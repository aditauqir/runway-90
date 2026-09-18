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

*HackHers @ GSU · Track: FinanceHER — Building Financial Independence*  
*Target: iOS 18.0+ (SwiftUI · Liquid Glass Design)*  
*Key Integrations: Google Gemini · Backboard · Tiger Data · Auth0 by Okta*

[![iOS 18.0+](https://img.shields.io/badge/iOS-18.0%2B-blue.svg?logo=apple&style=flat-square)](https://developer.apple.com/ios/)
[![Swift 5.10](https://img.shields.io/badge/Swift-5.10-orange.svg?logo=swift&style=flat-square)](https://swift.org)
[![XcodeGen](https://img.shields.io/badge/Project-XcodeGen-blueviolet.svg?style=flat-square)](https://github.com/yonaskolb/XcodeGen)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

> *"Leaving is an event. Financial independence is the next 90 days."*

</div>

---

## Table of Contents

- [The Problem](#the-problem)
- [What Runway 90 Does](#what-runway-90-does)
- [The 5-Beat Demo Loop](#the-5-beat-demo-loop)
- [Sponsor Architecture & Technical Reference](#sponsor-architecture--technical-reference)
  - [Google Gemini API (Vision & Structured Extraction)](#1-google-gemini-api-vision--structured-extraction)
  - [Backboard (Cross-Session Persistent Memory)](#2-backboard-cross-session-persistent-memory)
  - [Tiger Data / Timescale Cloud (Event-Sourced Runway)](#3-tiger-data--timescale-cloud-event-sourced-runway)
  - [Auth0 by Okta (Role Separation & Scoped Access)](#4-auth0-by-okta-role-separation--scoped-access)
  - [Deliberate Exclusions](#deliberate-exclusions-demonstrating-product-judgment)
- [Safety & Trauma-Informed Principles](#safety--trauma-informed-principles)
- [Design System — Liquid Glass](#design-system--liquid-glass)
- [Getting Started: Build & Run on Any Device](#getting-started-build--run-on-any-device)
  - [Prerequisites](#prerequisites)
  - [1. Clone Repository & Install XcodeGen](#1-clone-repository--install-xcodegen)
  - [2. Generate Xcode Project](#2-generate-xcode-project)
  - [3. Configuration & Secrets (Optional)](#3-configuration--secrets-optional)
  - [4. Build & Run in Xcode GUI](#4-build--run-in-xcode-gui)
  - [5. CLI Build Commands](#5-cli-build-commands)
  - [6. Troubleshooting & Gotchas](#6-troubleshooting--gotchas)
- [Repository Structure](#repository-structure)
- [Data Model & Database Schema](#data-model--database-schema)
- [Demo Script & Pitch](#demo-script--pitch)
- [Sources & References](#sources--references)

---

## The Problem

Financial abuse is present in **~99% of domestic violence cases** ([NNEDV](https://nnedv.org/content/about-financial-abuse/)). It is the single most cited reason survivors stay in or return to unsafe environments. An abuser frequently controls bank access, forces debt into the partner's name, ruins credit, conceals obligations, and confiscates income.

When a woman finally leaves, she faces systemic barriers:
- **Zero accessible liquidity:** Accounts are drained, monitored, or locked.
- **Coerced, invisible debt:** Collections letters arrive for credit lines, loans, and bills she never opened or knew existed.
- **Wrecked credit:** Poor credit scores prevent securing an apartment lease, opening a phone plan, financing reliable transport, or passing employment checks.
- **A mountain of bewildering paperwork:** Creditor notices, bureau reports, and legal notices that must be untangled under severe cognitive and emotional stress.
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

1. **Multimodal Document Ingestion:** Uses Google Gemini vision to extract counterparties, account numbers, balances, and opening dates into structured cards.
2. **Survivor-Controlled Truth:** Nothing enters the confirmed case record without survivor verification. The app **never** labels an account as "fraud" — only *unrecognised*, *inconsistent*, or *requires review*.
3. **Continuous Runway Metric:** Displays financial runway in days (e.g., *"18 days of essential expenses covered"*), powered by an event-backed time-series model.
4. **Single Next Action:** Eliminates decision fatigue by suggesting exactly **one** actionable next step with clear rationale, avoiding competing priorities.
5. **Persistent Cross-Session Memory:** Remembers confirmed facts, bureaus frozen, active deadlines, and preferences via Backboard. Survivors never have to re-explain their situation.
6. **Scoped Advocate Handoff:** Generates a neutral, aggregate summary that can be shared with an advocate through Auth0 role separation. Private notes, unconfirmed facts, and original documents remain completely private.

---

## The 5-Beat Demo Loop

Runway 90 is engineered to prove its end-to-end loop in a crisp, 3-minute demo using pre-seeded fixture data for **Maya** (Day 6 of recovery, 18-day runway, Experian frozen, TransUnion pending).

```
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                         THE 3-MINUTE DEMO WORKFLOW                          │
 └─────────────────────────────────────────────────────────────────────────────┘

 Beat 1: Reopen Maya's Case
 ─────────────────────────
 • Opens directly into Maya's active recovery session.
 • Home card displays a personalized memory message synthesized from persisted
   MemoryEntry records (via Backboard):
   "Welcome back, Maya. You froze Experian and confirmed two accounts.
    TransUnion is still open. Want to review the letter you mentioned?"

 Beat 2: Ingest Document via Gemini Vision
 ─────────────────────────────────────────
 • Tap "Review letter" -> Select bundled synthetic collection letter (or camera).
 • Gemini 3.6 Flash analyzes the image and extracts structured metadata:
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

 Beat 4: Tiger Data Runway & Single Next Action
 ──────────────────────────────────────────────
 • Runway screen displays 18 days of essential expenses covered.
 • Apple Charts visualizes the historical runway time-series.
 • Highlights largest remaining gaps: Transportation & Housing deposit.
 • Proposes exactly ONE next action: "Request transportation support ($250)".
 • Survivor submits the request and taps "Share neutral summary".

 Beat 5: Scoped Advocate Handoff & Quick Exit Close
 ──────────────────────────────────────────────────
 • Switch to Advocate Role (Auth0 Universal Login / Demo MFA gate).
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

## Sponsor Architecture & Technical Reference

Runway 90 integrates four sponsors where each serves a load-bearing architectural role. If any sponsor is removed, the product loop breaks.

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                       RUNWAY 90 ARCHITECTURE                                    │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                  │
                 ┌────────────────────────────────┼────────────────────────────────┐
                 │                                │                                │
                 ▼                                ▼                                ▼
       ┌───────────────────┐            ┌───────────────────┐            ┌───────────────────┐
       │   Google Gemini   │            │     Backboard     │            │    Tiger Data     │
       │   (Vision AI)     │            │  (Case Memory)    │            │ (Event Sourcing)  │
       └───────────────────┘            └───────────────────┘            └───────────────────┘
                 │                                │                                │
        Multimodal extraction           Long-term state recall           Direct TLS Postgres
        gemini-3.6-flash                app.backboard.io/api             hypertable on db-90
        Strict JSON schema              One assistant per case           Timescale continuous
        Zero-markdown contract          Thread messages with             aggregates for runway
                                        memory: "auto"                   history chart
                 │                                │                                │
                 └────────────────────────────────┼────────────────────────────────┘
                                                  │
                                                  ▼
                                        ┌───────────────────┐
                                        │  Auth0 by Okta    │
                                        │  (Identity & RBAC)│
                                        └───────────────────┘
                                                  │
                                         Universal Login PKCE
                                         Custom URL scheme callback
                                         Roles claim: survivor vs advocate
                                         Scoped, revocable data isolation
```

### 1. Google Gemini API (Vision & Structured Extraction)
- **Role:** Extracts accounts, balances, dates, and counterparties from camera photos or photo library documents.
- **Model:** `gemini-3.6-flash` via Google Generative Language API endpoint:
  ```http
  POST https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key={GEMINI_API_KEY}
  ```
- **Contract:** Uses `generationConfig.response_mime_type: "application/json"` to enforce raw JSON parsing without markdown fences (` ```json `):
  ```json
  {
    "documentType": "collection_letter",
    "facts": [
      {
        "counterparty": "Northstar Collections",
        "accountLast4": "4471",
        "amount": 2310,
        "openedDate": "2024-03",
        "reviewStatus": "unconfirmed"
      }
    ]
  }
  ```
- **Fallback:** Bundled `Fixture.extractionFixture` returning identical JSON structure, visibly tagged with a `Demo extraction` badge in the UI.

### 2. Backboard (Cross-Session Persistent Memory)
- **Role:** Overcomes LLM statelessness by maintaining long-term case memory, past actions, frozen bureaus, and survivor preferences.
- **Endpoint:** `https://app.backboard.io/api` with authentication header `X-API-Key: {BACKBOARD_API_KEY}`.
- **Implementation:**
  - Creates/reuses one assistant per case (`POST /assistants` with name `runway90-{caseId}`).
  - Emits memory snapshots via `POST /threads/messages` with `"memory": "auto"`.
  - Recalls cross-thread memories (`retrieved_memories: true`).
- **Memory Assembly:** The home greeting is generated at runtime from `MemoryEntry` key-value pairs (`experian_status`, `last_action`, `pending_task`, `mentioned_letter`), rather than static strings.
- **Fallback:** Local atomic JSON persistence (`Documents/runway90_case_state.json`) with a `Demo memory fallback` badge.

### 3. Tiger Data / Timescale Cloud (Event-Sourced Runway)
- **Role:** Financial runway is a continuous time-series aggregate, not a static number. Every confirmed fact, expense, and request is an immutable event.
- **Service Details:** Tiger Cloud service `db-90`, database `tsdb`.
- **Direct Wire Protocol:** Direct TLS connection from Swift to PostgreSQL via `PostgresClientKit` (SCRAM-SHA-256 authentication). **No middle-tier proxy required.**
- **Database Hypertable Schema:**
  ```sql
  CREATE TABLE events (
    id text NOT NULL,
    case_id text NOT NULL,
    type text NOT NULL,
    timestamp timestamptz NOT NULL,
    payload jsonb
  );
  SELECT create_hypertable('events', 'timestamp', if_not_exists => TRUE);
  ```
- **Event Types Emitted:** `fact_confirmed`, `account_marked_not_mine`, `fact_needs_review`, `assistance_request_created`, `assistance_request_approved`, `runway_recalculated`, `summary_shared`.
- **Fallback:** Local event log in `CaseState.timeline` with `Demo data source` badge.

### 4. Auth0 by Okta (Role Separation & Scoped Access)
- **Role:** Enforces strict role-based access control between the **Survivor** and the **Advocate**.
- **SDK:** `Auth0.swift` (v2.22+) using PKCE authorization code grant over custom URL scheme (`com.hackhers.runway90`).
- **Role Mapping:** Inspects custom JWT claim `https://runway90.app/roles`:
  - `roles.contains("advocate")` -> `.advocate` (Advocate Dashboard).
  - Otherwise -> `.survivor` (Survivor Reclaim Workspace).
- **Data Scoping:** The advocate view can **only** query explicitly shared aggregate summaries (`summaryShared == true`). Advocates have zero access to document photos, raw timelines, or unconfirmed facts.
- **MFA Enforcement:** Tenant-enforced multi-factor authentication for advocates. Live Auth0 sessions skip in-app MFA; demo mode provides a 6-digit simulation sheet.
- **Fallback:** Labelled `Demo login` local role toggle.

### Deliberate Exclusions (Demonstrating Product Judgment)
Judges appreciate teams that know what **not** to build:
- **No Cryptocurrency / On-Chain Vouchers (e.g., Solana):** Money movement does not solve coerced debt disputes and adds unnecessary complexity.
- **No Audio/Voice Synthesis (e.g., ElevenLabs):** Audio playing aloud in a cohabitated, unsafe home is a severe physical hazard.
- **No Emotion Detection (e.g., Presage):** Subjecting a trauma survivor to webcam emotional analysis is invasive and ethically fraught.

---

## Safety & Trauma-Informed Principles

Runway 90 was architected around the reality that a survivor's phone may be monitored by an abuser:

| Safety Feature | Implementation | Behavior |
|---|---|---|
| **Shake to Exit** | `UIWindow.motionEnded` override | Shaking the iPhone immediately replaces all content with the Decoy screen. |
| **Triple-Tap Exit** | `.onTapGesture(count: 3)` on root screens | Discreet alternative to shaking when physical movement must be minimized. |
| **Quick Exit Button** | Toolbar `xmark.shield.fill` button | Guaranteed exit mechanism on all screens (especially in Simulator). |
| **Decoy Screen** | `DecoyView` (system light theme) | Displays innocuous weather widget (`68° Partly Cloudy`) and neutral notes. |
| **Decoy Return PIN** | Secure PIN entry | Enter `0000` to return to Runway 90. |
| **Duress PIN Placeholder**| Any other 4-digit code | Empties the decoy state without displaying error messages. |
| **Neutral Notifications**| System copy | Alerts read: *"You have a reminder"* — never exposing financial or domestic terms. |
| **Complete Data Erasure**| "Delete demo case" action | Atomically removes local JSON, clears session, and reseeds clean state. |
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

- **Adaptive Glass Material:** Implements native iOS 26+ `.glassEffect()` modifiers with graceful fallback to `.ultraThinMaterial` on iOS 18.0+.
- **Dynamic Numeric Transitions:** Runway numbers animate smoothly using `.contentTransition(.numericText())` when approval shifts runway from 18 to 31 days.
- **Decoy Contrast:** Decoy screen deliberately abandons dark glass styling in favor of stark system light backgrounds to look entirely unbranded.

---

## Getting Started: Build & Run on Any Device

Follow these instructions to clone, configure, build, and run Runway 90 on a Mac running Xcode.

### Prerequisites
- **macOS:** macOS Sonoma (14.0+) or Sequoia (15.0+)
- **Xcode:** Xcode 16.0+ (Xcode 27 recommended, Swift 5.10)
- **XcodeGen:** Utility to generate the `.xcodeproj` from declarative `project.yml`:
  ```sh
  brew install xcodegen
  ```
- **Optional Tools:**
  - `libpq` for direct database inspection via `psql`: `brew install libpq`
  - iOS physical device or Simulator with iOS 18.0+ runtime installed.

---

### 1. Clone Repository & Install XcodeGen

```sh
# Clone repository
git clone https://github.com/aditauqir/runway90.git
cd runway90

# Ensure xcodegen is installed
brew install xcodegen
```

### 2. Generate Xcode Project

Runway 90 uses `project.yml` as its source of truth to avoid merge conflicts in `.pbxproj` files:

```sh
xcodegen generate
```
*This produces a clean, configured `Runway90.xcodeproj` linked with Swift Package dependencies (`PostgresClientKit` and `Auth0.swift`).*

---

### 3. Configuration & Secrets (Optional)

The app is **100% functional out of the box** without any API keys. When keys are absent, all adapters smoothly run labelled demo fallbacks:
- Gemini -> *"Demo extraction"*
- Backboard -> *"Demo memory fallback"*
- Tiger Data -> *"Demo data source"*
- Auth0 -> *"Demo login"* / *"Demo approval"*

To enable live cloud integrations, set up `Secrets.plist`:

```sh
# Copy template
cp Runway90/Resources/Secrets.example.plist Runway90/Resources/Secrets.plist
```

Open `Runway90/Resources/Secrets.plist` and populate your credentials:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Google AI Studio Gemini API Key -->
    <key>GEMINI_API_KEY</key>
    <string>your_gemini_api_key_here</string>

    <!-- Backboard.io API Key -->
    <key>BACKBOARD_API_KEY</key>
    <string>your_backboard_api_key_here</string>

    <!-- Tiger Data / Timescale Cloud PostgreSQL URL -->
    <key>TIGER_DATA_URL</key>
    <string>postgres://tsdbadmin:password@host:port/tsdb?sslmode=require</string>

    <!-- Auth0 Tenant Configuration -->
    <key>AUTH0_DOMAIN</key>
    <string>your-tenant.us.auth0.com</string>
    <key>AUTH0_CLIENT_ID</key>
    <string>your_auth0_client_id_here</string>
</dict>
</plist>
```

> **Note on Auth0:** The repository includes a pre-configured `Runway90/Resources/Auth0.plist` pointed to a shared demo client with custom callback scheme `com.hackhers.runway90`.

---

### 4. Build & Run in Xcode GUI

1. Open the generated project in Xcode:
   ```sh
   open Runway90.xcodeproj
   ```
2. **Configure Code Signing:**
   - In Xcode's project navigator, select **Runway90** at the top.
   - Select the **Runway90** target -> **Signing & Capabilities** tab.
   - Under **Signing**, select your personal or organization Apple Team from the **Team** dropdown.
   - Set **Bundle Identifier** to `com.hackhers.runway90` (or a unique suffix if using a free personal team).
3. **Select Run Destination:**
   - In the top toolbar, select an iOS Simulator (e.g., **iPhone 16 Pro**) or your connected physical iPhone.
4. **Build & Run:**
   - Press **⌘R** or click the **Play** button.

---

### 5. CLI Build Commands

To verify compilation and linking directly from the terminal:

```sh
# Regenerate project file
xcodegen generate

# Build for generic iOS Simulator destination (skips code signing requirement)
xcodebuild -project Runway90.xcodeproj -scheme Runway90 \
  -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

---

### 6. Troubleshooting & Gotchas

- **"No simulator runtime installed":**
  If `xcodebuild` or Xcode reports missing runtimes, open Xcode -> **Settings** -> **Components** -> Download the latest **iOS Runtime** (iOS 18+).
- **Inspecting Live Tiger Data Events:**
  If you have configured `TIGER_DATA_URL`, view live event ingestion from terminal:
  ```sh
  /opt/homebrew/opt/libpq/bin/psql "$TIGER_DATA_URL" \
    -c "SELECT type, timestamp FROM events ORDER BY timestamp DESC LIMIT 10;"
  ```
- **Quick Exit in Simulator:**
  Trigger shake gesture in Simulator via **Device ▸ Shake** or tap the **Exit Shield Button** in the navigation bar.
- **Decoy Unlock PIN:**
  The PIN to exit the weather decoy screen is `0000`.

---

## Repository Structure

```
runway90/
├── project.yml                       # XcodeGen project specification
├── Runway90.xcodeproj                # Generated Xcode project
├── AGENTS.md                         # Agent handoff notes & verification status
├── docs/
│   ├── Runway90_Product_Spec_Packet.md  # Official product spec & demo beats
│   └── TECH_STACK.md                 # Deep technical architecture reference
└── Runway90/
    ├── App/
    │   └── Runway90App.swift         # @main App, root routing, shake detection
    ├── Theme/
    │   └── Theme.swift               # Palette & Liquid Glass view modifiers
    ├── Models/
    │   └── Models.swift              # Spec §5 data models, Maya fixture, Gemini JSON contract
    ├── Store/
    │   └── AppStore.swift            # Central @MainActor state store & business logic
    ├── Adapters/
    │   ├── Secrets.swift             # Configuration reader (Secrets.plist)
    │   ├── GeminiAdapter.swift       # Gemini 3.6 Flash vision extraction adapter
    │   ├── BackboardAdapter.swift    # Backboard assistant memory & local JSON sync
    │   ├── TigerDataAdapter.swift    # Direct TLS PostgreSQL client for Timescale hypertable
    │   └── AuthAdapter.swift         # Auth0 Universal Login & demo role switcher
    ├── Views/
    │   ├── DisclosureView.swift      # Synthetic data warning & disclosure screen
    │   ├── RoleEntryView.swift       # Role selector: Maya (Survivor) or Demo Advocate
    │   ├── SurvivorHomeView.swift    # Home dashboard, Backboard greeting, runway summary
    │   ├── CaptureView.swift         # Document capture, Gemini extraction, confirmation cards
    │   ├── SyntheticLetterView.swift # Native in-app rendered fictional collection letter
    │   ├── ReclaimView.swift         # Confirmed facts, unrecognised accounts, timeline
    │   ├── RunwayView.swift          # Big runway counter, Charts history, single next action
    │   ├── AdvocateView.swift        # Scoped summary view, demo MFA gate, request approval
    │   └── DecoyView.swift           # Neutral weather decoy screen (PIN 0000 escape)
    └── Resources/
        ├── Auth0.plist               # Public client ID & domain for Auth0.swift
        └── Secrets.example.plist     # Template for private API credentials
```

---

## Data Model & Database Schema

### Core Swift Models (`Models.swift`)
- **`User`:** Identity, display name, role (`.survivor` | `.advocate`), safety preferences.
- **`CaseRecord`:** Active recovery day number, runway days, confirmed fact references, pending task.
- **`DocumentRecord`:** Ingested document metadata, type, extraction status.
- **`FinancialFact`:** Extracted financial item, counterparty, last 4 digits, balance, opening date, `reviewStatus` (`.mine`, `.notMine`, `.notSure`, `.unconfirmed`).
- **`AssistanceRequest`:** Mutual aid / support request ($250 transportation), status (`.pending` | `.approved`).
- **`MemoryEntry`:** Key-value long-term memory records (`experian_status`, `pending_task`, `last_action`, `mentioned_letter`).
- **`RunwaySnapshot`:** Point-in-time runway calculation for time-series charts.

### Tiger Data (Timescale Cloud) Hypertable Schema
```sql
-- Timescale Cloud Hypertable for Case Events
CREATE TABLE events (
  id text NOT NULL,
  case_id text NOT NULL,
  type text NOT NULL,
  timestamp timestamptz NOT NULL,
  payload jsonb
);

-- Convert to Timescale continuous hypertable partitioned on timestamp
SELECT create_hypertable('events', 'timestamp', if_not_exists => TRUE);
```

---

## Demo Script & Pitch

### 30-Second Elevator Pitch
> *"Financial abuse is present in 99% of domestic violence cases. Women leave with nothing — with debt they didn't open, credit that's been wrecked, and a pile of paperwork they have to decode alone. Then they have to explain it, again and again, to every bank, shelter, and agency.*  
>  
> *Runway 90 reads her paperwork, lets her confirm what's really hers, shows her exactly how many days of runway she has, tells her the one next step — and remembers everything so she never has to retell her story.*  
>  
> *Leaving is an event. Financial independence is the next 90 days."*

### Presenter Walkthrough Script
> *"This is Maya, day six after leaving an economically abusive household. All data is synthetic.*  
>  
> *Notice the home screen: Runway 90 remembers that she froze Experian yesterday and has an open TransUnion task. She doesn't have to retell her story because Backboard holds her memory across sessions.*  
>  
> *Maya reviews a collection letter from Northstar Collections. Google Gemini extracts the account number, amount, and date. But Maya decides what is true. She marks the account 'Not mine'. It immediately updates her Reclaim record without ever labeling it 'fraud'.*  
>  
> *Her Runway view shows 18 days of essential expenses covered, backed by Tiger Data events. Rather than overwhelming her with twenty tasks, Runway 90 gives her exactly one next action: request $250 for transportation assistance.*  
>  
> *An advocate logs in through Auth0. Notice the advocate sees only the neutral summary Maya chose to share — no private notes, no unconfirmed facts. The advocate approves the transportation grant. Maya's runway animates from 18 to 31 days.*  
>  
> *If her phone is ever watched, a quick shake triggers the weather decoy screen.*  
>  
> *Everything you saw was synthetic. She never had to tell her story twice."*

---

## Sources & References

1. **National Network to End Domestic Violence (NNEDV):** [About Financial Abuse](https://nnedv.org/content/about-financial-abuse/)
2. **Surviving Economic Abuse (SEA):** [Understanding Economic Abuse](https://survivingeconomicabuse.org/what-is-economic-abuse/)
3. **National Library of Medicine (PMC9121607):** [Examining the Impact of Economic Abuse on Survivors](https://pmc.ncbi.nlm.nih.gov/articles/PMC9121607/)
4. **Journal of Interpersonal Violence (PMC7427218):** [IPV in Transgender Populations](https://pmc.ncbi.nlm.nih.gov/articles/PMC7427218/)
5. **New York State Office for the Prevention of Domestic Violence (OPDV):** [Survivors Access Financial Empowerment (SAFE)](https://opdv.ny.gov/survivors-access-financial-empowerment-safe)
6. **MLH HackHers @ GSU:** FinanceHER Track — Building Financial Independence

---

<div align="center">
Built with care for HackHers @ Georgia State University.
</div>
