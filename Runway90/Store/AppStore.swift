import SwiftUI
import UIKit

enum Route: Equatable {
    case disclosure
    case roleEntry
    case onboarding
    case survivor
    case advocate
    case decoy
}

@MainActor
final class AppStore: ObservableObject {

    @Published var route: Route = .disclosure
    @Published var state: CaseState
    @Published var session: AuthAdapter.Session?
    @Published var previousSession: AuthAdapter.Session?
    @Published var checkingPreviousSession = true

    // Extraction flow
    @Published var extracting = false
    @Published var extractionIsLive = false
    @Published var pendingFacts: [FinancialFact] = []

    // Was the app state restored from persistence? (proves Backboard memory beat)
    @Published var restoredFromMemory: Bool
    @Published var restoredFromTigerData = false

    // Onboarding state — scoped per authenticated subject
    @Published var onboardingPage: Int = 0
    @Published var onboardingSafetyAcked = false
    @Published var onboardingDisplayName = ""
    @Published var onboardingShowDemoLetter = true
    @Published var onboardingRememberSession = true

    init() {
        if let saved = BackboardAdapter.load() {
            state = saved
            restoredFromMemory = true
        } else {
            state = Fixture.fresh()
            restoredFromMemory = false
            BackboardAdapter.save(state)
        }
    }

    // MARK: - Memory message (Beat 1 — built from persisted memory, not hardcoded UI)

    var memoryMessage: String {
        let mem = Dictionary(uniqueKeysWithValues: state.memory.map { ($0.key, $0.value) })
        var parts: [String] = ["Welcome back, \(state.user.displayName)."]
        // Credit bureau status
        if let bureaus = mem["credit_bureaus_frozen"] {
            parts.append("Credit bureaus: \(bureaus).")
        } else if mem["experian_status"] == "frozen" {
            parts.append("You froze Experian")
            if mem["equifax_status"] == "frozen" { parts.append("and Equifax.") } else { parts.append(".") }
        }
        if let last = mem["last_action"] { parts.append("Last: \(last).") }
        if let task = mem["pending_task"] { parts.append(task + ".") }
        if let next = mem["next_action"], mem["mentioned_letter"] != "true" {
            parts.append("Next step: \(next).")
        }
        if mem["mentioned_letter"] == "true" { parts.append("Want to review another document?") }
        return parts.joined(separator: " ")
    }

    // MARK: - Events

    func startSession(_ newSession: AuthAdapter.Session) {
        AuthAdapter.rememberDemoLogin(newSession)
        session = newSession
        previousSession = nil
        checkingPreviousSession = false
        restoredFromTigerData = false

        if newSession.role == .advocate {
            route = .advocate
        } else if hasCompletedOnboarding(for: newSession.subject) {
            route = .survivor
        } else {
            // Reset onboarding state for this new flow
            onboardingPage = 0
            onboardingSafetyAcked = false
            onboardingDisplayName = newSession.displayName
            onboardingShowDemoLetter = true
            onboardingRememberSession = true
            route = .onboarding
        }

        // A live advocate must never inherit a survivor's local case from the
        // same device. The demo advocate intentionally keeps the current
        // synthetic case so the five-beat presentation remains seamless.
        if newSession.role == .advocate {
            if !newSession.isDemo {
                state = Fixture.fresh()
                restoredFromMemory = false
            }
            return
        }

        // Keep same-owner local state for fast UI, but never show one user's
        // local case while another authenticated survivor is restoring.
        if state.user.id != newSession.subject {
            state = Fixture.fresh()
            restoredFromMemory = false
        }

        state.user.id = newSession.subject
        state.user.displayName = newSession.displayName
        state.user.role = .survivor
        state.caseRecord.userId = newSession.subject

        if let accessToken = newSession.accessToken {
            Task { await restoreFromTigerData(for: newSession.subject, accessToken: accessToken) }
        } else {
            persist()
        }
    }

    private func restoreFromTigerData(for ownerID: String, accessToken: String) async {
        guard TigerDataAdapter.isLive(accessToken: accessToken) else {
            persist()
            return
        }

        do {
            guard let remoteState = try await TigerDataAdapter.loadSnapshot(ownerID: ownerID,
                                                                              accessToken: accessToken)
            else {
                // This is a genuinely new account. Seed it once; a network
                // error must never overwrite an existing remote case.
                persist()
                return
            }

            state = remoteState
            restoredFromMemory = true
            restoredFromTigerData = true
            BackboardAdapter.save(state)
        } catch {
            #if DEBUG
            print("Tiger Data restore failed; preserving local state: \(error)")
            #endif
        }
    }

    func appendEvent(type: String, payload: [String: String]) {
        let event = TimelineEvent(id: UUID().uuidString, caseId: state.caseRecord.id,
                                  type: type, timestamp: Date(), payload: payload)
        state.timeline.append(event)
        TigerDataAdapter.record(event: event, accessToken: remoteAccessToken)
        persist()
    }

    // MARK: - Extraction (Beat 2)

    func runExtraction(image: UIImage?) {
        extracting = true
        pendingFacts = []
        Task {
            let output = await GeminiAdapter.extract(image: image, accessToken: remoteAccessToken)
            let doc = DocumentRecord(id: UUID().uuidString, caseId: state.caseRecord.id,
                                     localAssetName: "maya_collection_letter",
                                     documentType: output.result.documentType,
                                     createdAt: Date(), extractionStatus: .requiresReview)
            state.documents.append(doc)
            pendingFacts = output.result.facts.map { f in
                FinancialFact(id: UUID().uuidString, documentId: doc.id,
                              type: output.result.documentType,
                              counterparty: f.counterparty,
                              accountLast4: f.accountLast4,
                              amount: f.amount, openedDate: f.openedDate,
                              reviewStatus: .unconfirmed)
            }
            extractionIsLive = output.isLive
            extracting = false
            persist()
        }
    }

    // MARK: - Confirmation (Beat 3)

    func confirm(fact: FinancialFact, as status: ReviewStatus) {
        var fact = fact
        fact.reviewStatus = status
        state.facts.append(fact)
        pendingFacts.removeAll { $0.id == fact.id }

        switch status {
        case .mine:
            state.caseRecord.confirmedFactIds.append(fact.id)
            appendEvent(type: "fact_confirmed", payload: ["fact": fact.counterparty])
        case .notMine:
            appendEvent(type: "account_marked_not_mine",
                        payload: ["counterparty": fact.counterparty,
                                  "accountLast4": fact.accountLast4 ?? ""])
            setMemory(key: "unrecognised_account", value: "\(fact.counterparty) ****\(fact.accountLast4 ?? "")")
        case .notSure:
            appendEvent(type: "fact_needs_review", payload: ["fact": fact.counterparty])
        case .unconfirmed:
            break
        }
        persist()
    }

    var unrecognisedFacts: [FinancialFact] { state.facts.filter { $0.reviewStatus == .notMine } }
    var confirmedFacts: [FinancialFact] { state.facts.filter { $0.reviewStatus == .mine } }
    var notSureFacts: [FinancialFact] { state.facts.filter { $0.reviewStatus == .notSure } }

    // MARK: - Sharing + approval (Beat 5)

    func shareSummary() {
        state.summaryShared = true
        state.request.sharedWithAdvocate = true
        state.caseRecord.sharedSummaryIds.append("summary-\(UUID().uuidString.prefix(8))")
        setMemory(key: "sharing_preference", value: "neutral summary shared with advocate")
        appendEvent(type: "summary_shared", payload: ["scope": "neutral_summary"])
    }

    func createRequestIfNeeded() {
        guard state.request.status == .pending else { return }
        appendEvent(type: "assistance_request_created",
                    payload: ["type": state.request.type, "amount": "\(state.request.amount)"])
    }

    /// Demo approval — moves runway 18 → 31.
    func approveRequest() {
        guard state.request.status == .pending else { return }
        state.request.status = .approved
        appendEvent(type: "assistance_request_approved",
                    payload: ["type": state.request.type, "amount": "\(state.request.amount)"])
        recalculateRunway(to: 31, reason: "Transportation support approved (Demo approval)")
        setMemory(key: "last_action", value: "received approved transportation support")
    }

    func recalculateRunway(to days: Int, reason: String) {
        state.caseRecord.runwayDays = days
        state.runwayHistory.append(
            RunwaySnapshot(id: UUID().uuidString, days: days, timestamp: Date(), reason: reason))
        appendEvent(type: "runway_recalculated", payload: ["days": "\(days)", "reason": reason])
    }

    // MARK: - Memory helpers

    func setMemory(key: String, value: String) {
        if let idx = state.memory.firstIndex(where: { $0.key == key }) {
            state.memory[idx].value = value
            state.memory[idx].updatedAt = Date()
        } else {
            state.memory.append(MemoryEntry(id: UUID().uuidString, caseId: state.caseRecord.id,
                                            key: key, value: value, updatedAt: Date()))
        }
        persist()
    }

    // MARK: - Onboarding

    private static let onboardingPrefix = "runway90.onboarding.completed."

    func hasCompletedOnboarding(for subject: String) -> Bool {
        UserDefaults.standard.bool(forKey: Self.onboardingPrefix + subject)
    }

    func completeOnboarding() {
        guard let subject = session?.subject else { return }
        UserDefaults.standard.set(true, forKey: Self.onboardingPrefix + subject)

        // Apply preferences
        if !onboardingDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            state.user.displayName = onboardingDisplayName
        }
        persist()
    }

    func clearOnboarding(for subject: String) {
        UserDefaults.standard.removeObject(forKey: Self.onboardingPrefix + subject)
    }

    // MARK: - Safety

    func logout() {
        let hadLiveSession = session?.isDemo == false
        let hadDemoSession = session?.isDemo == true
        session = nil
        previousSession = nil
        checkingPreviousSession = true
        if hadDemoSession {
            AuthAdapter.clearDemoLogin()
        }
        route = .roleEntry

        if hadLiveSession {
            Task { await AuthAdapter.logoutLive() }
        }
    }

    func quickExit() {
        // Try to open the real Weather app first (looks completely natural on
        // a monitored phone). Fall back to the in-app decoy if the URL scheme
        // is unavailable (e.g. simulator without Weather installed).
        if let weatherURL = URL(string: "weather://"),
           UIApplication.shared.canOpenURL(weatherURL) {
            UIApplication.shared.open(weatherURL)
        } else {
            route = .decoy
        }
    }

    func deleteDemoCase() {
        let subject = state.user.id
        TigerDataAdapter.deleteSnapshot(ownerID: subject, accessToken: remoteAccessToken)
        BackboardAdapter.deleteAll()
        clearOnboarding(for: subject)
        state = Fixture.fresh()
        restoredFromMemory = false
        restoredFromTigerData = false
        session = nil
        previousSession = nil
        checkingPreviousSession = true
        AuthAdapter.clearDemoLogin()
        pendingFacts = []
        route = .disclosure
        BackboardAdapter.save(state)
    }

    // MARK: - Entry screen authentication state

    /// Checks secure Auth0 credentials first, then the local labelled demo
    /// session. This lets a returning user see a resume button without
    /// silently routing into the case before they choose it.
    func checkPreviousSession() async {
        checkingPreviousSession = true
        if let liveSession = await AuthAdapter.restoreSession() {
            previousSession = liveSession
        } else if AuthAdapter.hasPreviousDemoLogin {
            previousSession = AuthAdapter.demoLogin(role: .survivor)
        } else {
            previousSession = nil
        }
        checkingPreviousSession = false
    }

    // MARK: - Persistence

    func persist() {
        BackboardAdapter.save(state, accessToken: remoteAccessToken)
        TigerDataAdapter.saveSnapshot(state, ownerID: state.user.id, accessToken: remoteAccessToken)
    }

    /// Only a live survivor may write a case snapshot. A live advocate gets a
    /// clean scoped view and must not accidentally create a new advocate-owned
    /// case in Tiger Data.
    private var remoteAccessToken: String? {
        guard session?.role == .survivor else { return nil }
        return session?.accessToken
    }
}
