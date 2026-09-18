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
        let caseId = "case-isabel-001"
        let confirmed: [FinancialFact] = [
            FinancialFact(id: "fact-rent", documentId: nil, type: "expense",
                          counterparty: "Magnolia Creek Apartments (rent)", accountLast4: nil,
                          amount: 1350, openedDate: nil, reviewStatus: .mine),
            FinancialFact(id: "fact-paycheck", documentId: nil, type: "income",
                          counterparty: "Paycheck — Grady Health System", accountLast4: nil,
                          amount: 1680, openedDate: nil, reviewStatus: .mine),
            FinancialFact(id: "fact-experian-freeze", documentId: nil, type: "credit_action",
                          counterparty: "Experian credit freeze", accountLast4: nil,
                          amount: nil, openedDate: nil, reviewStatus: .mine),
            FinancialFact(id: "fact-auto-insurance", documentId: nil, type: "expense",
                          counterparty: "State Farm auto insurance", accountLast4: nil,
                          amount: 142, openedDate: nil, reviewStatus: .mine),
            FinancialFact(id: "fact-checking-8802", documentId: "doc-002", type: "account",
                          counterparty: "Peachtree Federal CU checking", accountLast4: "8802",
                          amount: 549.66, openedDate: nil, reviewStatus: .mine),
            FinancialFact(id: "fact-equifax-freeze", documentId: nil, type: "credit_action",
                          counterparty: "Equifax credit freeze", accountLast4: nil,
                          amount: nil, openedDate: nil, reviewStatus: .mine),
            FinancialFact(id: "fact-georgia-power", documentId: nil, type: "expense",
                          counterparty: "Georgia Power — utilities", accountLast4: nil,
                          amount: 89, openedDate: nil, reviewStatus: .mine),
            FinancialFact(id: "fact-metro-pcs", documentId: nil, type: "expense",
                          counterparty: "Metro PCS phone plan", accountLast4: nil,
                          amount: 55, openedDate: nil, reviewStatus: .mine),
            FinancialFact(id: "fact-transunion-dispute", documentId: "doc-003", type: "credit_action",
                          counterparty: "TransUnion dispute filed — 2 accounts", accountLast4: nil,
                          amount: nil, openedDate: nil, reviewStatus: .mine),
            FinancialFact(id: "fact-grocery", documentId: nil, type: "expense",
                          counterparty: "Kroger grocery budget", accountLast4: nil,
                          amount: 220, openedDate: nil, reviewStatus: .mine),
        ]
        let unrecognised: [FinancialFact] = [
            FinancialFact(id: "fact-northstar", documentId: "doc-001", type: "collection_letter",
                          counterparty: "Northstar Collections", accountLast4: "4471",
                          amount: 2310, openedDate: "2024-03", reviewStatus: .notMine),
            FinancialFact(id: "fact-unknown-payment", documentId: "doc-002", type: "bank_statement",
                          counterparty: "Unknown online payment", accountLast4: "8802",
                          amount: 412, openedDate: nil, reviewStatus: .notMine),
        ]
        let unsure: [FinancialFact] = [
            FinancialFact(id: "fact-creditline-plus", documentId: "doc-003", type: "credit_account",
                          counterparty: "Creditline Plus", accountLast4: "5509",
                          amount: 875, openedDate: "2024-01", reviewStatus: .notSure),
        ]
        let allFacts = confirmed + unrecognised + unsure
        return CaseState(
            user: User(id: "demo-isabel-001", displayName: "Isabel", role: .survivor),
            caseRecord: CaseRecord(id: caseId, userId: "demo-isabel-001", dayNumber: 12,
                                   runwayDays: 28,
                                   confirmedFactIds: confirmed.map(\.id),
                                   sharedSummaryIds: ["summary-advocate-001"],
                                   pendingTaskId: "task-transunion-followup"),
            documents: [
                DocumentRecord(id: "doc-001", caseId: caseId, localAssetName: "northstar_collection_letter",
                               documentType: "collection_letter", createdAt: now.addingTimeInterval(-9 * 86400),
                               extractionStatus: .requiresReview),
                DocumentRecord(id: "doc-002", caseId: caseId, localAssetName: "peachtree_bank_statement",
                               documentType: "bank_statement", createdAt: now.addingTimeInterval(-8 * 86400),
                               extractionStatus: .done),
                DocumentRecord(id: "doc-003", caseId: caseId, localAssetName: "transunion_credit_notice",
                               documentType: "credit_bureau_notice", createdAt: now.addingTimeInterval(-4 * 86400),
                               extractionStatus: .done),
            ],
            facts: allFacts,
            timeline: [
                TimelineEvent(id: "evt-i-001", caseId: caseId, type: "case_created",
                              timestamp: now.addingTimeInterval(-12 * 86400), payload: ["source": "onboarding"]),
                TimelineEvent(id: "evt-i-002", caseId: caseId, type: "fact_confirmed",
                              timestamp: now.addingTimeInterval(-12 * 86400), payload: ["fact": "Rent confirmed"]),
                TimelineEvent(id: "evt-i-003", caseId: caseId, type: "fact_confirmed",
                              timestamp: now.addingTimeInterval(-12 * 86400), payload: ["fact": "Paycheck confirmed"]),
                TimelineEvent(id: "evt-i-005", caseId: caseId, type: "fact_confirmed",
                              timestamp: now.addingTimeInterval(-11 * 86400), payload: ["fact": "Experian credit freeze"]),
                TimelineEvent(id: "evt-i-006", caseId: caseId, type: "fact_confirmed",
                              timestamp: now.addingTimeInterval(-11 * 86400), payload: ["fact": "Auto insurance confirmed"]),
                TimelineEvent(id: "evt-i-009", caseId: caseId, type: "account_marked_not_mine",
                              timestamp: now.addingTimeInterval(-9 * 86400),
                              payload: ["counterparty": "Northstar Collections", "accountLast4": "4471"]),
                TimelineEvent(id: "evt-i-013", caseId: caseId, type: "account_marked_not_mine",
                              timestamp: now.addingTimeInterval(-8 * 86400),
                              payload: ["counterparty": "Unknown online payment", "accountLast4": "8802"]),
                TimelineEvent(id: "evt-i-014", caseId: caseId, type: "fact_confirmed",
                              timestamp: now.addingTimeInterval(-6 * 86400), payload: ["fact": "Equifax credit freeze"]),
                TimelineEvent(id: "evt-i-015", caseId: caseId, type: "fact_confirmed",
                              timestamp: now.addingTimeInterval(-6 * 86400), payload: ["fact": "Georgia Power utilities"]),
                TimelineEvent(id: "evt-i-019", caseId: caseId, type: "fact_confirmed",
                              timestamp: now.addingTimeInterval(-4 * 86400), payload: ["fact": "TransUnion dispute filed"]),
                TimelineEvent(id: "evt-i-021", caseId: caseId, type: "summary_shared",
                              timestamp: now.addingTimeInterval(-3 * 86400), payload: ["scope": "neutral_summary"]),
                TimelineEvent(id: "evt-i-023", caseId: caseId, type: "assistance_request_approved",
                              timestamp: now.addingTimeInterval(-2 * 86400),
                              payload: ["type": "transportation support", "amount": "250"]),
                TimelineEvent(id: "evt-i-026", caseId: caseId, type: "fact_confirmed",
                              timestamp: now.addingTimeInterval(-86400), payload: ["fact": "Grocery budget confirmed"]),
            ],
            request: AssistanceRequest(id: "request-housing-001", caseId: caseId,
                                       type: "housing deposit assistance", amount: 675,
                                       status: .pending, sharedWithAdvocate: true),
            memory: [
                MemoryEntry(id: "mem-i-1", caseId: caseId, key: "experian_status", value: "frozen", updatedAt: now.addingTimeInterval(-11 * 86400)),
                MemoryEntry(id: "mem-i-2", caseId: caseId, key: "equifax_status", value: "frozen", updatedAt: now.addingTimeInterval(-6 * 86400)),
                MemoryEntry(id: "mem-i-3", caseId: caseId, key: "last_action", value: "confirmed grocery budget and filed TransUnion dispute", updatedAt: now.addingTimeInterval(-86400)),
                MemoryEntry(id: "mem-i-4", caseId: caseId, key: "pending_task", value: "TransUnion dispute follow-up — results expected within 30 days", updatedAt: now.addingTimeInterval(-4 * 86400)),
                MemoryEntry(id: "mem-i-5", caseId: caseId, key: "mentioned_letter", value: "true", updatedAt: now.addingTimeInterval(-9 * 86400)),
                MemoryEntry(id: "mem-i-6", caseId: caseId, key: "next_action", value: "request housing deposit assistance", updatedAt: now.addingTimeInterval(-86400)),
                MemoryEntry(id: "mem-i-7", caseId: caseId, key: "unrecognised_account", value: "Northstar Collections ****4471 ($2,310) + Unknown payment ****8802 ($412)", updatedAt: now.addingTimeInterval(-8 * 86400)),
                MemoryEntry(id: "mem-i-8", caseId: caseId, key: "sharing_preference", value: "neutral summary shared with advocate", updatedAt: now.addingTimeInterval(-3 * 86400)),
                MemoryEntry(id: "mem-i-9", caseId: caseId, key: "credit_bureaus_frozen", value: "Experian, Equifax (TransUnion dispute pending)", updatedAt: now.addingTimeInterval(-4 * 86400)),
                MemoryEntry(id: "mem-i-10", caseId: caseId, key: "approved_support", value: "transportation support ($250) approved", updatedAt: now.addingTimeInterval(-2 * 86400)),
            ],
            runwayHistory: [
                RunwaySnapshot(id: "snap-i-0", days: 12, timestamp: now.addingTimeInterval(-12 * 86400), reason: "Initial estimate"),
                RunwaySnapshot(id: "snap-i-1", days: 14, timestamp: now.addingTimeInterval(-11 * 86400), reason: "Auto insurance confirmed"),
                RunwaySnapshot(id: "snap-i-2", days: 14, timestamp: now.addingTimeInterval(-9 * 86400), reason: "Unrecognised debt excluded"),
                RunwaySnapshot(id: "snap-i-3", days: 16, timestamp: now.addingTimeInterval(-6 * 86400), reason: "Utilities and phone confirmed"),
                RunwaySnapshot(id: "snap-i-4", days: 18, timestamp: now.addingTimeInterval(-3 * 86400), reason: "All essential costs confirmed"),
                RunwaySnapshot(id: "snap-i-5", days: 31, timestamp: now.addingTimeInterval(-2 * 86400), reason: "Transportation support approved"),
                RunwaySnapshot(id: "snap-i-6", days: 28, timestamp: now.addingTimeInterval(-86400), reason: "Grocery budget confirmed"),
            ],
            summaryShared: true
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
