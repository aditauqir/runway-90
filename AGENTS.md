# Runway 90 — Agent Handoff

> Read this first. It tells you what exists, what's left, and the rules.
> The full product spec is in `docs/Runway90_Product_Spec_Packet.md` (copied from
> `~/Downloads/Runway90_Product_Spec_Packet.md`). The spec is the source of truth.

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
Runway90/
  App/Runway90App.swift          # entry, root router, shake-to-quick-exit, QuickExitButton
  Theme/Theme.swift              # palette + liquid glass modifiers (see Design below)
  Models/Models.swift            # spec §5 data model + Maya fixture + Gemini JSON contract
  Store/AppStore.swift           # single @MainActor ObservableObject: all state + actions
  Adapters/
    Secrets.swift                # reads Resources/Secrets.plist (git-ignored)
    GeminiAdapter.swift          # live vision extraction OR labelled "Demo extraction"
    BackboardAdapter.swift       # local JSON persistence + best-effort Backboard sync
    TigerDataAdapter.swift       # event POST to Tiger endpoint OR "Demo data source"
    AuthAdapter.swift            # demo role login; TODO live Auth0.swift wiring
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
- [x] Persistence survives restart via local JSON (Backboard fallback) —
      `restoredFromMemory` drives the "Demo memory fallback / Backboard memory" chip.

## Status — TODO (pick up here)

1. **Live Auth0** — add SPM package `https://github.com/auth0/Auth0.swift`, wire
   `AuthAdapter.loginLive` (web auth, roles claim → `Role`, MFA action for advocate).
   Keep the demo login fallback; never remove it.
2. **Live Backboard** — confirm the real endpoint/shape from the sponsor booth/docs
   and fix `BackboardAdapter.syncToBackboard` (currently best-effort POST to
   `app.backboard.io/api/memories`, guessed path). Also implement remote `load()` merge.
3. **Live Tiger Data** — stand up a tiny HTTP proxy (or use Tiger Cloud REST/SQL-over-HTTP)
   that inserts into a hypertable `events(id, case_id, type, timestamp, payload jsonb)`.
   `TigerDataAdapter` already POSTs `{base}/events` with a bearer token.
4. **Gemini live test** — adapter is written against
   `gemini-2.0-flash:generateContent` with `response_mime_type: application/json`.
   Needs a real key in Secrets.plist and one end-to-end test with the rendered letter.
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

Secrets: `cp Runway90/Resources/Secrets.example.plist Runway90/Resources/Secrets.plist`
and fill keys. All keys optional; missing keys = labelled demo fallbacks.

Demo PIN to leave the decoy screen: `0000`. Quick exit: shake, triple-tap, or the
shield button in every toolbar.

## Demo script

Follow spec §3 beats exactly. Presenter script is spec §11. Close line:
"Everything you saw was synthetic. She never had to tell her story twice."
