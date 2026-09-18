import SwiftUI

struct SurvivorRootView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        TabView {
            NavigationStack { SurvivorHomeView() }
                .tabItem { Label("Home", systemImage: "house.fill") }
            NavigationStack { ReclaimView() }
                .tabItem { Label("Reclaim", systemImage: "folder.fill.badge.person.crop") }
            NavigationStack { RunwayView() }
                .tabItem { Label("Runway", systemImage: "airplane.departure") }
        }
        .tint(RW.pink)
        .preferredColorScheme(.dark)
        .onTapGesture(count: 3) { store.quickExit() }   // triple-tap quick exit
    }
}

struct SurvivorHomeView: View {
    @EnvironmentObject var store: AppStore
    @State private var showCapture = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {

                // Beat 1 — memory message built from persisted Backboard memory
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Day \(store.state.caseRecord.dayNumber)")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(RW.raspberry, in: Capsule())
                            .foregroundStyle(RW.cloud)
                        Spacer()
                        if store.restoredFromTigerData {
                            Label("Tiger Data restore", systemImage: "cylinder.split.1x2")
                                .font(.caption2)
                                .foregroundStyle(RW.pink.opacity(0.9))
                        } else if store.restoredFromMemory {
                            Label(BackboardAdapter.isLive(for: store.session?.accessToken) ? "Backboard memory" : "Demo memory fallback",
                                  systemImage: "brain.head.profile")
                                .font(.caption2)
                                .foregroundStyle(RW.mist.opacity(0.8))
                        }
                    }
                    Text(store.memoryMessage)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(RW.cloud)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()

                // Runway snapshot
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Runway").font(.caption).foregroundStyle(RW.mist)
                        Text("\(store.state.caseRecord.runwayDays) days")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(RW.cloud)
                            .contentTransition(.numericText())
                        Text("of essential expenses covered")
                            .font(.caption2).foregroundStyle(RW.cloud.opacity(0.7))
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Confirmed facts").font(.caption).foregroundStyle(RW.mist)
                        Text("\(store.confirmedFacts.count)")
                            .font(.title2.weight(.bold)).foregroundStyle(RW.cloud)
                        Text("Experian frozen ✓").font(.caption2).foregroundStyle(RW.mist)
                    }
                }
                .glassCard(tint: RW.pink)

                // Pending task
                VStack(alignment: .leading, spacing: 8) {
                    Label("You have a reminder", systemImage: "bell.badge")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RW.cloud)
                    Text("TransUnion still needs review.")
                        .font(.callout).foregroundStyle(RW.cloud.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()

                // Beat 2 entry point
                Button {
                    showCapture = true
                } label: {
                    Label("Review letter", systemImage: "doc.viewfinder")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .rwPrimaryButton()

                SyntheticBanner()
            }
            .padding()
        }
        .rwScreen()
        .navigationTitle("Runway 90")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    store.logout()
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.title3)
                }
                .foregroundStyle(RW.cloud)
                .accessibilityLabel("Log out")
            }
            ToolbarItem(placement: .topBarTrailing) { QuickExitButton() }
        }
        .sheet(isPresented: $showCapture) {
            CaptureView()
                .environmentObject(store)
        }
    }
}
