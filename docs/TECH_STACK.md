# Runway 90 — Technical Stack & Architecture Reference

> Companion to [`../AGENTS.md`](../AGENTS.md) (handoff/status) and
> [`Runway90_Product_Spec_Packet.md`](Runway90_Product_Spec_Packet.md) (product spec).
> This file is the deep technical reference: exact versions, endpoints, schemas,
> wire formats, and the reasoning behind each architectural decision.
> Last verified: 2026-09-18 on the machine described below.

---

## 1. Toolchain & build system

| Component | Version / value | Notes |
|---|---|---|
| Xcode | 27.0 (27A266a) | Ships the iOS 26+ SDK → native Liquid Glass APIs |
| Swift | 5.10 (`SWIFT_VERSION` in project.yml) | Swift 6 concurrency NOT enabled; `AppStore` is `@MainActor` |
| Deployment target | **iOS 18.0** | All iOS 26 APIs gated behind `#available(iOS 26.0, *)` — do not raise the target |
| Project generator | **XcodeGen 2.46.0** (`/opt/homebrew/bin/xcodegen`) | `project.yml` is authoritative; `Runway90.xcodeproj` is generated output (committed for convenience) |
| Bundle ID | `com.hackhers.runway90` | Must match Auth0 native app config exactly |
| Apple Team ID | `L22992699P` | Set in `project.yml` → `DEVELOPMENT_TEAM`, automatic signing |
| Device family | iPhone only (`TARGETED_DEVICE_FAMILY: "1"`), portrait only | |
| psql | `/opt/homebrew/opt/libpq/bin/psql` (keg-only libpq) | Used for Tiger Cloud inspection; not on PATH by default |

### Build commands

```sh
xcodegen generate     # ALWAYS run after editing project.yml (regenerates .xcodeproj)
xcodebuild -project Runway90.xcodeproj -scheme Runway90 \
  -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

Note: **no simulator runtimes are downloaded** on this machine (`xcrun simctl list
runtimes` is empty). CLI builds use `generic/platform=iOS Simulator`, which
compiles/links but cannot boot an app. On-device runs happen through Xcode GUI.

### Swift Package dependencies (declared in `project.yml → packages`)

| Package | Version | Purpose |
|---|---|---|
| [Auth0.swift](https://github.com/auth0/Auth0.swift) | `from: 2.22.0` | Universal Login (ASWebAuthenticationSession under the hood), token exchange, session clearing |

No other third-party code. Charts is Apple's `Charts` framework (SwiftUI, iOS 16+).

---

## 2. App architecture

**Pattern:** single-store MVVM-ish. One `@MainActor ObservableObject`
(`Store/AppStore.swift`) owns ALL mutable state and all actions. Views are dumb;
adapters are stateless `struct`s with `static` funcs. No DI framework, no
Combine beyond `@Published`, no Coordinator layer — routing is a 5-case enum.

```
┌─────────────────────────────────────────────────────────────┐
│ Runway90App (@main)                                         │
│   └─ RootView — switch store.route                          │
│        disclosure → DisclosureView                          │
│        roleEntry  → RoleEntryView (Auth0 live + demo login) │
│        survivor   → SurvivorRootView (TabView: Home/        │
│                     Reclaim/Runway)                         │
│        advocate   → AdvocateView (demo-MFA gate → scoped    │
│                     summary → Demo approval)                │
│        decoy      → DecoyView (quick-exit target)           │
└──────────────┬──────────────────────────────────────────────┘
               │ @EnvironmentObject
┌──────────────▼──────────────────────────────────────────────┐
│ AppStore (@MainActor ObservableObject)                      │
│   @Published route / state: CaseState / session /           │
│   extracting / pendingFacts / restoredFromMemory            │
│   Actions: runExtraction, confirm(fact:as:), shareSummary,  │
│   approveRequest, recalculateRunway, quickExit,             │
│   deleteDemoCase, setMemory, appendEvent, persist           │
└───┬──────────────┬───────────────┬──────────────┬───────────┘
    │              │               │              │
┌───▼────┐  ┌──────▼─────┐  ┌──────▼─────┐  ┌────▼─────┐
│ Gemini │  │ Backboard  │  │ TigerData  │  │  Auth    │
│Adapter │  │  Adapter   │  │  Adapter   │  │ Adapter  │
└────────┘  └────────────┘  └────────────┘  └──────────┘
 backend     backend       BackendAPI       Auth0.swift
 proxy       proxy         → Tiger Cloud    Universal Login
              + local      owner-scoped     + API token
              fallback     snapshots        + demo fallback
```

**Adapter contract (hard rule):** every adapter exposes `isLive: Bool` derived
from config presence, and the UI labels the fallback honestly ("Demo extraction",
"Demo memory fallback", "Demo data source", "Demo login", "Demo approval").
A live call is never faked; a failed live call falls back silently to local
state but never reports itself as live.

### Event flow (the demo loop, end to end)

1. `CaptureView` → `store.runExtraction(image:)` → `GeminiAdapter.extract` →
   `pendingFacts` (all `reviewStatus == .unconfirmed`).
2. `FactConfirmCard` → `store.confirm(fact:as:)` — the ONLY path into
   `state.facts`. Emits `fact_confirmed` / `account_marked_not_mine` /
   `fact_needs_review` events.
3. Every `appendEvent` writes to `state.timeline` (offline UI cache), fires
   `TigerDataAdapter.record` (authenticated backend INSERT into Tiger Data),
   and persists.
4. `RunwayView` → `shareSummary()` sets `summaryShared`, emits
   `summary_shared`, records sharing preference in memory.
5. `AdvocateView` → `approveRequest()` → `recalculateRunway(to: 31, …)` →
   `runway_recalculated` event + `RunwaySnapshot` appended (Charts line chart
   re-renders; big number animates via `.contentTransition(.numericText())`).
6. Every `persist()` → local JSON cache + authenticated backend snapshot upsert
   into Tiger Data and Backboard memory push when a live Auth0 token exists.

---

## 3. Data model & persistence

Types in `Models/Models.swift`, mirroring spec §5 exactly: `User`, `CaseRecord`,
`DocumentRecord`, `FinancialFact`, `TimelineEvent`, `AssistanceRequest`,
`MemoryEntry`, `RunwaySnapshot`, all `Codable`, all string IDs.

`ReviewStatus` raw values are wire-stable: `mine | not_mine | not_sure | unconfirmed`.
**Never introduce a "fraud" status** (spec hard rule).

### Persistence

- Single blob: `CaseState` (everything above) →
  `Documents/runway90_case_state.json`, ISO-8601 dates, atomic writes.
- Written on every mutation via `AppStore.persist()`.
- On launch: `BackboardAdapter.load()`; success sets
  `restoredFromMemory = true`, which drives the "Backboard memory /
  Demo memory fallback" chip on the home screen (this is the judge-visible
  proof of Beat 1). After a survivor session starts, Tiger Data can restore a
  full `CaseState` snapshot scoped to the session owner.
- `deleteDemoCase()` removes the file, resets to `Fixture.fresh()`, routes to
  disclosure.
- Fixture seed: Maya, day 6, runway 18, facts `fact-rent` ($1,150),
  `fact-paycheck` ($1,480), `fact-experian-freeze`; pending `task-transunion`;
  request `request-transport-001` ($250, pending); 5 memory rows; 2 runway
  snapshots (14 → 18).

The Beat-1 memory message is **assembled at render time** from `MemoryEntry`
rows in `AppStore.memoryMessage` — deliberately not a stored string, so judges
can be shown the memory table driving the copy.

---

## 4. Sponsor integrations — exact wire formats (all verified live 2026-09-18)

### 4.1 Gemini (`Adapters/GeminiAdapter.swift` + `api/[...path].js`) — ✅ backend-proxied

- iOS endpoint: authenticated `POST /api/extract`.
- Backend endpoint: `POST https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key={GEMINI_API_KEY}`.
- `GEMINI_API_KEY` exists only in Vercel environment variables; it is never bundled into the iPhone app.
- ⚠️ `gemini-2.0-flash` is **retired** (404 with a migration message). Current model: `gemini-3.6-flash`.
- Request: `contents[0].parts = [ {text: prompt}, {inline_data: {mime_type: "image/jpeg", data: base64}} ]`,
  `generationConfig.response_mime_type: "application/json"` (forces raw JSON, no markdown fences).
- The prompt pins the exact output schema and forbids the word "fraud";
  `reviewStatus` is always `"unconfirmed"` (user is the source of truth).
- Response envelope: `candidates[0].content.parts[].text` → decode as `ExtractionResult`.
- Verified end-to-end with the rendered letter PNG; returns
  `{"documentType":"collection_letter","facts":[{"counterparty":"NORTHSTAR COLLECTIONS","accountLast4":"4471","amount":2310,"openedDate":"2024-03","reviewStatus":"unconfirmed"}]}`.
- Fallback: `Fixture.extractionFixture` (same shape) + `isLive=false` →
  "Demo extraction" badge. A ~1.2 s artificial delay preserves the
  "extracting…" demo beat.
- Image source: `SyntheticLetterView.renderImage()` (SwiftUI `ImageRenderer`,
  scale 3, width 360) — the fixture letter is rendered in-app, so it can never
  be missing from a bundle.

### 4.2 Backboard (`Adapters/BackboardAdapter.swift` + `api/[...path].js`) — ✅ backend-proxied

- iOS endpoint: authenticated `POST /api/memory`.
- Backend base URL: `https://app.backboard.io/api` · Auth header: **`X-API-Key`** (NOT Bearer).
- `BACKBOARD_API_KEY` exists only in Vercel environment variables; it is never bundled into the iPhone app.
- Docs: <https://docs.backboard.io> (index at `https://backboard-docs.docsalot.dev/llms.txt`).
- Model: one **assistant per case**; memory is shared across all threads of an assistant.
  - `POST /assistants` `{name, instructions}` → response field `assistant_id`
    (UUID). Cached in `UserDefaults` key `backboard_assistant_id`.
  - `POST /threads/messages` `{assistant_id, content, memory: "auto"}` —
    thread auto-created; Backboard's memory layer extracts facts from content.
- Verified: memory snapshot pushed, then a **new thread** recalled the case
  facts with `retrieved_memories: true` in the response.
- Existing live assistant on the tenant key: `3a48867e-4f5b-4dc4-9974-8efebc4c6d94`
  (name `runway90-case-maya-001`) — the app will reuse its own cached ID, so
  this one is just historical.
- Local persistence (the JSON blob above) remains an offline cache. Live sessions
  push memory through the authenticated backend; the full recoverable case
  snapshot is restored from Tiger Data after Auth0 login.

### 4.3 Tiger Data (`Adapters/TigerDataAdapter.swift` + `api/[...path].js`) — ✅ backend-proxied

- The iPhone never opens Postgres and never receives `TIGER_DATA_URL`.
- Auth0 access token → backend JWT verification → Tiger query scoped by the
  token's `sub` claim. A client-supplied owner ID is intentionally ignored.
- Backend environment variable: `TIGER_DATA_URL` = full connection string
  `postgres://user:pass@host:port/db?sslmode=require`.
- API routes: `GET/PUT/DELETE /api/case` for the per-user snapshot and
  `POST /api/events` for the event stream.
- Service: name `db-90`, host `jtf4omyes3.ehv2z06xub.tsdb.cloud.timescale.com`,
  port `39663`, db `tsdb`, user `tsdbadmin`.
- Schema (already created on the service):
  ```sql
  CREATE TABLE events (
    id text NOT NULL, case_id text NOT NULL, type text NOT NULL,
    timestamp timestamptz NOT NULL, payload jsonb
  );
  SELECT create_hypertable('events', 'timestamp', if_not_exists => TRUE);

  CREATE TABLE IF NOT EXISTS case_snapshots (
    owner_id text PRIMARY KEY,
    case_id text NOT NULL,
    updated_at timestamptz NOT NULL,
    payload jsonb NOT NULL
  );
  ```
- Insert path: parameterized `pg` queries in the Vercel Node function, with a
  small pooled connection count suitable for the hackathon demo.
- Event types written: `fact_confirmed`, `account_marked_not_mine`,
  `fact_needs_review`, `assistance_request_created`,
  `assistance_request_approved`, `runway_recalculated`, `summary_shared`.
- Snapshot path: every live survivor `persist()` upserts the complete synthetic
  `CaseState` into `case_snapshots`; the backend uses the Auth0 access-token
  `sub` as `owner_id`. A new install loads that snapshot after survivor login
  and shows a `Tiger Data restore` chip. Demo roles stay local and labeled.
- Judge-facing inspection query:
  ```sh
  /opt/homebrew/opt/libpq/bin/psql "$TIGER_DATA_URL" \
    -c "SELECT type, timestamp FROM events ORDER BY timestamp DESC LIMIT 10;"
  ```
- ⚠️ Rotate the `tsdbadmin` password after the event (string was shared in chat
  and sits in `~/Downloads/tiger-cloud-db-90-credentials.txt`).

### 4.4 Auth0 (`Adapters/AuthAdapter.swift`) — ✅ wired, needs one on-device test

- Tenant `skmpe.us.auth0.com`, native app client `U7jFSU34Rfu3DJOCIcUzWCWxG08PwgCL`,
  token endpoint auth method `none` (public client + PKCE).
- SDK config: `Resources/Auth0.plist` (`ClientId`, `Domain`, public API
  `Audience`, and public `BackendURL`) — read
  automatically by Auth0.swift. **Committed on purpose** (client ID + domain are
  not secrets for a public client).
- Callback mode: **custom URL scheme** (`CFBundleURLTypes` →
  `com.hackhers.runway90`), NOT Universal Links → no Associated Domains
  entitlement needed. Allowlisted callback/logout URLs on the tenant:
  `com.hackhers.runway90://skmpe.us.auth0.com/ios/com.hackhers.runway90/callback`
  (plus the https twins).
- Login: `Auth0.webAuth().audience(Audience).scope("openid profile email").start()`
  (async/await). The resulting access token is sent as `Authorization: Bearer`
  to the backend.
- Role mapping: custom ID-token claim **`https://runway90.app/roles`**
  (string array). `advocate` in array → `.advocate`; otherwise `.survivor`.
  Claim decoded by a minimal base64url JWT payload split (signature trust comes
  from the SDK's code-exchange over TLS; do not re-verify locally).
- Live advocate sessions have `mfaVerified = true` and **skip the in-app
  demo-MFA sheet** — MFA is a tenant responsibility.
- The backend validates the same audience and issuer with Auth0 JWKS, then uses
  the verified token `sub` as the only Tiger `owner_id`. Auth0 therefore links
  a person to their own stored case; the iPhone never chooses the database owner.
- Tenant-side setup still required (human, dashboard):
  1. Roles `survivor` + `advocate`; assign to test users.
  2. Post-login Action:
     `api.idToken.setCustomClaim("https://runway90.app/roles", event.authorization?.roles || []);`
  3. Optional: MFA policy / Action challenge when roles include `advocate`.
- `AuthAdapter.isLive` = Auth0.plist present with non-empty values.
  Demo fallback (`demoLogin(role:)`) is a spec hard requirement — never remove.

---

## 5. Secrets & configuration

| File | Committed? | Contents |
|---|---|---|
| `Runway90/Resources/Secrets.plist` | **NO** and explicitly excluded from the Xcode target | Legacy local template only; it is never bundled or used for live cloud access |
| `.env.example` | yes | Names of backend environment variables; contains no values |
| Vercel environment variables | **NO** | `GEMINI_API_KEY`, `BACKBOARD_API_KEY`, `TIGER_DATA_URL`, `AUTH0_AUDIENCE` |
| `Runway90/Resources/Auth0.plist` | yes | Auth0 ClientId, Domain, API Audience, and backend URL; public configuration |

The iOS app uses `BackendAPI` for live integrations. Missing backend URL,
missing Auth0 API audience, or an absent access token flips the app to its
labelled demo fallback. **A missing key must never crash or block anything.**

The backend is deployed from the repository root with Vercel. Set the values in
`.env.example` as Vercel project environment variables; never put those values
in `Auth0.plist`, an IPA, or GitHub.

---

## 6. Design system (Theme/Theme.swift)

Palette — Coolors `b60e41-e03068-c4dee5-292227-f5f5f5`:

| Token | Hex | Role |
|---|---|---|
| `RW.raspberry` | `#B60E41` | primary actions, gradient top |
| `RW.pink` | `#E03068` | accent, approved/success states, chart line |
| `RW.mist` | `#C4DEE5` | glass tint, secondary text, section headers |
| `RW.plum` | `#292227` | background gradient base |
| `RW.cloud` | `#F5F5F5` | primary text on dark |

Liquid Glass implementation:

- `.rwScreen()` → raspberry→plum `LinearGradient` + `.preferredColorScheme(.dark)`.
- `.glassCard(tint:corner:)` → iOS 26+: `.glassEffect(.regular.tint(tint.opacity(0.12)).interactive(), in: .rect(cornerRadius:))`;
  <26: `.ultraThinMaterial` + 1 pt tinted stroke.
- `.rwPrimaryButton(tint)` → `.buttonStyle(.glassProminent)` / fallback `.borderedProminent`.
- `.rwGlassButton()` → `.buttonStyle(.glass)` / fallback `.bordered`.
- Views must never call raw `buttonStyle`/materials directly — always these
  modifiers, so the fallback stays consistent.
- Runway number animates with `.contentTransition(.numericText())` +
  `.animation(.smooth(duration: 0.8))` — this is the 18→31 beat.
- Decoy screen intentionally breaks the design system (light scheme, system
  background, no brand color) so it reads as "not this app".

---

## 7. Safety mechanics (implementation detail)

- **Shake** → `UIWindow.motionEnded` override posts `.deviceDidShake` →
  `store.quickExit()` (works anywhere in the app; simulator: Device ▸ Shake).
- **Triple-tap** → `.onTapGesture(count: 3)` on `SurvivorRootView` and `AdvocateView`.
- **Shield button** (`QuickExitButton`) in every toolbar — simulator-friendly fallback.
- **Decoy** (`DecoyView`): fake weather + "You have a reminder"; hidden
  "Settings" reveals a PIN field. PIN `0000` → role entry. Any other 4+ digit
  PIN = duress placeholder → stays on an empty decoy (no error shown).
- **Delete demo case** in ReclaimView → confirmation dialog →
  `store.deleteDemoCase()` (wipes JSON, reseeds, back to disclosure).
- Neutral notification copy only ("You have a reminder"); no real notifications.

---

## 8. Known limitations / gotchas for the next agent

1. **Simulator runtimes not installed** on this machine — CLI can only compile.
   Install an iOS runtime via Xcode ▸ Settings ▸ Components to boot the app locally.
2. **Auth0 login untested end-to-end** (needs a screen). Everything up to
   `webAuth().start()` is compile-verified only.
3. **Backboard restore** is represented by the Tiger snapshot; Backboard memory
   is currently write-path only.
4. **The backend opens a small pooled connection set to Tiger Data** —
   acceptable at demo scale; move to a managed pool or connection proxy if
   volume grows.
5. **Vercel environment variables are required for live integrations** — the
   iOS target intentionally falls back to labeled demo behavior when the
   backend URL or Auth0 API audience is still a placeholder.
6. `AppStore` mixes state + actions + derived views in one class deliberately
   (hackathon speed). Do not refactor into layers mid-event.
7. Free-vs-paid signing: Team `L22992699P` is set; if signing fails on device,
   check Xcode ▸ Signing & Capabilities and re-select the team.
8. No app icon yet; no tests (vertical slice, all verification is manual +
   live curl/psql checks documented above).
