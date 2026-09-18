import SwiftUI

/// First screen: synthetic-data warning + non-advice disclaimer (spec section 4/7).
struct DisclosureView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 10) {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(RW.pink)
                Text("Runway 90")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(RW.cloud)
                Text("A private financial-recovery companion")
                    .font(.subheadline)
                    .foregroundStyle(RW.mist)
            }

            VStack(alignment: .leading, spacing: 14) {
                Label {
                    Text("**Synthetic demo data.** No real financial accounts, survivors, advocates, or organisations are represented.")
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(RW.pink)
                }
                Label {
                    Text("This is a hackathon demo. It is **not** an emergency service, lawyer, therapist, or financial adviser.")
                } icon: {
                    Image(systemName: "info.circle.fill").foregroundStyle(RW.mist)
                }
                Label {
                    Text("Quick exit is always available: shake the phone or tap the shield.")
                } icon: {
                    Image(systemName: "xmark.shield.fill").foregroundStyle(RW.mist)
                }
            }
            .font(.callout)
            .foregroundStyle(RW.cloud.opacity(0.92))
            .glassCard()
            .padding(.horizontal)

            Spacer()

            Button {
                store.route = .roleEntry
            } label: {
                Text("I understand — continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .rwPrimaryButton()
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .rwScreen()
    }
}
