import SwiftUI

/// Reclaim workspace: confirmed facts, unrecognised accounts, documents, timeline.
struct ReclaimView: View {
    @EnvironmentObject var store: AppStore
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {

                section("Confirmed facts", icon: "checkmark.seal.fill", tint: RW.mist) {
                    if store.confirmedFacts.isEmpty {
                        emptyRow("No confirmed facts yet.")
                    }
                    ForEach(store.confirmedFacts) { fact in
                        factRow(fact, badge: "Mine", badgeColor: RW.mist)
                    }
                }

                section("Unrecognised accounts", icon: "questionmark.folder.fill", tint: RW.raspberry) {
                    if store.unrecognisedFacts.isEmpty {
                        emptyRow("Nothing marked ‘Not mine’ yet.")
                    }
                    ForEach(store.unrecognisedFacts) { fact in
                        factRow(fact, badge: "Requires review", badgeColor: RW.raspberry)
                    }
                    ForEach(store.notSureFacts) { fact in
                        factRow(fact, badge: "Not sure", badgeColor: RW.pink)
                    }
                }

                section("Documents", icon: "doc.fill", tint: RW.pink) {
                    if store.state.documents.isEmpty {
                        emptyRow("No documents captured yet.")
                    }
                    ForEach(store.state.documents) { doc in
                        HStack {
                            Image(systemName: "doc.text.image")
                            VStack(alignment: .leading) {
                                Text(doc.documentType.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(.subheadline).foregroundStyle(RW.cloud)
                                Text(doc.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2).foregroundStyle(RW.mist)
                            }
                            Spacer()
                        }
                    }
                }

                section("Case timeline", icon: "clock.fill", tint: RW.mist) {
                    ForEach(store.state.timeline.sorted { $0.timestamp > $1.timestamp }) { event in
                        HStack(alignment: .top, spacing: 10) {
                            Circle().fill(color(for: event.type)).frame(width: 8, height: 8)
                                .padding(.top, 5)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title(for: event))
                                    .font(.subheadline).foregroundStyle(RW.cloud)
                                Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2).foregroundStyle(RW.mist)
                            }
                            Spacer()
                        }
                    }
                }

                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Label("Delete demo case", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .rwPrimaryButton(RW.raspberry)

                SyntheticBanner()
            }
            .padding()
        }
        .rwScreen()
        .navigationTitle("Reclaim")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { QuickExitButton() } }
        .confirmationDialog("Delete all demo case data?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete everything", role: .destructive) { store.deleteDemoCase() }
        }
    }

    // MARK: helpers

    private func section<Content: View>(_ title: String, icon: String, tint: Color,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint == RW.raspberry ? RW.pink : tint)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(tint: tint)
    }

    private func factRow(_ fact: FinancialFact, badge: String, badgeColor: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(fact.counterparty).font(.subheadline).foregroundStyle(RW.cloud)
                HStack(spacing: 8) {
                    if let amount = fact.amount {
                        Text(amount.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                    }
                    if let last4 = fact.accountLast4 { Text("····\(last4)") }
                }
                .font(.caption).foregroundStyle(RW.mist)
            }
            Spacer()
            Text(badge)
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(badgeColor.opacity(0.25), in: Capsule())
                .foregroundStyle(RW.cloud)
        }
    }

    private func emptyRow(_ text: String) -> some View {
        Text(text).font(.caption).foregroundStyle(RW.mist)
    }

    private func title(for event: TimelineEvent) -> String {
        switch event.type {
        case "fact_confirmed": return "Confirmed: \(event.payload["fact"] ?? "fact")"
        case "account_marked_not_mine":
            return "Marked not mine: \(event.payload["counterparty"] ?? "account") ····\(event.payload["accountLast4"] ?? "")"
        case "fact_needs_review": return "Needs review: \(event.payload["fact"] ?? "fact")"
        case "assistance_request_created": return "Requested \(event.payload["type"] ?? "support")"
        case "assistance_request_approved": return "Approved: \(event.payload["type"] ?? "support") (Demo approval)"
        case "runway_recalculated": return "Runway updated to \(event.payload["days"] ?? "?") days"
        case "summary_shared": return "Neutral summary shared with advocate"
        default: return event.type.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func color(for type: String) -> Color {
        switch type {
        case "account_marked_not_mine": return RW.raspberry
        case "assistance_request_approved", "runway_recalculated": return RW.pink
        default: return RW.mist
        }
    }
}
