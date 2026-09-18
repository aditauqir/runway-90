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

### She left. The debt didn't.

**Runway 90 is a private financial-recovery companion for women rebuilding after economic abuse.**

*The first tool built not around budgets, but around the truth she gets to decide.*

[![iOS 18.0+](https://img.shields.io/badge/iOS-18.0%2B-blue.svg?logo=apple&style=flat-square)](https://developer.apple.com/ios/)
[![Swift 5.10](https://img.shields.io/badge/Swift-5.10-orange.svg?logo=swift&style=flat-square)](https://swift.org)
[![Liquid Glass](https://img.shields.io/badge/Design-Liquid%20Glass-blueviolet.svg?style=flat-square)](https://developer.apple.com/design/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

</div>

---

> *"Leaving is an event. Financial independence is the next 90 days."*
>
> 99% of domestic violence involves financial abuse. She walks away with a phone full of collection letters for accounts she never opened, credit she didn't wreck, and bills she was never told existed. She has no clear picture, no confirmed record, and every new caseworker asks her to start from zero.
>
> **Runway 90 fixes that.**

---

## Why this exists

Financial abuse is the #1 reason survivors return to unsafe environments ([NNEDV](https://nnedv.org/content/about-financial-abuse/)). Not because they want to. Because they can't see a way through the next 90 days.

Every existing tool fails her:

| Tool | Why it fails |
|---|---|
| **Budgeting apps** (Mint, YNAB) | Assume stable income and that every transaction is hers |
| **Credit monitoring** (Credit Karma) | Treats all recorded debt as legitimate |
| **Shelters & hotlines** | Life-saving for safety, but can't untangle coerced consumer debt |
| **Spreadsheets** | Re-traumatize by forcing her to manually organize the chaos |

**Runway 90 is not a budgeting app.** It's a recovery companion that starts from zero and lets her decide what is true.

---

## What it does in 60 seconds

```
  Capture ──> Confirm ──> Runway ──> One action ──> Remembered
  ───────     ───────     ──────     ──────────     ──────────
  Photo a     Mine,       Days of    Not five       Picks up
  letter      Not mine,   essentials competing      where she
  or bill     Not sure    covered    priorities.    left off.
                                     Just one.      No retelling.
```

1. **Capture** a collection letter, bank statement, or credit notice
2. **Gemini vision** extracts the counterparty, account, amount, and date into structured cards
3. **She decides**: Mine / Not mine / Not sure. Nothing enters her record without her say
4. **One next action** with a reason — not a to-do list, not financial advice, just the single most impactful step
5. **An advocate** sees only what she chose to share. Never the raw document. Never the private notes. Never the unconfirmed facts
6. **Backboard memory** remembers everything across sessions. She never tells her story twice

---

## The 90-day runway metric

Most financial apps show a balance. Runway 90 shows **time**.

> **18 days** of essential expenses covered

That number is the only metric that matters when you're deciding whether to sign a lease, accept a shift, or ask for transportation help. When an advocate approves a $250 transportation request, she watches her runway animate from **18 days to 31 days** in real time.

Time is what she's buying. The app shows her exactly how much she has.

---

## Safety is not a feature. It's the architecture.

The phone might be monitored. The screen might be watched. Every design decision starts there.

| Threat | Defense |
|---|---|
| Someone grabs the phone | **Shake to exit** instantly opens the Weather app. Not a decoy screen inside the app — the actual Apple Weather app. If unavailable, a bland weather widget with zero case data. |
| Shoulder surfing | **Triple-tap** or the **shield button** does the same thing from any screen |
| Phone inspection | Decoy shows "Partly cloudy, 68°" and "You have a reminder" — nothing financial, no brand |
| Returning from decoy | PIN `0000` (configurable) returns to the app. Wrong PIN = empty profile, no error |
| Data discovery | **Delete demo case** atomically wipes everything and reseeds clean |
| Notification preview | All alerts read "You have a reminder" — never mentions money, accounts, or abuse |
| Account labels | The app **never says fraud**. Only: *unrecognised*, *inconsistent*, *requires review* |

---

## Trauma-informed onboarding

New users see a 5-page guided introduction:

1. **Welcome** — plain-language explanation, no urgency, no legal promises
2. **Privacy & Safety** — quick exit walkthrough with mandatory acknowledgement (Continue is disabled until she checks "I understand how quick exit works")
3. **How it works** — the 5-step loop as a visual timeline: capture, confirm, runway, next step, share
4. **Personalization** — display name, demo letter preference, session memory. Never asks for address, employer, bank, or account number. Option to save 3 synthetic documents to Photos for the demo
5. **Ready** — summary of choices + one primary action: "Review the demo letter"

Returning users skip straight to their case. Advocates never see survivor onboarding. Onboarding state is scoped per Auth0 subject — one user's completion never leaks to another.

---

## Synthetic demo documents

During onboarding, you can save 3 realistic-looking fictional financial documents to your photo library:

| Document | Contents |
|---|---|
| **Collection letter** | Northstar Collections, account ····4471, $2,310, opened 03/2024 |
| **Bank statement** | Peachtree Federal CU, checking ····8802, Sept 2024, suspicious $412 transaction marked with ? |
| **Credit bureau notice** | TransUnion dispute acknowledgement, 2 accounts in dispute (····4471, ····5509) |

All are clearly marked **FICTIONAL / SYNTHETIC**. Pick any of them from Photos during the demo's document capture flow and watch Gemini extract the structured facts.

---

## Sponsor integrations

| Sponsor | What it proves | Live? |
|---|---|---|
| **Gemini** | Vision extraction of financial documents into structured JSON cards | Verified |
| **Backboard** | Persistent case memory across app restarts — she never retells her story | Verified |
| **Tiger Data** | Event-sourced runway time-series in a TimescaleDB hypertable | Verified |
| **Auth0** | Universal Login, PKCE, role separation (survivor / advocate), scoped sharing | Verified |

Every integration has a labelled demo fallback. Missing credentials never crash the app — they show "Demo extraction", "Demo memory fallback", "Demo data source", or "Demo login" honestly in the UI.

---

## Design — Liquid Glass

Built with Apple's iOS 26 Liquid Glass design language. Falls back gracefully to `ultraThinMaterial` on iOS 18–25.

| Token | Hex | Role |
|---|---|---|
| `RW.raspberry` | `#B60E41` | Primary actions, gradient top |
| `RW.pink` | `#E03068` | Accent, approved states, chart stroke |
| `RW.mist` | `#C4DEE5` | Glass tint, secondary text |
| `RW.plum` | `#292227` | Background gradient base |
| `RW.cloud` | `#F5F5F5` | Primary text on dark |

- `.glassEffect()` cards with real depth and refraction on iOS 26+
- `.glassProminent` / `.glass` button styles
- `.contentTransition(.numericText())` for the 18→31 runway animation
- Decoy screen deliberately breaks the design system (light, unbranded, system background) so it reads as "not this app"

---

## Quick start

```bash
brew install xcodegen
xcodegen generate
open Runway90.xcodeproj
# Select your iPhone → ⌘R
```

No API keys needed for the demo — everything runs with synthetic fallbacks. To go live, fill `Runway90/Resources/Secrets.plist` (git-ignored) with sponsor credentials.

---

## The demo script

> This is Maya, day six after leaving an economically abusive household. The data is synthetic. Runway 90 remembers that she froze Experian yesterday, so she does not have to retell the story. She reviews a fictional collection letter. Gemini extracts the account, amount, and date, but Maya decides what is true. She marks the account not hers. The app shows 18 days of essentials covered and gives her one next action: request transportation support. An advocate signs in through a separate role, sees only the summary Maya shared, and approves the demo request. Her runway moves to 31 days. Then we trigger quick exit, because a phone can be watched. Runway 90 does not promise to solve abuse. It gives her a financial record she controls and a next step she can choose.

**Closing line:** *"Everything you saw was synthetic. She never had to tell her story twice."*

---

## Repository structure

```
runway90/
├── project.yml                       # XcodeGen spec (authoritative)
├── AGENTS.md                         # Agent handoff (read this first)
├── api/[...path].js                  # Vercel backend proxy
├── docs/
│   ├── Runway90_Product_Spec_Packet.md
│   ├── TECH_STACK.md                 # Deep technical reference
│   └── ONBOARDING_AGENT_PROMPT.md
└── Runway90/
    ├── App/Runway90App.swift          # Entry, routing, shake detection
    ├── Theme/Theme.swift              # Palette + Liquid Glass modifiers
    ├── Models/Models.swift            # Data model + Maya fixture
    ├── Store/AppStore.swift           # Central state + all actions
    ├── Adapters/                      # Gemini, Backboard, Tiger Data, Auth0
    └── Views/                         # All screens + synthetic documents
```

---

## Sources

1. [NNEDV — About Financial Abuse](https://nnedv.org/content/about-financial-abuse/)
2. [Surviving Economic Abuse — What is economic abuse?](https://survivingeconomicabuse.org/what-is-economic-abuse/)
3. [PMC — Impact of Economic Abuse on Survivors](https://pmc.ncbi.nlm.nih.gov/articles/PMC9121607/)
4. [PMC — IPV in Transgender Populations](https://pmc.ncbi.nlm.nih.gov/articles/PMC7427218/)
5. [NY OPDV — Survivors Access Financial Empowerment](https://opdv.ny.gov/survivors-access-financial-empowerment-safe)

---

<div align="center">

Built with care for **HackHers @ Georgia State University** | FinanceHER Track

*She never had to tell her story twice.*

</div>
