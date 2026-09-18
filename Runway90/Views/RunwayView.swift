import SwiftUI
import Charts

/// Beat 4: runway, largest gaps, history, and exactly one next action.
struct RunwayView: View {
    @EnvironmentObject var store: AppStore
    @State private var showShareConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {

                // Big runway number
                VStack(spacing: 6) {
                    Text("Essentials covered for")
                        .font(.subheadline).foregroundStyle(RW.mist)
                    Text("\(store.state.caseRecord.runwayDays)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(RW.cloud)
                        .contentTransition(.numericText())
                        .animation(.smooth(duration: 0.8), value: store.state.caseRecord.runwayDays)
                    Text("days")
                        .font(.headline).foregroundStyle(RW.pink)
                    Label(TigerDataAdapter.isLive ? "Tiger Data" : "Demo data source",
                          systemImage: "chart.line.uptrend.xyaxis")
                        .font(.caption2).foregroundStyle(RW.mist.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .glassCard(tint: RW.pink)

                // Runway history (event-backed snapshots)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Runway history")
                        .font(.subheadline.weight(.bold)).foregroundStyle(RW.mist)
                    Chart(store.state.runwayHistory) { snap in
                        LineMark(x: .value("When", snap.timestamp),
                                 y: .value("Days", snap.days))
                            .foregroundStyle(RW.pink)
                            .interpolationMethod(.catmullRom)
                        PointMark(x: .value("When", snap.timestamp),
                                  y: .value("Days", snap.days))
                            .foregroundStyle(RW.cloud)
                    }
                    .frame(height: 140)
                    .chartYScale(domain: 0...40)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()

                // Largest gaps
                VStack(alignment: .leading, spacing: 10) {
                    Text("Largest gaps")
                        .font(.subheadline.weight(.bold)).foregroundStyle(RW.mist)
                    gapRow("Transportation", icon: "bus.fill")
                    gapRow("Housing deposit", icon: "house.lodge.fill")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()

                // Exactly ONE next action
                VStack(alignment: .leading, spacing: 12) {
                    Label("One next action", systemImage: "arrow.forward.circle.fill")
                        .font(.subheadline.weight(.bold)).foregroundStyle(RW.pink)

                    Text("Request transportation support")
                        .font(.title3.weight(.semibold)).foregroundStyle(RW.cloud)
                    Text("Transportation support protects the next work and appointment days.")
                        .font(.callout).foregroundStyle(RW.cloud.opacity(0.8))

                    HStack {
                        Text("$250 · \(store.state.request.status == .approved ? "Approved" : "Pending")")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background((store.state.request.status == .approved ? RW.pink : RW.mist).opacity(0.25),
                                        in: Capsule())
                            .foregroundStyle(RW.cloud)
                        Spacer()
                    }

                    if store.state.request.status == .pending {
                        Button {
                            store.createRequestIfNeeded()
                            store.shareSummary()
                            showShareConfirm = true
                        } label: {
                            Label(store.state.summaryShared ? "Summary shared ✓" : "Share neutral summary",
                                  systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                        .rwPrimaryButton()
                    } else {
                        Label("Approved — runway extended to \(store.state.caseRecord.runwayDays) days",
                              systemImage: "checkmark.seal.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RW.pink)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(tint: RW.raspberry)

                SyntheticBanner()
            }
            .padding()
        }
        .rwScreen()
        .navigationTitle("Runway")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { QuickExitButton() } }
        .alert("Neutral summary shared", isPresented: $showShareConfirm) {
            Button("Switch to advocate view") { store.route = .advocate; store.session = AuthAdapter.demoLogin(role: .advocate) }
            Button("Stay here", role: .cancel) {}
        } message: {
            Text("Only the summary you chose to share is visible to the advocate. Private notes, unconfirmed facts, and documents stay with you.")
        }
    }

    private func gapRow(_ name: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(RW.pink)
            Text(name).font(.callout).foregroundStyle(RW.cloud)
            Spacer()
        }
    }
}
