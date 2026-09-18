import SwiftUI

/// Demo role entry — Maya (survivor) or Demo Advocate.
/// Uses Auth0 when configured, otherwise a clearly labelled local demo login.
struct RoleEntryView: View {
    @EnvironmentObject var store: AppStore
    @State private var loginError: String?
    @State private var loggingIn = false

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                QuickExitButton()
            }
            .padding(.horizontal)

            Spacer()

            Text("Who is presenting?")
                .font(.title2.weight(.bold))
                .foregroundStyle(RW.cloud)

            if !AuthAdapter.isLive {
                Text("Demo login — Auth0 not configured. This is a local role switch, not production authentication.")
                    .font(.caption)
                    .foregroundStyle(RW.mist)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 16) {
                if AuthAdapter.isLive {
                    Button {
                        Task { await liveLogin() }
                    } label: {
                        roleRow(icon: "key.horizontal.fill",
                                title: loggingIn ? "Signing in…" : "Log in with Auth0",
                                subtitle: "Universal Login · role from your account")
                    }
                    .rwPrimaryButton()
                    .disabled(loggingIn)

                    if let loginError {
                        Text(loginError)
                            .font(.caption)
                            .foregroundStyle(RW.pink)
                            .multilineTextAlignment(.center)
                    }

                    Text("Or use the local demo roles (labelled Demo login):")
                        .font(.caption2)
                        .foregroundStyle(RW.mist.opacity(0.8))
                }
                Button {
                    store.session = AuthAdapter.demoLogin(role: .survivor)
                    store.route = .survivor
                } label: {
                    roleRow(icon: "person.fill", title: "Maya", subtitle: "Survivor · case day 6")
                }
                .rwPrimaryButton()

                Button {
                    store.session = AuthAdapter.demoLogin(role: .advocate)
                    store.route = .advocate
                } label: {
                    roleRow(icon: "person.badge.shield.checkmark.fill",
                            title: "Demo Advocate", subtitle: "Sees only what Maya shares")
                }
                .rwPrimaryButton(RW.pink)
            }
            .padding(.horizontal, 24)

            Spacer()
            SyntheticBanner()
                .padding(.bottom, 16)
        }
        .rwScreen()
    }

    @MainActor
    private func liveLogin() async {
        loggingIn = true
        loginError = nil
        do {
            let session = try await AuthAdapter.loginLive()
            store.session = session
            store.route = session.role == .advocate ? .advocate : .survivor
        } catch {
            loginError = "Auth0 login failed: \(error.localizedDescription)"
        }
        loggingIn = false
    }

    private func roleRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).opacity(0.85)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.footnote)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }
}
