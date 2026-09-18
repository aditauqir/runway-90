import Foundation

// MARK: - Core model (mirrors the spec packet, section 5)

enum Role: String, Codable { case survivor, advocate }

enum ReviewStatus: String, Codable, CaseIterable {
    case mine, notMine = "not_mine", notSure = "not_sure", unconfirmed
    var label: String {
        switch self {
        case .mine: return "Mine"
        case .notMine: return "Not mine"
        case .notSure: return "Not sure"
        case .unconfirmed: return "Unconfirmed"
        }
    }
}

struct User: Codable {
    var id: String
    var displayName: String
    var role: Role
    var safetyModeEnabled: Bool = true
}

struct CaseRecord: Codable {
    var id: String
    var userId: String
    var dayNumber: Int
    var runwayDays: Int
    var confirmedFactIds: [String]
    var sharedSummaryIds: [String]
    var pendingTaskId: String?
}

enum ExtractionStatus: String, Codable {
    case notStarted = "not_started", extracting, done, requiresReview = "requires_review"
}

struct DocumentRecord: Codable, Identifiable {
    var id: String
    var caseId: String
    var localAssetName: String
    var documentType: String
    var createdAt: Date
    var extractionStatus: ExtractionStatus
}

struct FinancialFact: Codable, Identifiable {
    var id: String
    var documentId: String?
    var type: String
    var counterparty: String
    var accountLast4: String?
    var amount: Double?
    var openedDate: String?
    var reviewStatus: ReviewStatus
}

struct TimelineEvent: Codable, Identifiable {
    var id: String
    var caseId: String
    var type: String
    var timestamp: Date
    var payload: [String: String]
}

enum RequestStatus: String, Codable { case pending, approved }

struct AssistanceRequest: Codable, Identifiable {
    var id: String
    var caseId: String
    var type: String
    var amount: Double
    var status: RequestStatus
    var sharedWithAdvocate: Bool
}

struct MemoryEntry: Codable, Identifiable {
    var id: String
    var caseId: String
    var key: String
    var value: String
    var updatedAt: Date
}

struct RunwaySnapshot: Codable, Identifiable {
    var id: String
    var days: Int
    var timestamp: Date
    var reason: String
}

// MARK: - Whole persisted app state (Backboard-fallback local store shape)

struct CaseState: Codable {
    var user: User
    var caseRecord: CaseRecord
    var documents: [DocumentRecord]
    var facts: [FinancialFact]
    var timeline: [TimelineEvent]
    var request: AssistanceRequest
    var memory: [MemoryEntry]
    var runwayHistory: [RunwaySnapshot]
    var summaryShared: Bool
}

// MARK: - Fixture (Maya, spec section 2)

enum Fixture {
    static func fresh() -> CaseState {
        let now = Date()
        let caseId = "case-maya-001"
        let confirmed: [FinancialFact] = [
            FinancialFact(id: "fact-rent", documentId: nil, type: "expense",
                          counterparty: "Peachtree Flats (rent)", accountLast4: nil,
                          amount: 1150, openedDate: nil, reviewStatus: .mine),
            FinancialFact(id: "fact-paycheck", documentId: nil, type: "income",
                          counterparty: "Paycheck — Midtown Clinic", accountLast4: nil,
                          amount: 1480, openedDate: nil, reviewStatus: .mine),
            FinancialFact(id: "fact-experian-freeze", documentId: nil, type: "credit_action",
                          counterparty: "Experian credit freeze", accountLast4: nil,
                          amount: nil, openedDate: nil, reviewStatus: .mine),
        ]
        return CaseState(
            user: User(id: "maya-demo", displayName: "Maya", role: .survivor),
            caseRecord: CaseRecord(id: caseId, userId: "maya-demo", dayNumber: 6,
                                   runwayDays: 18,
                                   confirmedFactIds: confirmed.map(\.id),
                                   sharedSummaryIds: [],
                                   pendingTaskId: "task-transunion"),
            documents: [],
            facts: confirmed,
            timeline: [
                TimelineEvent(id: "evt-freeze", caseId: caseId, type: "fact_confirmed",
                              timestamp: now.addingTimeInterval(-86400),
                              payload: ["fact": "Experian credit freeze"]),
                TimelineEvent(id: "evt-rent", caseId: caseId, type: "fact_confirmed",
                              timestamp: now.addingTimeInterval(-172800),
                              payload: ["fact": "Rent confirmed"]),
            ],
            request: AssistanceRequest(id: "request-transport-001", caseId: caseId,
                                       type: "transportation support", amount: 250,
                                       status: .pending, sharedWithAdvocate: false),
            memory: [
                MemoryEntry(id: "mem-1", caseId: caseId, key: "experian_status", value: "frozen", updatedAt: now),
                MemoryEntry(id: "mem-2", caseId: caseId, key: "last_action", value: "confirmed two accounts", updatedAt: now),
                MemoryEntry(id: "mem-3", caseId: caseId, key: "pending_task", value: "TransUnion still needs review", updatedAt: now),
                MemoryEntry(id: "mem-4", caseId: caseId, key: "mentioned_letter", value: "true", updatedAt: now),
                MemoryEntry(id: "mem-5", caseId: caseId, key: "next_action", value: "request transportation support", updatedAt: now),
            ],
            runwayHistory: [
                RunwaySnapshot(id: "snap-0", days: 14, timestamp: now.addingTimeInterval(-3 * 86400), reason: "Initial estimate"),
                RunwaySnapshot(id: "snap-1", days: 18, timestamp: now.addingTimeInterval(-86400), reason: "Paycheck confirmed"),
            ],
            summaryShared: false
        )
    }

    /// Gemini fallback extraction — same JSON shape the live API is asked for.
    static let extractionFixture = ExtractionResult(
        documentType: "collection_letter",
        facts: [
            ExtractedFact(counterparty: "Northstar Collections",
                          accountLast4: "4471",
                          amount: 2310,
                          openedDate: "2024-03",
                          reviewStatus: "unconfirmed")
        ]
    )
}

// MARK: - Gemini extraction contract (spec section 6)

struct ExtractionResult: Codable {
    var documentType: String
    var facts: [ExtractedFact]
}

struct ExtractedFact: Codable {
    var counterparty: String
    var accountLast4: String?
    var amount: Double?
    var openedDate: String?
    var reviewStatus: String
}
