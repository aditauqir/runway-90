# Runway 90 — Product Spec Packet

**Hackathon:** HackHers @ GSU  
**Track:** FinanceHER — Building Financial Independence  
**Target:** iPhone demo  
**Primary prize targets:** Gemini, Backboard, Tiger Data, Auth0  
**Build status:** Hackathon vertical slice, not a production financial service

## Copy this to the build agent first

You are building the first demo of **Runway 90**, a private financial-recovery companion for cis and trans women rebuilding after economic abuse.

Build one reliable, judge-facing vertical slice. Do not expand the scope into a full budgeting app, a real grant platform, a credit-monitoring product, or a general chatbot.

The demo must prove this loop:

**Synthetic document → Gemini extraction → survivor confirmation → Tiger Data runway update → one next action → Auth0-scoped advocate handoff → Backboard remembers the case.**

Use fictional data only. Display this warning inside the app:

> Synthetic demo data. No real financial accounts, survivors, advocates, or organisations are represented.

Target iPhone. Prefer SwiftUI if starting from zero. Flutter targeting iOS is acceptable only if an existing Flutter scaffold already works. Do not spend hackathon time switching frameworks.

## 1. Product promise

Women leaving economic abuse often have documents but no trustworthy, confirmed picture of what they owe, what is theirs, or what to do next. Runway 90 lets the user:

1. Capture a financial document.
2. Review extracted facts.
3. Mark each fact **Mine**, **Not mine**, or **Not sure**.
4. See a runway estimate based only on confirmed information.
5. Receive one practical next action with a reason.
6. Reopen later without retelling the story.
7. Share a neutral summary with a verified advocate.

The app must never declare an account to be fraud. Use **unrecognised**, **inconsistent**, or **requires review**.

## 2. Demo persona and fixture data

Use one pre-seeded fictional survivor. Do not build live onboarding for the demo.

### Maya

- Case day: 6
- Role: Survivor
- Confirmed facts: 3
- Credit bureau status: Experian frozen
- Open task: TransUnion still needs review
- Current runway: 18 days of essential expenses
- Largest gaps: transportation and housing deposit
- Preferred next action: request transportation support

### Synthetic collection letter

Create a clearly fictional image or PDF named `maya_collection_letter.png`.

- Counterparty: `Northstar Collections`
- Account ending: `4471`
- Amount: `$2,310`
- Opened: `03/2024`
- Initial extraction status: `requires_review`
- User action in demo: tap **Not mine**

Do not use real user documents. Do not use a real person’s name, account number, address, phone number, or uploaded financial record.

### Transportation request

- Request type: transportation support
- Amount: `$250`
- State at start: pending
- Advocate action: approve
- State after approval: approved
- Runway change: 18 days → 31 days

The request approval is mocked and must be labelled **Demo approval**.

## 3. The exact three-minute demo

The app opens directly into the pre-seeded demo. No live onboarding.

### Beat 1 — Reopen Maya’s case

Show a survivor home screen with:

> Welcome back, Maya. You froze Experian and confirmed two accounts. TransUnion is still open. Want to review the letter you mentioned?

This text must come from persisted case memory, not a hardcoded screen-only string.

**Judge sees:** Backboard memory across a restart or session reload.

### Beat 2 — Capture a document

Tap **Review letter**. Provide two paths:

- **Demo path:** choose the bundled synthetic letter from the photo picker.
- **Device path:** use the camera if the device supports it.

Show a short extraction state, then display confirm cards:

- Northstar Collections
- Account ending 4471
- Amount $2,310
- Opened March 2024
- Status requires review

**Judge sees:** Gemini vision and structured extraction.

### Beat 3 — Survivor confirms the truth

Each extracted fact must have three explicit choices:

- Mine
- Not mine
- Not sure

Select **Not mine** for the synthetic account. Move the item into:

- Unrecognised accounts
- The chronological case timeline
- The neutral advocate summary

Nothing may enter the confirmed case record before the user chooses a status.

### Beat 4 — Runway and one next action

Show a runway view:

- Current runway: **18 days**
- Largest gaps: transportation and housing deposit
- One suggested action: **Request transportation support**
- Explanation: `Transportation support protects the next work and appointment days.`

Do not show five competing recommendations. The product gives one next action.

**Judge sees:** Tiger Data event storage and runway time-series behavior.

### Beat 5 — Advocate handoff and safety close

Tap **Share neutral summary**. Switch to the advocate role.

The advocate flow must show:

1. Auth0 role separation.
2. MFA or a clearly labelled demo-MFA fallback.
3. Only the summary Maya explicitly shared.
4. A **Demo approval** button for the transportation request.

Approve the request. Return to Maya’s account. Animate or visibly update the runway from **18 days** to **31 days**.

Trigger quick exit using shake or triple-tap. Provide a visible fallback button for the simulator. Show a decoy screen with no case information.

Close with:

> Everything you saw was synthetic. She never had to tell her story twice.

## 4. Required screens

| Screen | Required behavior |
|---|---|
| Safety disclosure | Shows synthetic-data warning and explains that this is a demo, not emergency, legal, financial, or therapeutic advice. |
| Demo role entry | Lets the presenter enter Maya as Survivor or Demo Advocate. Use Auth0 when configured and a labelled local fallback otherwise. |
| Survivor home | Shows day 6, 18-day runway, confirmed facts, pending task, and Backboard memory message. |
| Document capture | Photo picker plus optional camera path. Bundled synthetic fixture must always work. |
| Gemini extraction | Shows extraction state and structured fact cards. |
| Fact confirmation | Mine, Not mine, Not sure. Default every new fact to unconfirmed. |
| Reclaim workspace | Shows confirmed facts, unrecognised accounts, documents, and timeline. |
| Runway | Shows days covered, largest gaps, runway history, and exactly one next action. |
| Advocate summary | Shows only explicitly shared neutral information. No private notes or unconfirmed facts. |
| Advocate approval | Shows demo request and approve action. |
| Safety decoy | Contains no case history, document thumbnail, name, amount, or notification preview. |

## 5. Data model

Use stable IDs. Keep the model small and explicit.

```text
User
  id
  displayName
  role: survivor | advocate
  safetyModeEnabled

Case
  id
  userId
  dayNumber
  runwayDays
  confirmedFactIds[]
  sharedSummaryIds[]
  pendingTaskId

Document
  id
  caseId
  localAssetName
  documentType
  createdAt
  extractionStatus

FinancialFact
  id
  documentId
  type
  counterparty
  accountLast4
  amount
  openedDate
  reviewStatus: mine | not_mine | not_sure | unconfirmed

TimelineEvent
  id
  caseId
  type
  timestamp
  payload

AssistanceRequest
  id
  caseId
  type
  amount
  status: pending | approved
  sharedWithAdvocate

MemoryEntry
  id
  caseId
  key
  value
  updatedAt
```

### Initial fixture state

```json
{
  "user": { "id": "maya-demo", "displayName": "Maya", "role": "survivor" },
  "case": {
    "id": "case-maya-001",
    "dayNumber": 6,
    "runwayDays": 18,
    "confirmedFactIds": ["fact-rent", "fact-paycheck", "fact-experian-freeze"],
    "pendingTaskId": "task-transunion"
  },
  "request": {
    "id": "request-transport-001",
    "type": "transportation support",
    "amount": 250,
    "status": "pending",
    "sharedWithAdvocate": false
  }
}
```

## 6. Sponsor integration contracts

The four sponsor integrations must be visible in the demo. Use adapters so the app still runs when a credential or network call is unavailable.

### Gemini

**Purpose:** extract structured facts from the synthetic collection letter.

Required behavior:

- Send the bundled fixture image to Gemini when credentials are available.
- Request JSON, not free-form prose.
- Render the returned facts as confirmation cards.
- Keep the user as the source of truth.
- Never label the account fraud.

Expected extraction shape:

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

Fallback: use the same JSON fixture and show `Demo extraction` in the UI. Do not fake a successful live API call.

### Backboard

**Purpose:** persistent memory across app restarts.

Persist at minimum:

- Maya’s confirmed facts
- Experian frozen status
- Last completed action
- Pending TransUnion task
- Last suggested next action
- Sharing preference

After closing and reopening the app, the home screen must still produce the Maya memory message. Fallback: local persistence with `Demo memory fallback` shown only in a developer/debug indicator.

### Tiger Data

**Purpose:** event-backed runway history.

Record events for:

- Fact confirmed
- Account marked not mine
- Assistance request created
- Assistance request approved
- Runway recalculated

The demo must show at least two runway snapshots:

```text
Before request approval: 18 days
After request approval: 31 days
```

Fallback: use a local event store with the same event schema and label it `Demo data source`.

### Auth0

**Purpose:** role separation and scoped sharing.

Required roles:

- `survivor`
- `advocate`

The advocate can see only the neutral summary explicitly shared by Maya. The advocate cannot see unconfirmed facts, private notes, the full document image, or the entire case timeline.

Fallback: local demo role switch labelled `Demo login`. Never imply that a local switch is production authentication.

## 7. Safety requirements

These are product requirements, not optional polish.

- Show the synthetic-data warning on the first screen and demo close screen.
- Add quick exit through shake or triple-tap.
- Add a simulator-friendly quick-exit button.
- Quick exit opens a blank decoy screen.
- Add a duress-PIN placeholder that opens an empty profile.
- Use neutral labels such as `You have a reminder`.
- Do not include real notifications in the demo.
- Do not store real names, addresses, account numbers, locations, or uploaded documents.
- Add **Delete demo case** and clear all local fixture state.
- Never instruct a user to confront a partner, leave immediately, call police, or make a legal decision.
- Add a visible disclaimer: not an emergency service, lawyer, therapist, or financial adviser.

## 8. Explicitly out of scope

Do not build these for the first demo:

- Real credit-bureau APIs
- Real bank connections
- Real money movement or cryptocurrency payments
- Real grant distribution
- Legal document generation
- Production notification delivery
- Web scraping of survivor posts
- Emotion detection or camera-based trauma analysis
- Voice features
- Full budgeting and investment tools
- Multi-user messaging
- Real partner-organisation verification

The demo should prove the product loop, not pretend to be a deployable social-service platform.

## 9. Build order

Build in this order and stop when the acceptance criteria pass.

1. Create the iPhone shell, theme, synthetic-data disclosure, and demo role entry.
2. Seed Maya’s case and render the survivor home screen.
3. Add document fixture selection and Gemini extraction adapter.
4. Add confirmation states and the Reclaim workspace.
5. Add event-backed runway calculation and the 18-to-31 update.
6. Add Backboard memory and prove it survives a restart.
7. Add Auth0 survivor/advocate roles and scoped summary.
8. Add quick exit, decoy screen, deletion, and the final demo script.
9. Record the happy-path demo before the event.

If an external API is unstable, keep the adapter and use the labelled fixture fallback. Do not let a missing API key block the entire app.

## 10. Definition of done

The initial demo is complete only when all of these are true:

- [ ] The app opens directly to Maya’s seeded case.
- [ ] Synthetic-data warning is visible.
- [ ] The bundled collection letter always loads.
- [ ] Gemini integration or clearly labelled extraction fallback produces the expected facts.
- [ ] The user can select Mine, Not mine, or Not sure.
- [ ] Unrecognised account appears in the case timeline.
- [ ] Home screen shows 18 runway days before approval.
- [ ] One next action is shown with a reason.
- [ ] The advocate sees only the explicitly shared summary.
- [ ] Approval changes the request state to approved.
- [ ] Runway changes from 18 to 31 days.
- [ ] Backboard memory survives a reload, or the labelled fallback does.
- [ ] Auth0 roles work, or the labelled demo-login fallback works.
- [ ] Quick exit works on a physical device or simulator button.
- [ ] Delete demo case clears the case and returns to the disclosure screen.
- [ ] A backup screen recording exists.
- [ ] The app never uses real personal or financial data.

## 11. Presenter script

> This is Maya, day six after leaving an economically abusive household. The data is synthetic. Runway 90 remembers that she froze Experian yesterday, so she does not have to retell the story. She reviews a fictional collection letter. Gemini extracts the account, amount, and date, but Maya decides what is true. She marks the account not hers. The app shows 18 days of essentials covered and gives her one next action: request transportation support. An advocate signs in through a separate role, sees only the summary Maya shared, and approves the demo request. Her runway moves to 31 days. Then we trigger quick exit, because a phone can be watched. Runway 90 does not promise to solve abuse. It gives her a financial record she controls and a next step she can choose.

## 12. References

The product rationale, sponsor mapping, safety requirements, and demo beats are based on the Runway 90 concept brief supplied with this project.

- NNEDV — About Financial Abuse: <https://nnedv.org/content/about-financial-abuse/>
- Surviving Economic Abuse — What is economic abuse?: <https://survivingeconomicabuse.org/what-is-economic-abuse/>
- Examining the impact of economic abuse on survivors: <https://pmc.ncbi.nlm.nih.gov/articles/PMC9121607/>
- IPV in Transgender Populations: <https://pmc.ncbi.nlm.nih.gov/articles/PMC7427218/>
- Transgender survivors and shelters: <https://journals.sagepub.com/doi/10.1177/10443894231196929>
- NY OPDV — Survivors Access Financial Empowerment: <https://opdv.ny.gov/survivors-access-financial-empowerment-safe>
- MLH HackHers @ GSU prize list
