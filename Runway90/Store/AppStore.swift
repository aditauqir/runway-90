import SwiftUI
import UIKit

enum Route: Equatable {
    case disclosure
    case roleEntry
    case survivor
    case advocate
    case decoy
}

@MainActor
final class AppStore: ObservableObject {

    @Published var route: Route = .disclosure
    @Published var state: CaseState
    @Published var session: AuthAdapter.Session?

    // Extraction flow
    @Published var extracting = false
    @Published var extractionIsLive = false
    @Published var pendingFacts: [FinancialFact] = []

    // Was the app state restored from persistence? (proves Backboard memory beat)
    @Published var restoredFromMemory: Bool

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
        if mem["experian_status"] == "frozen" { parts.append("You froze Experian") }
        if let last = mem["last_action"] { parts.append("and \(last).") }
        if let task = mem["pending_task"] { parts.append(task.replacingOccurrences(of: "still needs review", with: "is still open") + ".") }
        if mem["mentioned_letter"] == "true" { parts.append("Want to review the letter you mentioned?") }
        return parts.joined(separator: " ")
    }

    // MARK: - Events

    func appendEvent(type: String, payload: [String: String]) {
        let event = TimelineEvent(id: UUID().uuidString, caseId: state.caseRecord.id,
                                  type: type, timestamp: Date(), payload: payload)
        state.timeline.append(event)
        TigerDataAdapter.record(event: event)
        persist()
    }

    // MARK: - Extraction (Beat 2)

    func runExtraction(image: UIImage?) {
        extracting = true
        pendingFacts = []
        Task {
            let output = await GeminiAdapter.extract(image: image)
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

    // MARK: - Safety

    func quickExit() {
        route = .decoy
    }

    func deleteDemoCase() {
        BackboardAdapter.deleteAll()
        state = Fixture.fresh()
        restoredFromMemory = false
        session = nil
        pendingFacts = []
        route = .disclosure
        BackboardAdapter.save(state)
    }

    // MARK: - Persistence

    func persist() {
        BackboardAdapter.save(state)
    }
}
