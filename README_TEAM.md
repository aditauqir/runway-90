# Runway 90 — Team & Collaborator Brief

> **CONFIDENTIAL / COLLABORATOR USE ONLY**  
> This document contains internal hackathon strategy, sponsor prize targets, live wire contracts, presenter scripts, and judging rubrics for **Runway 90**.

---

## 1. Hackathon & Track Overview

- **Hackathon:** HackHers @ Georgia State University (GSU) — Organized by the Girls Who Code College Loop.
- **Track:** **FinanceHER — Building Financial Independence**
- **Track Focus:** Creating technology and financial tools that empower women, protect vulnerable individuals, and provide sustainable paths toward financial self-determination.
- **Runway 90 Mission:** A private, persistent financial-recovery companion for women rebuilding after economic abuse. 
- **The Core Thesis:** *"Leaving is an event. Financial independence is the next 90 days."*

---

## 2. Sponsor Targets & Prize Alignment

Runway 90 was deliberately architected around **four sponsors**. Every sponsor is load-bearing; removing any one breaks the core loop.

```
  Synthetic Document
         │
         ▼
 ┌───────────────┐
 │ Google Gemini │  Multimodal extraction into structured cards
 └───────────────┘
         │
         ▼
 ┌───────────────┐
 │   Survivor    │  Survivor confirms truth: Mine / Not mine / Not sure
 └───────────────┘  (User is the source of truth; never labels "fraud")
         │
         ▼
 ┌───────────────┐
 │  Tiger Data   │  Runway continuous aggregate updates in TimescaleDB
 └───────────────┘  (Event-sourced time-series: 18 days → 31 days)
         │
         ▼
 ┌───────────────┐
 │   Auth0       │  Role separation & scoped sharing (Survivor vs Advocate)
 └───────────────┘  (Advocate sees only explicitly shared neutral summary)
         │
         ▼
 ┌───────────────┐
 │   Backboard   │  Persistent cross-session case memory across app restarts
 └───────────────┘  (She never has to retell her story)
```

### Sponsor Prize Breakdown

| Sponsor & Prize Category | Architectural Role | The Exact Moment a Judge Sees It | Technical Implementation & Wire Contract |
|---|---|---|---|
| **Google Gemini**<br>*(Best Use of Gemini API)* | Vision & structured extraction from financial paperwork (collection letters, credit reports, statements). | Beat 2: Presenter scans/selects synthetic collection letter; structured fact cards appear instantly with amounts, dates, and account numbers. | • Model: `gemini-3.6-flash`<br>• Enforces `response_mime_type: "application/json"`<br>• Backend proxy: `POST /api/extract`<br>• Zero-markdown JSON schema (`documentType`, `facts[]`)<br>• User confirmation required before saving. |
| **Backboard**<br>*(Best Use of Backboard)* | Cross-session long-term memory for the recovery companion. Solves AI statelessness so survivors don't retell trauma. | Beat 1: App opens after a reload: *"Welcome back, Maya. You froze Experian and confirmed two accounts. TransUnion is still open..."* | • Base URL: `https://app.backboard.io/api`<br>• Header: `X-API-Key`<br>• One assistant per Auth0 subject (`POST /assistants`)<br>• Thread messages with `"memory": "auto"`<br>• Memory recalled dynamically via `MemoryEntry` key-values. |
| **Tiger Data (Timescale Cloud)**<br>*(Best Use of Tiger Data)* | High-frequency event sourcing + relational snapshots for financial runway time-series. | Beat 4 & 5: Runway chart reads 18 days; when an assistance grant is approved, runway recalculates and jumps to 31 days. | • TimescaleDB Cloud service `db-90`<br>• Continuous aggregate hypertable `events`<br>• Scoped snapshots table `case_snapshots(owner_id primary key, payload jsonb)`<br>• Proxied via authenticated backend: `POST /api/events`, `GET/PUT /api/case`. |
| **Auth0 by Okta**<br>*(Best Use of Auth0)* | Strict role separation and scoped data isolation (Survivor vs Advocate) with tenant MFA. | Beat 5: Advocate logs in via Auth0; MFA challenge; advocate sees ONLY the neutral summary explicitly shared by Maya. | • Native `Auth0.swift` with PKCE authorization code grant<br>• Custom URL scheme: `com.hackhers.runway90://...`<br>• Custom JWT claim: `https://runway90.app/roles`<br>• Tenant-side Action injects roles into ID token. |

---

## 3. Deliberate Exclusions (Demonstrating Engineering Judgment)

When presenting to judges, explain why we **explicitly chose not to include** other hackathon tracks/technologies:

1. **No Cryptocurrency / On-Chain Vouchers (e.g., Solana):**
   *Why:* Survivors escaping abusive environments need to untangle legal consumer debt, clear credit bureau records, and access essential liquidity. An on-chain cryptocurrency token or NFT voucher is decorative, unhelpful to real landlords and utility companies, and distracts from core safety.
2. **No Voice / Audio Generation (e.g., ElevenLabs):**
   *Why:* A phone in an abusive household is frequently monitored or overheard. Audio playing aloud creates severe physical safety hazards for survivors.
3. **No Emotion Sensing / Facial Recognition (e.g., Presage):**
   *Why:* Subjecting a traumatized woman to camera-based emotion detection is invasive, clinically inaccurate, and ethically unacceptable in trauma-informed software.

---

## 4. The 3-Minute Demo Script (5 Beats)

Follow these 5 beats exactly during your presentation. Keep pacing crisp:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       3-MINUTE DEMO TIME ALLOCATION                         │
│                                                                             │
│  [0:00 - 0:30]  The Hook & Problem (Statistics, Trauma, Paperwork)         │
│  [0:30 - 1:00]  Beat 1: Reopen Maya's Case (Backboard Memory)               │
│  [1:00 - 1:40]  Beat 2 & 3: Document Capture & Survivor Confirmation       │
│  [1:40 - 2:15]  Beat 4: Tiger Data Runway & Single Next Action             │
│  [2:15 - 2:45]  Beat 5: Auth0 Advocate Handoff & 18→31 Animation           │
│  [2:45 - 3:00]  Safety Close & Final Pitch Line                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Script & Actions

#### Opening (0:00 - 0:30)
> *"Financial abuse occurs in 99% of domestic violence cases. When a woman leaves, she leaves with debt she didn't open, ruined credit, and a pile of paperwork she has to decode alone. Worst of all: she has to explain her trauma again and again to every bank, shelter, and agency. Runway 90 changes that."*

#### Beat 1: Reopen Maya's Case — Backboard Memory (0:30 - 1:00)
- **Action:** Open Runway 90. Tap "Welcome back, Maya" on the login screen.
- **Show Screen:** Home screen appears.
- **Point Out:** Look at the top card:
  > *"Welcome back, Maya. You froze Experian and confirmed two accounts. TransUnion is still open. Want to review the letter you mentioned?"*
- **Script:** *"This isn't a hardcoded screen string. Backboard remembers Maya's case across app restarts. She never has to retell her story."*

#### Beat 2 & 3: Gemini Vision & Survivor Confirmation (1:00 - 1:40)
- **Action:** Tap **Review letter** ▸ Tap **Use the demo letter**.
- **Show Screen:** Extraction loader briefly displays (`Reading the document...`), then structured confirmation cards appear:
  - *Northstar Collections · Ending 4471 · $2,310 · Opened 03/2024*
- **Action:** Tap **Not mine**.
- **Point Out:** 
  > *"Nothing enters the case record without survivor consent. We never use the word 'fraud'—only 'unrecognised' or 'requires review'. The account routes directly to her Reclaim timeline."*

#### Beat 4: Tiger Data Runway & Single Next Action (1:40 - 2:15)
- **Action:** Tap the **Runway** tab.
- **Show Screen:** Big numeric display: `18 days`. Apple Charts line graph showing runway history.
- **Script:** *"Tiger Data stores every financial event as an immutable time-series. Her current confirmed runway is 18 days. Instead of twenty overwhelming tasks, Runway 90 proposes exactly ONE next action: Request $250 for transportation assistance."*
- **Action:** Tap **Share neutral summary**.

#### Beat 5: Auth0 Advocate Handoff & 18→31 Animation (2:15 - 2:45)
- **Action:** In the confirmation dialog, tap **Switch to advocate view**. Complete the 6-digit demo MFA.
- **Show Screen:** Advocate View.
- **Point Out:** *"Through Auth0 role isolation, the advocate sees ONLY what Maya explicitly shared. Zero document photos, zero unconfirmed debts, zero private notes."*
- **Action:** Tap **Approve (Demo approval)**.
- **Action:** Tap **Back to Maya** in top-left.
- **Show Screen:** Runway tab. Watch the big number smoothly animate from **18 days → 31 days**!

#### Safety Close (2:45 - 3:00)
- **Action:** Shake the phone (or tap the **Shield** icon in the toolbar).
- **Show Screen:** Instant transition to the Weather Decoy Screen (`Partly Cloudy · 68°`).
- **Script:** *"If a phone might be watched, a shake or shield tap instantly hides everything behind a neutral decoy. Enter PIN 0000 to return."*
- **Closing Punchline:**
  > *"Everything you saw was synthetic. She never had to tell her story twice."*

---

## 5. Technical Architecture & Wire Formats

### Backend Architecture (`api/[...path].js`)
All sensitive sponsor credentials (`TIGER_DATA_URL`, `BACKBOARD_API_KEY`, `GEMINI_API_KEY`) reside on the secure Vercel serverless backend. The iOS app communicates using verified Auth0 JWT Bearer tokens:

```
iOS App (SwiftUI)
  │
  │ HTTPS (Bearer Auth0 Access Token)
  ▼
Vercel Serverless Function (api/[...path].js)
  │
  ├──► Verifies JWT via Auth0 JWKS (issuer, audience, sub)
  ├──► Proxies Gemini 3.6 Flash (Vision JSON extraction)
  ├──► Syncs Backboard memory assistants
  └──► Upserts & queries Tiger Cloud (TimescaleDB)
```

### PostgreSQL / TimescaleDB Schema (`TIGER_DATA_URL`)
```sql
-- Continuous hypertable for financial events
CREATE TABLE IF NOT EXISTS events (
  id text NOT NULL,
  case_id text NOT NULL,
  type text NOT NULL,
  timestamp timestamptz NOT NULL,
  payload jsonb
);
SELECT create_hypertable('events', 'timestamp', if_not_exists => TRUE);

-- Auth0 sub-scoped case state snapshots
CREATE TABLE IF NOT EXISTS case_snapshots (
  owner_id text PRIMARY KEY,
  case_id text NOT NULL,
  updated_at timestamptz NOT NULL,
  payload jsonb NOT NULL
);
```

### Backboard Assistant Integration
- **Endpoint:** `POST https://app.backboard.io/api/assistants`
- **Payload:** `{"name": "runway90-{subject}", "instructions": "Store case memory for survivor recovery."}`
- **Thread Memory:** `POST https://app.backboard.io/api/threads/messages` with payload:
  ```json
  {
    "assistant_id": "{assistant_id}",
    "content": "Memory update: experian_status=frozen, confirmed_facts=3, last_action=transport_approved",
    "memory": "auto"
  }
  ```

### Google Gemini Vision Request
- **Endpoint:** `POST https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key={GEMINI_API_KEY}`
- **Generation Config:** `{"response_mime_type": "application/json"}`
- **Prompt:** Enforces schema, forbids the word "fraud", sets `reviewStatus: "unconfirmed"`.

### Auth0 Universal Login & Custom Claim
- **Domain:** `skmpe.us.auth0.com`
- **Client ID:** `U7jFSU34Rfu3DJOCIcUzWCWxG08PwgCL`
- **Custom Claim:** `https://runway90.app/roles` -> `["survivor"]` or `["advocate"]`
- **Post-Login Action Code:**
  ```javascript
  exports.onExecutePostLogin = async (event, api) => {
    const roles = event.authorization?.roles || [];
    api.idToken.setCustomClaim("https://runway90.app/roles", roles);
    api.accessToken.setCustomClaim("https://runway90.app/roles", roles);
  };
  ```

---

## 6. Testing Environments

1. **Virtual iOS Simulator (Local Mac):**
   - Run via Xcode 27 / 16+ on iOS 18+ runtime.
   - Use `Device ▸ Shake` (`⌃⌘Z`) for quick exit testing.
   - Works 100% offline using labelled demo fallbacks even with zero API keys.
2. **Live Backend Verification:**
   - Deploy backend to Vercel with environment variables set from `.env.example`.
   - Update `BACKEND_BASE_URL` in `Runway90/Resources/Auth0.plist` to point to the live deployment.

---

<div align="center">
Runway 90 · HackHers @ GSU · FinanceHER Track
</div>
