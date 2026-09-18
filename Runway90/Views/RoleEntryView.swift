import SwiftUI

/// Login & Role Entry screen with Apple Liquid Glass aesthetic.
struct RoleEntryView: View {
    @EnvironmentObject var store: AppStore
    @State private var loginError: String?
    @State private var loggingIn = false

    var body: some View {
        ZStack {
            // MARK: - Center Flight Icon (exactly 30px above center mid)
            VStack {
                Spacer()
                flightBadge
                    .offset(y: -30)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // MARK: - Top & Bottom Overlay Controls
            VStack(spacing: 0) {
                // Top safety exit
                HStack {
                    Spacer()
                    QuickExitButton()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                // Bottom Controls
                VStack(spacing: 12) {
                    if let loginError {
                        Text(loginError)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(RW.raspberry.opacity(0.9), in: Capsule())
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
                        .frame(height: 54)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule()
                                        .fill(RW.raspberry.opacity(0.7))
                                )
                                .overlay(
                                    Capsule()
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.65), Color.white.opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(color: RW.raspberry.opacity(0.35), radius: 12, y: 6)
                    }
                    .buttonStyle(.plain)
                    .disabled(loggingIn)

                    // Button 2: Welcome back <user>
                    Button {
                        store.startSession(AuthAdapter.demoLogin(role: .survivor))
                    } label: {
                        Text("Welcome back, \(store.state.user.displayName)")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Capsule()
                                            .fill(Color.white.opacity(0.15))
                                    )
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.55), Color.white.opacity(0.18)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.18), radius: 12, y: 6)
                    }
                    .buttonStyle(.plain)

                    // Small Plain Text Link: "I'm a demo advocate"
                    Button {
                        store.startSession(AuthAdapter.demoLogin(role: .advocate))
                    } label: {
                        Text("I’m a demo advocate")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .padding(.top, 4)
                            .padding(.bottom, 2)
                    }
                    .buttonStyle(.plain)

                    SyntheticBanner()
                        .padding(.top, 2)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            GeometryReader { geo in
                ZStack {
                    if let uiImg = UIImage(named: "login_bg") ?? (Bundle.main.path(forResource: "login_bg", ofType: "jpg").flatMap { UIImage(contentsOfFile: $0) }) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    } else {
                        RW.gradient
                    }

                    // Ambient contrast scrim
                    LinearGradient(
                        stops: [
                            .init(color: Color.black.opacity(0.25), location: 0.0),
                            .init(color: Color.black.opacity(0.04), location: 0.35),
                            .init(color: Color.black.opacity(0.18), location: 0.65),
                            .init(color: Color.black.opacity(0.55), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .ignoresSafeArea()
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Flight Icon Badge

    private var flightBadge: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 84, height: 84)
                .overlay(
                    Circle()
                        .fill(Color.white.opacity(0.1))
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.7), Color.white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.black.opacity(0.22), radius: 20, y: 8)

            Image(systemName: "airplane.departure")
                .font(.system(size: 38, weight: .semibold))
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
