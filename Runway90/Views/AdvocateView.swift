import SwiftUI

/// Beat 5: advocate role — sees ONLY the neutral summary Maya explicitly shared.
/// Shows Auth0 role separation (or labelled demo login) + demo-MFA + demo approval.
struct AdvocateView: View {
    @EnvironmentObject var store: AppStore
    @State private var mfaPassed = false
    @State private var mfaCode = ""

    /// Live Auth0 advocates already passed tenant-side MFA; demo advocates
    /// must pass the labelled demo-MFA sheet.
    private var needsDemoMFA: Bool {
        (store.session?.isDemo ?? true) && !mfaPassed
    }

    var body: some View {
        NavigationStack {
            Group {
                if needsDemoMFA {
                    mfaGate
                } else {
                    advocateContent
                }
            }
            .rwScreen()
            .navigationTitle("Advocate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back to Maya") {
                        store.startSession(AuthAdapter.demoLogin(role: .survivor))
                    }
                    .tint(RW.mist)
                }
                ToolbarItem(placement: .topBarTrailing) { QuickExitButton() }
            }
        }
        .onTapGesture(count: 3) { store.quickExit() }
    }

    // MARK: demo MFA gate

    private var mfaGate: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 44)).foregroundStyle(RW.pink)
            Text("Advocate verification")
                .font(.title3.weight(.bold)).foregroundStyle(RW.cloud)
            Text("Demo MFA — enter any 6 digits. This simulates Auth0 MFA for the advocate role.")
                .font(.caption).foregroundStyle(RW.mist)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            TextField("6-digit code", text: $mfaCode)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
                .frame(width: 180)

            Button {
                if mfaCode.count >= 6 { withAnimation { mfaPassed = true } }
            } label: {
                Text("Verify (Demo MFA)").font(.headline).frame(maxWidth: 220)
            }
            .rwPrimaryButton()
            .disabled(mfaCode.count < 6)
            Spacer()
            SyntheticBanner().padding(.bottom, 12)
        }
    }

    // MARK: advocate content — scoped to the shared summary only

    private var advocateContent: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack {
                    Label((store.session?.isDemo ?? true) ? "Demo login · role: advocate" : "Auth0 · role: advocate",
                          systemImage: "person.badge.shield.checkmark.fill")
                        .font(.caption.weight(.semibold)).foregroundStyle(RW.mist)
                    Spacer()
                }

                if !store.state.summaryShared {
                    VStack(spacing: 12) {
                        Image(systemName: "tray").font(.largeTitle).foregroundStyle(RW.mist)
                        Text("No shared summary yet")
                            .font(.headline).foregroundStyle(RW.cloud)
                        Text("The advocate sees nothing until the survivor explicitly shares a neutral summary.")
                            .font(.caption).foregroundStyle(RW.mist)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .glassCard()
                } else {
                    // Neutral summary — no private notes, no unconfirmed facts,
                    // no document image, no full timeline.
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Neutral summary — shared by Maya", systemImage: "doc.plaintext")
                            .font(.subheadline.weight(.bold)).foregroundStyle(RW.pink)
                        summaryRow("Case day", "\(store.state.caseRecord.dayNumber)")
                        summaryRow("Confirmed facts", "\(store.confirmedFacts.count)")
                        summaryRow("Credit freeze", "Experian frozen")
                        summaryRow("Runway", "\(store.state.caseRecord.runwayDays) days of essentials")
                        summaryRow("Largest gaps", "Transportation, housing deposit")
                        if !store.unrecognisedFacts.isEmpty {
                            summaryRow("Unrecognised accounts", "\(store.unrecognisedFacts.count) requires review")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()

                    // The assistance request + Demo approval
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Assistance request", systemImage: "bus.fill")
                            .font(.subheadline.weight(.bold)).foregroundStyle(RW.mist)
                        summaryRow("Type", store.state.request.type.capitalized)
                        summaryRow("Amount", store.state.request.amount.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                        summaryRow("Status", store.state.request.status == .approved ? "Approved" : "Pending")

                        if store.state.request.status == .pending {
                            Button {
                                withAnimation(.smooth(duration: 0.8)) { store.approveRequest() }
                            } label: {
                                Label("Approve (Demo approval)", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                            }
                            .rwPrimaryButton(RW.pink)
                        } else {
                            Label("Approved — Maya's runway is now \(store.state.caseRecord.runwayDays) days",
                                  systemImage: "checkmark.seal.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RW.pink)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(tint: RW.pink)
                }

                SyntheticBanner()
            }
            .padding()
        }
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.callout).foregroundStyle(RW.mist)
            Spacer()
            Text(value).font(.callout.weight(.medium)).foregroundStyle(RW.cloud)
        }
    }
}
