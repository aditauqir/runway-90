# Runway 90

<div align="center">

```
  ____                                    ___    ___  
 |  _ \ _   _ _ ____      ____ _ _   _   / _ \  / _ \ 
 | |_) | | | | '_ \ \ /\ / / _` | | | | | (_) || | | |
 |  _ <| |_| | | | \ V  V / (_| | |_| |  \__, || |_| |
 |_| \_\\__,_|_| |_|\_/\_/ \__,_|\__, |    /_/  \___/ 
                                 |___/                
```

**A private, persistent financial-recovery companion for women rebuilding after economic abuse.**

*Target: iOS 18.0+ (SwiftUI · Liquid Glass Design)*  
*Platform: iPhone (Physical & Virtual iOS Simulator)*

[![iOS 18.0+](https://img.shields.io/badge/iOS-18.0%2B-blue.svg?logo=apple&style=flat-square)](https://developer.apple.com/ios/)
[![Swift 5.10](https://img.shields.io/badge/Swift-5.10-orange.svg?logo=swift&style=flat-square)](https://swift.org)
[![XcodeGen](https://img.shields.io/badge/Project-XcodeGen-blueviolet.svg?style=flat-square)](https://github.com/yonaskolb/XcodeGen)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

> *"Leaving is an event. Financial independence is the next 90 days."*

</div>

---

> ℹ️ **Team & Collaborator Note:** Detailed hackathon track targets, sponsor prize rubrics, presentation scripts, and backend wire contracts are documented separately in [**`README_TEAM.md`**](README_TEAM.md).

> 🧭 **Onboarding handoff:** The detailed implementation brief for the next
> agent is [**`docs/ONBOARDING_AGENT_PROMPT.md`**](docs/ONBOARDING_AGENT_PROMPT.md).

---

## Table of Contents

- [The Problem](#the-problem)
- [What Runway 90 Does](#what-runway-90-does)
- [The 5-Beat Recovery Loop](#the-5-beat-recovery-loop)
- [Safety & Trauma-Informed Principles](#safety--trauma-informed-principles)
- [Design System — Liquid Glass](#design-system--liquid-glass)
- [Virtual Demo: Testing on Mac via Xcode Simulator](#virtual-demo-testing-on-mac-via-xcode-simulator)
  - [Prerequisites](#prerequisites)
  - [Step 1: Download iOS Simulator Runtime](#step-1-download-ios-simulator-runtime)
  - [Step 2: Generate Project & Open in Xcode](#step-2-generate-project--open-in-xcode)
  - [Step 3: Select Virtual Simulator & Run](#step-3-select-virtual-simulator--run)
  - [Step 4: Step-by-Step Virtual Walkthrough](#step-4-step-by-step-virtual-walkthrough)
  - [Simulator Shortcuts & Safety Testing](#simulator-shortcuts--safety-testing)
- [Technical Architecture](#technical-architecture)
  - [Application Architecture](#application-architecture)
  - [Data Flow & Persistence](#data-flow--persistence)
- [Repository Structure](#repository-structure)
- [Sources & References](#sources--references)

---

## The Problem

Financial abuse is present in **~99% of domestic violence cases** ([NNEDV](https://nnedv.org/content/about-financial-abuse/)). It is the single most cited reason survivors stay in or return to unsafe environments. An abuser frequently controls bank access, forces debt into the partner's name, ruins credit, conceals obligations, and confiscates income.

When a woman finally leaves, she faces severe systemic barriers:
- **Zero accessible liquidity:** Accounts are drained, monitored, or locked.
- **Coerced, invisible debt:** Collections letters arrive for credit lines, loans, and bills she never opened or knew existed.
- **Wrecked credit:** Damaged credit history blocks apartment leases, phone plans, reliable transportation, and employment background checks.
- **A mountain of bewildering paperwork:** Creditor notices, bureau reports, and legal notices that must be untangled under extreme emotional and cognitive strain.
- **Trauma-compounding story repetition:** Having to retell her personal and financial trauma from scratch to every single shelter, intake worker, caseworker, and credit bureau.

### Why Existing Fintech Fails Survivors
- **Budgeting apps (Mint, Copilot, YNAB):** Assume stable income, transparent accounts, and that all transactions are recognized.
- **Credit monitoring apps (Credit Karma, Experian):** Treat all recorded debt as legitimate and belonging to the user.
- **Shelters and hotlines:** Provide crucial physical safety and emergency shelter, but lack tools to untangle complex consumer debt and rebuild financial standing.

**Runway 90 is not a budgeting app.** It is a dedicated companion for **rebuilding financial access from nothing while someone else has been controlling the record.**

---

## What Runway 90 Does

Runway 90 guides a survivor across her first 90 days of recovery with a trauma-informed, privacy-first loop:

```
  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
  │   Capture    │ ──> │   Confirm    │ ──> │    Runway    │ ──> │  Next Step   │ ──> │  Remembered  │
  └──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
   Photographs a        Marks facts:         Calculates days      Proposes ONE         Picks up where
   letter, bill,        Mine, Not mine,      of essential         action with a        she left off.
   or statement         or Not sure.         costs covered        clear reason         Zero retelling
```

1. **Multimodal Document Ingestion:** Analyzes collection letters and statements to extract counterparties, account numbers, balances, and opening dates into structured cards.
2. **Survivor-Controlled Truth:** Nothing enters the confirmed case record without survivor verification. The app **never** labels an account as "fraud" — only *unrecognised*, *inconsistent*, or *requires review*.
3. **Continuous Runway Metric:** Displays financial runway in days (e.g., *"18 days of essential expenses covered"*), powered by an event-backed time-series model.
4. **Single Next Action:** Eliminates decision fatigue by suggesting exactly **one** actionable next step with clear rationale, avoiding competing priorities.
5. **Persistent Cross-Session Memory:** Remembers confirmed facts, bureaus frozen, active deadlines, and preferences. Survivors never have to re-explain their situation.
6. **Scoped Advocate Handoff:** Generates a neutral, aggregate summary that can be shared with an advocate. Private notes, unconfirmed facts, and original documents remain completely private.

---

## The 5-Beat Recovery Loop

Runway 90 proves its core loop through a pre-seeded synthetic recovery profile for **Maya** (Day 6 of recovery, 18-day runway, Experian frozen, TransUnion pending):

```
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                         THE 5-BEAT DEMO WORKFLOW                            │
 └─────────────────────────────────────────────────────────────────────────────┘

 Beat 1: Reopen Maya's Case (Persistent Case Memory)
 ───────────────────────────────────────────────────
 • Opens directly into Maya's active recovery session.
 • Home card displays a personalized memory greeting synthesized from stored
   memory entries:
   "Welcome back, Maya. You froze Experian and confirmed two accounts.
    TransUnion is still open. Want to review the letter you mentioned?"

 Beat 2: Ingest Document via Vision Analysis
 ───────────────────────────────────────────
 • Tap "Review letter" -> Select the bundled synthetic collection letter.
 • Vision engine extracts structured metadata:
   - Counterparty: Northstar Collections
   - Account Last 4: 4471
   - Amount: $2,310
   - Opened Date: 03/2024
   - Status: requires review

 Beat 3: Survivor Confirms the Truth
 ──────────────────────────────────
 • Fact card presents three explicit choices: [Mine] [Not mine] [Not sure].
 • Survivor taps "Not mine".
 • Fact immediately routes to Unrecognised Accounts, appends to the Case Timeline,
   and queues for the neutral advocate summary.
 • Hard Rule: Zero data enters confirmed records without survivor verification.

 Beat 4: Dynamic Runway & Single Next Action
 ───────────────────────────────────────────
 • Runway screen displays 18 days of essential expenses covered.
 • Apple Charts visualizes the historical runway time-series.
 • Highlights largest remaining gaps: Transportation & Housing deposit.
 • Proposes exactly ONE next action: "Request transportation support ($250)".
 • Survivor submits the request and taps "Share neutral summary".

 Beat 5: Scoped Advocate Handoff & Quick Exit Close
 ──────────────────────────────────────────────────
 • Switch to Advocate Role (authenticated or demo advocate access).
 • Advocate dashboard displays strictly scoped summary:
   - Case Day: 6
   - Confirmed Facts: 3
   - Credit Freeze: Experian frozen
   - Unrecognised Accounts: 1 requires review
   - Assistance Request: Transportation Support ($250) [Pending]
 • Advocate clicks "Approve (Demo approval)".
 • Returning to Maya: Runway updates dynamically from 18 days -> 31 days with
   smooth numeric text animation.
 • Presenter performs Quick Exit (shake device or tap shield) -> Decoy screen appears.
 • Closing line: "Everything you saw was synthetic. She never had to tell her story twice."
```

---

## Safety & Trauma-Informed Principles

Runway 90 is designed for a phone that may be monitored by an abuser:

| Safety Feature | Implementation | Behavior |
|---|---|---|
| **Shake to Exit** | `UIWindow.motionEnded` override | Shaking the iPhone immediately replaces all content with the Decoy screen. |
| **Triple-Tap Exit** | `.onTapGesture(count: 3)` on root screens | Discreet alternative to shaking when physical movement must be minimized. |
| **Quick Exit Button** | Toolbar `xmark.shield.fill` button | Guaranteed exit mechanism on all screens (especially in Simulator). |
| **Decoy Screen** | `DecoyView` (system light theme) | Displays innocuous weather widget (`68° Partly Cloudy`) and neutral notes. |
| **Decoy Return PIN** | Secure PIN entry | Enter `0000` to return to Runway 90. |
| **Duress PIN Placeholder**| Any other 4-digit code | Empties the decoy state without displaying error messages. |
| **Neutral Notifications**| System copy | Alerts read: *"You have a reminder"* — never exposing financial or domestic terms. |
| **Complete Data Erasure**| "Delete demo case" action | Atomically removes local state, clears session, and reseeds clean baseline. |
| **Zero Real Data** | Synthetic-only policy | All names, balances, and accounts are fictional. Disclaimer banner on all screens. |

---

## Design System — Liquid Glass

Built with Apple's **Liquid Glass** aesthetic, combining blurred depth materials with a high-contrast recovery palette:

<div align="center">

| Token | Hex | Role in UI |
|---|---|---|
| `RW.raspberry` | `#B60E41` | Primary CTA buttons, gradient top, destructive indicators |
| `RW.pink` | `#E03068` | Accent highlights, approved states, runway chart stroke |
| `RW.mist` | `#C4DEE5` | Glass card stroke, secondary text, metadata labels |
| `RW.plum` | `#292227` | Deep background gradient base |
| `RW.cloud` | `#F5F5F5` | Primary text and crisp contrast elements |

</div>

- **Custom Iridescent Art Background:** The login screen renders a full-bleed art background with a subtle ambient gradient scrim for high contrast.
- **Floating Apple Flight Icon:** Centered Liquid Glass badge featuring Apple's flight icon (`airplane.departure`) placed 30px above the screen midpoint.
- **Adaptive Glass Material:** Implements native iOS 26+ `.glassEffect()` modifiers with graceful fallback to multi-layered `.ultraThinMaterial` on iOS 18.0+.
- **Dynamic Numeric Transitions:** Runway numbers animate smoothly using `.contentTransition(.numericText())` when approval shifts runway from 18 to 31 days.
- **Decoy Contrast:** Decoy screen deliberately abandons dark glass styling in favor of stark system light backgrounds to look entirely unbranded.

---

## Virtual Demo: Testing on Mac via Xcode Simulator

You can test Runway 90 virtually on macOS using Apple's **iOS Simulator**. The app runs with zero external configuration using built-in synthetic demo fallbacks.

### Prerequisites
- **Mac:** macOS Sonoma (14.0+) or Sequoia (15.0+)
- **Xcode:** Xcode 16.0+ (Xcode 27 recommended, Swift 5.10)
- **XcodeGen:** Install via Homebrew:
  ```bash
  brew install xcodegen
  ```

---

### Step 1: Download iOS Simulator Runtime

If this is your first time developing on Xcode, ensure an iOS Simulator runtime is installed:
1. Open **Xcode**.
2. Go to **Xcode ▸ Settings…** (`⌘ ,`).
3. Select the **Platforms** (or **Components**) tab.
4. Under **iOS**, click **Get** or **Download** next to the latest iOS Runtime.

*Or run from Terminal:*
```bash
xcodebuild -downloadPlatform iOS
```

---

### Step 2: Generate Project & Open in Xcode

From the repository root:

```bash
# Generate the Xcode project from declarative spec
xcodegen generate

# Open the project in Xcode
open Runway90.xcodeproj
```

---

### Step 3: Select Virtual Simulator & Run

1. In Xcode's top toolbar, click the device destination dropdown next to **Runway90**.
2. Under **iOS Simulators**, choose any virtual device (e.g., **iPhone 16 Pro** or **iPhone 15**).
3. If signing is requested under **Signing & Capabilities**, select your personal Apple ID team (no paid developer membership required for simulator testing).
4. Press **`⌘ R`** (or click the ▶ **Play** button).

The iOS Simulator will boot and launch directly into the **Liquid Glass** login screen!

---

### Step 4: Step-by-Step Virtual Walkthrough

1. **Login Screen:**
   - Notice the iridescent background, the Apple flight icon centered above the mid-line, and the frosted glass buttons pinned to the bottom.
   - Tap **"Welcome back, Maya"** to enter the survivor's active recovery session.
2. **Survivor Home (Beat 1):**
   - See Maya's Day 6 dashboard with the personalized memory message dynamically generated from stored recovery history.
   - Tap **"Review letter"**.
3. **Document Ingestion (Beat 2):**
   - Tap **"Use the demo letter"** (this uses the built-in synthetic Northstar Collections fixture).
   - Watch the extraction state parse the document into structured fact cards.
4. **Survivor Confirmation (Beat 3):**
   - On the extracted account card, tap **"Not mine"**.
   - The unrecognised debt routes immediately to the **Reclaim** tab and case timeline.
5. **Runway & Next Action (Beat 4):**
   - Navigate to the **Runway** tab. Notice the **18 days** counter and the line chart.
   - View the single next action: *"Request transportation support ($250)"*.
   - Tap **"Share neutral summary"**.
6. **Advocate Approval & Recalculation (Beat 5):**
   - Tap **"Switch to advocate view"** (or return to login and tap *"I’m a demo advocate"*).
   - Enter any 6 digits for the demo MFA gate (`123456`).
   - Notice the advocate sees ONLY the shared neutral summary (no private notes or documents).
   - Tap **"Approve (Demo approval)"**.
   - Tap **"Back to Maya"** and return to the **Runway** tab: watch the runway number smoothly animate from **18 days → 31 days**!

---

### Simulator Shortcuts & Safety Testing

- **Trigger Quick Exit (Shake):**
  In the macOS Simulator menu, click **Device ▸ Shake** (or press **`⌃ ⌘ Z`**).
  *Result:* The entire interface instantly flips to the Weather Decoy Screen (`Partly cloudy · 68°`).
- **Toolbar Quick Exit:**
  Tap the **Shield icon** in the top-right corner of any screen.
- **Unlock Decoy Screen:**
  Tap **Settings** at the bottom of the decoy screen and enter PIN **`0000`** to return to the app.
- **Duress PIN Test:**
  Enter any other 4 digits (e.g., `1234`) on the decoy screen — the app safely resets to an empty state without revealing case data.
- **Wipe Demo Data:**
  Go to the **Reclaim** tab ▸ scroll down ▸ tap **"Delete demo case"** to erase all local data and reset to Day 6 baseline.

---

## Technical Architecture

### Application Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Runway90App (@main)                                         │
│   └─ RootView — switch store.route                          │
│        disclosure → DisclosureView (Safety warnings)        │
│        roleEntry  → RoleEntryView (Liquid Glass login)      │
│        survivor   → SurvivorRootView (Home/Reclaim/Runway)  │
│        advocate   → AdvocateView (Scoped summary & approval)│
│        decoy      → DecoyView (Quick-exit weather decoy)    │
└──────────────┬──────────────────────────────────────────────┘
               │ @EnvironmentObject
┌──────────────▼──────────────────────────────────────────────┐
│ AppStore (@MainActor ObservableObject)                      │
│   Manages case state, timeline events, runway calculation,  │
│   memory entries, and scoped sharing permissions            │
└───┬──────────────┬───────────────┬──────────────┬───────────┘
    │              │               │              │
┌───▼────┐  ┌──────▼─────┐  ┌──────▼─────┐  ┌────▼─────┐
│ Gemini │  │ Backboard  │  │ TigerData  │  │  Auth    │
│Adapter │  │  Adapter   │  │  Adapter   │  │ Adapter  │
└────────┘  └────────────┘  └────────────┘  └──────────┘
```

### Data Flow & Persistence
- **Local Source of Truth:** `CaseState` persists locally in `Documents/runway90_case_state.json` via atomic file operations.
- **Live Cloud Backend:** Optional authenticated backend proxy (`api/[...path].js`) handles remote memory sync, event logging, and vision extraction when configured.
- **Graceful Fallbacks:** Every adapter includes a transparent demo fallback (`Demo extraction`, `Demo memory fallback`, `Demo data source`, `Demo login`, `Demo approval`). Missing credentials never block the app.

---

## Repository Structure

```
runway90/
├── project.yml                       # XcodeGen project specification
├── Runway90.xcodeproj                # Generated Xcode project
├── README.md                         # Public product & virtual demo testing guide
├── README_TEAM.md                    # Internal team brief (tracks, sponsors, script)
├── AGENTS.md                         # Agent handoff notes & technical status
├── api/
│   └── [...path].js                  # Vercel serverless proxy backend
├── docs/
│   ├── Runway90_Product_Spec_Packet.md  # Official product spec
│   └── TECH_STACK.md                 # Deep technical architecture reference
└── Runway90/
    ├── App/
    │   └── Runway90App.swift         # @main App, root routing, shake detection
    ├── Theme/
    │   └── Theme.swift               # Palette & Liquid Glass modifiers
    ├── Models/
    │   └── Models.swift              # Data models, Maya fixture, extraction schema
    ├── Store/
    │   └── AppStore.swift            # Central @MainActor state store & actions
    ├── Adapters/
    │   ├── BackendAPI.swift          # Authenticated API client
    │   ├── GeminiAdapter.swift       # Vision extraction adapter
    │   ├── BackboardAdapter.swift    # Case memory adapter
    │   ├── TigerDataAdapter.swift   # Financial event-sourcing adapter
    │   └── AuthAdapter.swift         # Auth0 login & role switcher
    ├── Views/
    │   ├── DisclosureView.swift      # Synthetic data disclosure
    │   ├── RoleEntryView.swift       # Redesigned Liquid Glass login screen
    │   ├── SurvivorHomeView.swift    # Maya's Day 6 dashboard
    │   ├── CaptureView.swift         # Document review & fact confirmation
    │   ├── SyntheticLetterView.swift # Native in-app synthetic collection letter
    │   ├── ReclaimView.swift         # Confirmed debt, unrecognised debt, timeline
    │   ├── RunwayView.swift          # Runway days counter, charts, next action
    │   ├── AdvocateView.swift        # Scoped advocate summary & approval
    │   └── DecoyView.swift           # Neutral weather decoy screen
    └── Resources/
        ├── Assets.xcassets/          # Art assets & app icons
        ├── Auth0.plist               # Public client ID & domain
        └── Secrets.example.plist     # Template for optional private API credentials
```

---

## Sources & References

1. **National Network to End Domestic Violence (NNEDV):** [About Financial Abuse](https://nnedv.org/content/about-financial-abuse/)
2. **Surviving Economic Abuse (SEA):** [Understanding Economic Abuse](https://survivingeconomicabuse.org/what-is-economic-abuse/)
3. **National Library of Medicine (PMC9121607):** [Examining the Impact of Economic Abuse on Survivors](https://pmc.ncbi.nlm.nih.gov/articles/PMC9121607/)
4. **Journal of Interpersonal Violence (PMC7427218):** [IPV in Transgender Populations](https://pmc.ncbi.nlm.nih.gov/articles/PMC7427218/)
5. **New York State Office for the Prevention of Domestic Violence (OPDV):** [Survivors Access Financial Empowerment (SAFE)](https://opdv.ny.gov/survivors-access-financial-empowerment-safe)

---

<div align="center">
Built with care for HackHers @ Georgia State University.
</div>
