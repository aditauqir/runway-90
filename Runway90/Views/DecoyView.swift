import SwiftUI

/// Safety decoy screen — no case history, thumbnails, names, amounts, or
/// notification previews. Looks like a bland notes/weather placeholder.
/// A duress-PIN placeholder opens an empty profile; the real path back is
/// the correct demo PIN (0000 for the hackathon demo).
struct DecoyView: View {
    @EnvironmentObject var store: AppStore
    @State private var pin = ""
    @State private var showPin = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "cloud.sun")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("Partly cloudy · 68°")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("You have a reminder")
                .font(.footnote)
                .foregroundStyle(.tertiary)
            Spacer()

            if showPin {
                SecureField("PIN", text: $pin)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 140)
                    .multilineTextAlignment(.center)
                    .onChange(of: pin) { _, value in
                        if value == "0000" {
                            // Correct demo PIN: return to role entry.
                            pin = ""; showPin = false
                            store.route = .roleEntry
                        } else if value.count >= 4 {
                            // Duress placeholder: any other PIN opens an empty profile.
                            pin = ""; showPin = false
                        }
                    }
            }

            Button {
                showPin.toggle()
            } label: {
                Text("Settings").font(.caption).foregroundStyle(.tertiary)
            }
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .preferredColorScheme(.light)
    }
}
