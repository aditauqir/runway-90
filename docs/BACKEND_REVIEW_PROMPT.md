# Prompt for a second-agent review

Paste this prompt into another coding agent from the repository root:

```text
You are reviewing the Runway 90 iOS app plus its Vercel backend on branch
codex/tiger-auth0-persistence. Read AGENTS.md, docs/TECH_STACK.md,
docs/Runway90_Product_Spec_Packet.md, api/[...path].js, and the Swift adapters
before changing anything.

Review the complete live-user flow, not just compilation:

1. Auth0 Universal Login must request the configured API audience, return an
   access token, and use the verified `sub` as the only database owner key.
2. The backend must reject missing/expired/wrong-audience tokens, never trust a
   client-supplied owner ID, and keep survivor and advocate permissions
   separate.
3. `GET/PUT/DELETE /api/case` and `POST /api/events` must persist user data in
   Tiger Data with parameterized queries and no cross-user reads or writes.
4. Gemini and Backboard API keys must exist only in server-side environment
   variables. Confirm no real key, Postgres URL, or Secrets.plist is bundled in
   the Xcode target or TestFlight archive.
5. The iOS app must restore the authenticated user’s case on a fresh install,
   retain a clearly labeled offline/demo fallback, and avoid racing an old
   local cache into a newly authenticated account.
6. Preserve the product rules: synthetic data only, never say “fraud”, never
   confirm a fact before the user chooses Mine/Not mine/Not sure, exactly one
   runway next action, and advocates only see explicitly shared neutral data.
7. Add focused tests for JWT rejection, owner scoping, state normalization,
   event ownership, missing backend configuration, and fresh-install restore.
8. Build the iOS target with xcodebuild and run the backend syntax/tests. Report
   concrete findings first, then implement safe fixes. Do not upload to
   App Store Connect, rotate credentials, or change Auth0/Tiger production data
   without asking first.

At the end, report:
- bugs/security issues found;
- files changed and why;
- test commands and results;
- remaining manual Auth0/Vercel/Tiger setup;
- whether the next TestFlight archive is safe to share.
```
