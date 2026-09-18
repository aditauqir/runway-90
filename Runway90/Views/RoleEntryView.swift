import SwiftUI

/// Login & Role Entry screen with Apple Liquid Glass aesthetic over custom iridescent background.
struct RoleEntryView: View {
    @EnvironmentObject var store: AppStore
    @State private var loginError: String?
    @State private var loggingIn = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // MARK: - Background Image & Subtle Scrim
                backgroundLayer

                // MARK: - Top Bar with Quick Exit
                VStack {
                    HStack {
                        Spacer()
                        QuickExitButton()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, proxy.safeAreaInsets.top > 0 ? 8 : 16)
                    Spacer()
                }

                // MARK: - Apple Flight Icon (exactly 30px above center mid)
                flightIcon
                    .offset(y: -30)

                // MARK: - Bottom Controls
                VStack {
                    Spacer()

                    VStack(spacing: 12) {
                        if let loginError {
                            Text(loginError)
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(RW.raspberry.opacity(0.85), in: Capsule())
                                .multilineTextAlignment(.center)
                        }

                        // Button 1: Log in
                        Button {
                            if AuthAdapter.isLive {
                                Task { await liveLogin() }
                            } else {
                                store.startSession(AuthAdapter.demoLogin(role: .survivor))
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if loggingIn {
                                    ProgressView()
                                        .tint(.white)
                                }
                                Text(loggingIn ? "Signing in…" : "Log in")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(Color.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                        }
                        .liquidGlassButton(tint: RW.raspberry, corner: 26)
                        .disabled(loggingIn)

                        // Button 2: Welcome back <user>
                        Button {
                            store.startSession(AuthAdapter.demoLogin(role: .survivor))
                        } label: {
                            Text("Welcome back, \(store.state.user.displayName)")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Color.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                        }
                        .liquidGlassButton(tint: Color.white.opacity(0.2), corner: 26)

                        // Small Plain Text Link: "I'm a demo advocate"
                        Button {
                            store.startSession(AuthAdapter.demoLogin(role: .advocate))
                        } label: {
                            Text("I’m a demo advocate")
                                .font(.footnote)
                                .foregroundStyle(Color.white.opacity(0.85))
                                .padding(.top, 4)
                                .padding(.bottom, 2)
                        }
                        .buttonStyle(.plain)

                        SyntheticBanner()
                            .padding(.top, 2)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, proxy.safeAreaInsets.bottom > 0 ? 12 : 24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        }
    }

    // MARK: - Subviews

    private var backgroundLayer: some View {
        ZStack {
            if let uiImg = UIImage(named: "login_bg") ?? (Bundle.main.path(forResource: "login_bg", ofType: "jpg").flatMap { UIImage(contentsOfFile: $0) }) {
                Image(uiImage: uiImg)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                RW.gradient
            }

            // Subtle dark-to-translucent scrim to enhance liquid glass refraction and text legibility
            LinearGradient(
                colors: [
                    Color.black.opacity(0.22),
                    Color.black.opacity(0.05),
                    Color.black.opacity(0.48)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    private var flightIcon: some View {
        ZStack {
            Circle()
                .frame(width: 80, height: 80)
                .glassCircle(tint: Color.white.opacity(0.18))

            Image(systemName: "airplane.departure")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.white)
        }
    }

    // MARK: - Actions

    @MainActor
    private func liveLogin() async {
        loggingIn = true
        loginError = nil
        do {
            let session = try await AuthAdapter.loginLive()
            store.startSession(session)
        } catch {
            loginError = "Auth0 login failed: \(error.localizedDescription)"
        }
        loggingIn = false
    }
}
