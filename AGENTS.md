# Runway 90 — Agent Handoff

> Read this first. It tells you what exists, what's left, and the rules.
> The full product spec is in `docs/Runway90_Product_Spec_Packet.md` (copied from
> `~/Downloads/Runway90_Product_Spec_Packet.md`). The spec is the source of truth.
>
> **Deep technical reference: [`docs/TECH_STACK.md`](docs/TECH_STACK.md).**
> Read it before touching any adapter, integration, build config, or the theme.
> It has the exact toolchain versions, API endpoints/wire formats (all verified
> live), DB schema, secrets layout, design-system rules, and known gotchas.

## What this is

Hackathon vertical slice (HackHers @ GSU, FinanceHER track) of **Runway 90** —
a private financial-recovery companion for women rebuilding after economic abuse.
iPhone-only SwiftUI app. Synthetic data only. Sponsor targets: Gemini, Backboard,
Tiger Data, Auth0.

The demo loop it must prove:
**Synthetic document → Gemini extraction → survivor confirmation → Tiger Data
runway update → one next action → Auth0-scoped advocate handoff → Backboard
remembers the case.**

## Repo layout

```
project.yml                      # XcodeGen spec — regenerate project with `xcodegen generate`
Runway90.xcodeproj               # generated; commit it, but project.yml is authoritative
api/[...path].js                 # Vercel backend: Auth0 JWT + Tiger/Gemini/Backboard proxy
.env.example                     # backend variable names only; never add real values
Runway90/
  App/Runway90App.swift          # entry, root router, shake-to-quick-exit, QuickExitButton
  Theme/Theme.swift              # palette + liquid glass modifiers (see Design below)
  Models/Models.swift            # spec §5 data model + Maya fixture + Gemini JSON contract
  Store/AppStore.swift           # single @MainActor ObservableObject: all state + actions
  Adapters/
    BackendAPI.swift             # authenticated API client; no provider secrets in app
    Secrets.swift                # legacy local template reader, never bundled
    GeminiAdapter.swift          # backend vision extraction OR labelled "Demo extraction"
    BackboardAdapter.swift       # local cache + authenticated backend memory sync
    TigerDataAdapter.swift       # authenticated backend facade for Tiger Data
    AuthAdapter.swift            # live Auth0 login + API token, with demo fallback
  Views/
    DisclosureView.swift         # synthetic-data warning, first screen
    RoleEntryView.swift          # Maya (survivor) / Demo Advocate entry
    SurvivorHomeView.swift       # tabs: Home / Reclaim / Runway; Beat 1 memory message
    CaptureView.swift            # Beats 2–3: fixture/photos/camera → extraction → confirm cards
    SyntheticLetterView.swift    # in-app rendered fictional Northstar letter + ImageRenderer
    ReclaimView.swift            # confirmed / unrecognised / documents / timeline / delete case
    RunwayView.swift             # Beat 4: big number, Charts history, gaps, ONE next action
    AdvocateView.swift           # Beat 5: demo-MFA gate, scoped summary, Demo approval 18→31
    DecoyView.swift              # quick-exit decoy (weather-ish), PIN 0000 returns to role entry
  Resources/Secrets.example.plist  # copy to Secrets.plist and fill keys (all optional)
```

## Status — done

- [x] Project builds clean (`xcodebuild`, iOS Simulator destination, Xcode 27).
- [x] Liquid glass theme with palette (see Design). Real `.glassEffect()` on iOS 26+,
      `ultraThinMaterial` fallback below.
- [x] Full data model + Maya fixture (day 6, 18-day runway, 3 confirmed facts,
      pending TransUnion task, $250 transportation request).
- [x] All required screens from spec §4.
- [x] Beat 1: memory message assembled from persisted `MemoryEntry` rows, not hardcoded UI.
- [x] Beat 2: demo letter (always works) + photo picker + camera path; Gemini adapter
      with strict JSON contract and honest "Demo extraction" fallback.
- [x] Beat 3: Mine / Not mine / Not sure; not-mine flows into unrecognised accounts,
      timeline, and advocate summary.
- [x] Beat 4: runway view, Charts history, two gaps, exactly one next action with reason.
- [x] Beat 5: share summary → advocate role → demo-MFA gate → scoped summary only →
      Demo approval → runway animates 18 → 31 (numericText content transition).
- [x] Safety: shake + triple-tap quick exit, visible Exit shield button (simulator
      fallback), decoy screen with no case data, duress-PIN placeholder, delete demo
      case, synthetic-data banners, neutral "You have a reminder" label.
- [x] Live Auth0 access tokens now authenticate the hosted backend.
- [x] Tiger Data, Gemini, and Backboard credentials moved server-side behind
      `api/[...path].js`; Tiger snapshots are scoped by verified Auth0 `sub`.
- [x] Persistence survives restart via a local offline cache plus authenticated
      Tiger snapshot restore for live survivor sessions.
- [x] 5-page trauma-informed onboarding (welcome, safety ack, loop explainer,
      personalization with sample doc export, ready screen). Scoped per subject.
- [x] Quick exit opens the real Weather app (`weather://` URL scheme) on
      physical devices; decoy screen is the simulator fallback.
- [x] 3 synthetic documents (collection letter, bank statement, credit notice)
      generated as images and saveable to Photos during onboarding.
- [x] Isabel fixture: day 12, 28-day runway, 10 confirmed facts, 2 unrecognised
      accounts, 1 under review, 3 documents scanned, 7 runway snapshots, 13
      timeline events, 10 memory entries. Pre-populated in Tiger Data (27 events
      + 8.6KB case snapshot) and Backboard (cross-thread recall verified).

## Status — TODO (pick up here)

1. ~~Live Auth0~~ **DONE (2026-09-18)** — Auth0.swift SPM package wired.
   Tenant `skmpe.us.auth0.com`, client `U7jFSU34Rfu3DJOCIcUzWCWxG08PwgCL`,
   custom-scheme callback `com.hackhers.runway90://…` (allowlisted on tenant;
   CFBundleURLTypes set in project.yml). Config in `Resources/Auth0.plist`.
   `AuthAdapter.loginLive()` does Universal Login and maps the custom claim
   `https://runway90.app/roles` → Role (no claim = survivor). Live advocate
   sessions skip the demo-MFA sheet (tenant enforces MFA). Demo login fallback
   kept, per hard rules. **Tenant-side setup still needed by a human:**
   create roles `survivor`/`advocate`, assign to test users, and add a
   post-login Action:
   `api.idToken.setCustomClaim("https://runway90.app/roles", event.authorization?.roles || [])`
   plus (optional) an MFA challenge when roles include `advocate`.
   Needs one on-device end-to-end test (web auth can't run headless).
2. ~~Live Backboard~~ **DONE (2026-09-18)** — the backend owns the
   `BACKBOARD_API_KEY`, creates one assistant per Auth0 subject, and pushes
   memory snapshots through `/api/memory`.
3. ~~Live Tiger Data~~ **DONE (2026-09-18)** — the backend owns
   `TIGER_DATA_URL`, validates Auth0 access tokens, and upserts a full synthetic
   `CaseState` into `case_snapshots` keyed by the verified Auth0 `sub`. The iOS
   target no longer includes PostgresClientKit or a database password. The
   existing Tiger schema is:
   `events(id text, case_id text, type text, timestamp timestamptz, payload jsonb)`
   plus `case_snapshots(owner_id text primary key, case_id text, updated_at timestamptz, payload jsonb)`.
   Inspect with:
   `psql "$TIGER_DATA_URL" -c "SELECT type, timestamp FROM events ORDER BY timestamp DESC LIMIT 10;"`
   (psql lives at /opt/homebrew/opt/libpq/bin).
4. ~~Gemini live test~~ **DONE (2026-09-18)** — the backend owns the Gemini
   key and proxies `gemini-3.6-flash:generateContent` with
   `response_mime_type: application/json`; missing backend configuration keeps
   the honest `Demo extraction` fallback.
5. **App icon** — none yet. Palette below; keep it abstract (no shield/DV imagery).
6. **Optional PNG fixture** — spec names `maya_collection_letter.png`; we render the
   letter in-app via `SyntheticLetterView` + `ImageRenderer` instead, which satisfies
   "bundled fixture always works". If a judge insists on a literal PNG in the photo
   library, export `SyntheticLetterView.renderImage()` once and add to the simulator.
7. **Record backup demo video** (spec definition-of-done).
8. Run through spec §10 checklist on a physical iPhone.

## Design system — DO NOT DRIFT

Liquid glass aesthetic. Palette (Coolors `b60e41-e03068-c4dee5-292227-f5f5f5`):

| Token | Hex | Use |
|---|---|---|
| `RW.raspberry` | `#B60E41` | primary buttons, destructive-ish emphasis |
| `RW.pink` | `#E03068` | accent, highlights, approved states |
| `RW.mist` | `#C4DEE5` | glass tint, secondary text, info |
| `RW.plum` | `#292227` | background gradient base |
| `RW.cloud` | `#F5F5F5` | primary text on dark, surfaces |

Rules:
- Screens use `.rwScreen()` (raspberry→plum gradient, dark scheme).
- Cards use `.glassCard(tint:)` — real `glassEffect` on iOS 26+, material fallback below.
- Buttons use `.rwPrimaryButton(tint)` / `.rwGlassButton()` (`.glassProminent` / `.glass`
  on iOS 26+). Never use raw `.buttonStyle` directly in views.
- Deployment target is iOS 18.0 with `#available(iOS 26, *)` gates — keep it that way.

## Hard product rules (from spec — violating these fails the demo)

- NEVER label an account "fraud". Only: unrecognised / inconsistent / requires review.
- Nothing enters the confirmed record before the user picks Mine / Not mine / Not sure.
- Exactly ONE next action on the runway screen. Not a list.
- Advocate sees ONLY the explicitly shared neutral summary — no documents, no
  unconfirmed facts, no private notes, no full timeline.
- Every integration must have a *labelled* fallback (Demo extraction, Demo memory
  fallback, Demo data source, Demo login, Demo approval). Never fake a live call.
- Synthetic-data warning stays visible on disclosure + close.
- No real names/accounts/documents anywhere, including test data.
- Out of scope (do not build): real bureau/bank APIs, money movement, legal docs,
  notifications, voice, emotion detection, multi-user messaging (spec §8).

## Build / run

```sh
brew install xcodegen          # already installed on this machine
xcodegen generate              # regenerate Runway90.xcodeproj after editing project.yml
open Runway90.xcodeproj        # set your team under Signing & Capabilities
# CLI simulator build:
xcodebuild -project Runway90.xcodeproj -scheme Runway90 \
  -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

Backend secrets belong in Vercel environment variables named in `.env.example`.
Do not put them in `Secrets.plist`, the iOS target, an IPA, or GitHub. Missing
backend configuration = labelled demo fallbacks.

Demo PIN to leave the decoy screen: `0000`. Quick exit: shake, triple-tap, or the
shield button in every toolbar.

## Demo script

Follow spec §3 beats exactly. Presenter script is spec §11. Close line:
"Everything you saw was synthetic. She never had to tell her story twice."
