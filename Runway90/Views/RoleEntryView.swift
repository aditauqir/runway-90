import SwiftUI

private enum DemoAuthMode {
    case login
    case createAccount
}

/// Entry screen for the live Auth0 path and the labelled local demo path.
struct RoleEntryView: View {
    @EnvironmentObject var store: AppStore
    @State private var loginError: String?
    @State private var loggingIn = false
    @State private var showingDemoAuth = false
    @State private var demoAuthMode: DemoAuthMode = .login

    var body: some View {
        ZStack {
            loginBackground

            VStack(spacing: 0) {
                // Centered plain-text safety control. It intentionally has no
                // icon, capsule, material, or border competing with the UI.
                Button("Exit") {
                    store.quickExit()
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.92))
                .buttonStyle(.plain)
                .padding(.top, 12)

                Spacer()

                flightBadge

                Spacer()

                bottomControls
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea(edges: .bottom)
        .task {
            await store.checkPreviousSession()
        }
        .sheet(isPresented: $showingDemoAuth) {
            DemoAuthSheet(mode: demoAuthMode) { session in
                showingDemoAuth = false
                store.startSession(session)
            }
        }
    }

    private var bottomControls: some View {
        VStack(spacing: 12) {
            if let loginError {
                Text(loginError)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(RW.raspberry.opacity(0.9), in: Capsule())
            }

            if store.checkingPreviousSession {
                ProgressView()
                    .tint(.white)
                    .frame(height: 54)
            } else if let previousSession = store.previousSession {
                AuthEntryButton(title: "Welcome back, \(previousSession.displayName)", prominent: true) {
                    store.startSession(previousSession)
                }

                AuthEntryButton(title: "Log in with Auth0", prominent: false) {
                    beginLogin()
                }
            } else {
                AuthEntryButton(title: "Log in", prominent: true) {
                    beginLogin()
                }
            }

            AuthEntryButton(
                title: "Create account",
                prominent: false
            ) {
                beginCreateAccount()
            }

            Button {
                store.startSession(AuthAdapter.demoLogin(role: .advocate))
            } label: {
                Text("I’m a demo advocate")
                    .font(.footnote)
                    .foregroundStyle(Color.white.opacity(0.86))
            }
            .buttonStyle(.plain)

            Text(AuthAdapter.hasLiveAPIConfiguration ? "Auth0 Universal Login" : "Demo Auth0 · Maya account")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.74))
                .padding(.top, 2)

            Text("Contents produced are for demo only.")
                .font(.caption2)
                .foregroundStyle(Color.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    private var loginBackground: some View {
        GeometryReader { geo in
            ZStack {
                if let uiImage = UIImage(named: "login_bg")
                    ?? Bundle.main.path(forResource: "login_bg", ofType: "png")
                        .flatMap({ UIImage(contentsOfFile: $0) }) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    RW.gradient
                }

                LinearGradient(
                    stops: [
                        .init(color: Color.black.opacity(0.22), location: 0.0),
                        .init(color: Color.black.opacity(0.02), location: 0.42),
                        .init(color: Color.black.opacity(0.12), location: 0.68),
                        .init(color: Color.black.opacity(0.48), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .ignoresSafeArea()
    }

    private var flightBadge: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 84, height: 84)
                .overlay(Circle().fill(Color.white.opacity(0.1)))
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
                .foregroundStyle(.white)
        }
    }

    private func beginLogin() {
        loginError = nil
        if AuthAdapter.hasLiveAPIConfiguration {
            Task { await liveLogin(createAccount: false) }
        } else {
            demoAuthMode = .login
            showingDemoAuth = true
        }
    }

    private func beginCreateAccount() {
        loginError = nil
        if AuthAdapter.hasLiveAPIConfiguration {
            Task { await liveLogin(createAccount: true) }
        } else {
            demoAuthMode = .createAccount
            showingDemoAuth = true
        }
    }

    @MainActor
    private func liveLogin(createAccount: Bool) async {
        loggingIn = true
        defer { loggingIn = false }
        do {
            let session = try await AuthAdapter.loginLive(createAccount: createAccount)
            store.startSession(session)
        } catch {
            loginError = "Auth0 login failed: \(error.localizedDescription)"
        }
    }
}

private struct AuthEntryButton: View {
    let title: String
    let prominent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .fill((prominent ? RW.raspberry : Color.white)
                                    .opacity(prominent ? 0.74 : 0.16))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.64), Color.white.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .shadow(color: (prominent ? RW.raspberry : Color.black).opacity(0.28), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}

private struct DemoAuthSheet: View {
    @Environment(\.dismiss) private var dismiss
    let mode: DemoAuthMode
    let onComplete: (AuthAdapter.Session) -> Void

    @State private var displayName: String
    @State private var email: String
    @State private var password = "runway90-demo"

    init(mode: DemoAuthMode, onComplete: @escaping (AuthAdapter.Session) -> Void) {
        self.mode = mode
        self.onComplete = onComplete
        _displayName = State(initialValue: "Maya")
        _email = State(initialValue: "maya.demo@runway90.invalid")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: mode == .login ? "person.crop.circle.badge.checkmark" : "person.badge.plus")
                    .font(.system(size: 44))
                    .foregroundStyle(RW.pink)

                Text(mode == .login ? "Demo Auth0 login" : "Create a demo account")
                    .font(.title2.weight(.bold))

                Text(mode == .login
                     ? "This local demo uses a fictional Maya account. No password is stored or sent anywhere."
                     : "This creates a fictional local account so the next launch can show the new name as a returning user.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                if mode == .createAccount {
                    TextField("Name", text: $displayName)
                        .textContentType(.name)
                }

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)

                SecureField("Demo password", text: $password)
                    .textContentType(.password)

                Button {
                    if mode == .createAccount {
                        onComplete(AuthAdapter.demoCreateAccount(displayName: displayName, email: email))
                    } else {
                        onComplete(AuthAdapter.demoLogin(role: .survivor))
                    }
                } label: {
                    Text(mode == .login ? "Continue as Maya" : "Create account")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .rwPrimaryButton()

                Text("Contents produced are for demo only.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .navigationTitle("Runway 90")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
