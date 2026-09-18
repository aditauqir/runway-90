import Foundation
import Auth0

/// Auth0 adapter — role separation and scoped sharing (spec section 6).
/// Live path (wired 2026-09-18): Auth0 Universal Login via Auth0.swift.
///   - Tenant config lives in Resources/Auth0.plist (read by the SDK).
///   - Roles come from the custom ID-token claim `https://runway90.app/roles`
///     (set by a post-login Action on the tenant). No claim -> survivor.
///   - MFA for advocates is enforced tenant-side (Auth0 Action / MFA policy),
///     so a live advocate session skips the in-app demo-MFA sheet.
/// Fallback: local role switch clearly labelled "Demo login". Never implies
/// production authentication. NEVER remove the demo fallback.
struct AuthAdapter {

    private static let demoAccountKey = "runway90.demo.auth.account"
    private static let demoSessionKey = "runway90.demo.auth.session"
    private static let credentialsManager = CredentialsManager(authentication: Auth0.authentication())

    private struct DemoAccount {
        let displayName: String
        let email: String
        let subject: String
    }

    /// Live when Auth0.plist is bundled with real values.
    static var isLive: Bool {
        guard let path = Bundle.main.path(forResource: "Auth0", ofType: "plist"),
              let values = NSDictionary(contentsOfFile: path),
              let clientId = values["ClientId"] as? String, !clientId.isEmpty,
              let domain = values["Domain"] as? String, !domain.isEmpty
        else { return false }
        return true
    }

    /// True when Auth0 Domain + ClientId are present — enough for Universal Login.
    /// The backend (Tiger/Gemini/Backboard proxy) is optional; adapters fall back
    /// to labelled demo paths when it is not deployed.
    static var hasLiveAPIConfiguration: Bool { isLive }

    /// True when the full backend proxy is also configured (audience + URL).
    static var hasBackendConfiguration: Bool {
        guard isLive,
              let audience = apiAudience,
              let backendURL = backendURL,
              !audience.contains("YOUR_"),
              !backendURL.contains("YOUR_") else { return false }
        return true
    }

    struct Session {
        var role: Role
        var displayName: String
        var isDemo: Bool
        var mfaVerified: Bool
        /// Auth0 access token for the Runway 90 API. Demo sessions have none.
        var accessToken: String?
        /// Auth0 `sub` for live sessions; stable demo IDs for local roles.
        /// Tiger snapshot rows are scoped by this identifier.
        var subject: String
    }

    enum AuthError: LocalizedError {
        case missingSubject
        case failedToStoreCredentials

        var errorDescription: String? {
            switch self {
            case .missingSubject:
                return "Auth0 did not return a stable user identifier."
            case .failedToStoreCredentials:
                return "The Auth0 session could not be saved securely on this device."
            }
        }
    }

    // MARK: - Demo fallback (always available)

    static func demoLogin(role: Role) -> Session {
        let account = storedDemoAccount()
        return Session(role: role,
                       displayName: role == .survivor ? account.displayName : "Demo Advocate",
                       isDemo: true,
                       mfaVerified: role == .survivor, // advocate must pass the demo-MFA sheet
                       accessToken: nil,
                       subject: role == .survivor ? account.subject : "demo-advocate-001")
    }

    /// Convenience: pre-seeded demo subject for Isabel (matches Fixture.fresh)
    static var defaultDemoSubject: String { "demo-isabel-001" }

    static var hasPreviousDemoLogin: Bool {
        UserDefaults.standard.bool(forKey: demoSessionKey)
    }

    static func demoCreateAccount(displayName: String, email: String) -> Session {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeName = name.isEmpty ? "Isabel" : name
        let safeEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let account = DemoAccount(displayName: safeName,
                                  email: safeEmail.isEmpty ? "maya.demo@runway90.invalid" : safeEmail,
                                  subject: "demo-\(UUID().uuidString.lowercased())")
        storeDemoAccount(account)
        UserDefaults.standard.set(true, forKey: demoSessionKey)
        return Session(role: .survivor,
                       displayName: account.displayName,
                       isDemo: true,
                       mfaVerified: true,
                       accessToken: nil,
                       subject: account.subject)
    }

    static func rememberDemoLogin(_ session: Session) {
        guard session.isDemo, session.role == .survivor else { return }
        UserDefaults.standard.set(true, forKey: demoSessionKey)
    }

    static func clearDemoLogin() {
        UserDefaults.standard.removeObject(forKey: demoSessionKey)
    }

    // MARK: - Live Auth0

    private static let rolesClaim = "https://runway90.app/roles"

    @MainActor
    static func loginLive(createAccount: Bool = false) async throws -> Session {
        // Use the API audience when the backend is configured; otherwise basic OIDC.
        var webAuth = Auth0.webAuth()
        if let audience = apiAudience, !audience.contains("YOUR_") {
            webAuth = webAuth.audience(audience)
        }
        var request = webAuth.scope("openid profile email offline_access")
        if createAccount {
            request = request.parameters(["screen_hint": "signup"])
        }
        let credentials = try await request.start()

        guard credentialsManager.store(credentials: credentials) else {
            throw AuthError.failedToStoreCredentials
        }

        return try session(from: credentials)
    }

    /// Rehydrates a previous Auth0 session from the SDK's Keychain store.
    /// Auth0.swift renews the access token when a refresh token is available.
    @MainActor
    static func restoreSession() async -> Session? {
        guard isLive else { return nil }
        do {
            let credentials = try await credentialsManager.credentials()
            return try session(from: credentials)
        } catch {
            return nil
        }
    }

    private static func session(from credentials: Credentials) throws -> Session {

        let claims = decodeJWTPayload(credentials.idToken) ?? [:]
        guard let subject = claims["sub"] as? String, !subject.isEmpty else {
            throw AuthError.missingSubject
        }
        let roles = (claims[rolesClaim] as? [String]) ?? []
        let role: Role = roles.contains("advocate") ? .advocate : .survivor
        let displayName = (claims["name"] as? String)
            ?? (claims["given_name"] as? String)
            ?? (claims["nickname"] as? String)
            ?? (claims["email"] as? String)
            ?? "Survivor"

        return Session(role: role,
                       displayName: displayName,
                       isDemo: false,
                       mfaVerified: true, // tenant policy enforces MFA before we get here
                       accessToken: credentials.accessToken,
                       subject: subject)
    }

    @MainActor
    static func logoutLive() async {
        try? await Auth0.webAuth().clearSession()
        _ = credentialsManager.clear()
    }

    private static var apiAudience: String? {
        guard let path = Bundle.main.path(forResource: "Auth0", ofType: "plist"),
              let values = NSDictionary(contentsOfFile: path),
              let audience = values["Audience"] as? String,
              !audience.isEmpty,
              !audience.contains("YOUR_") else { return nil }
        return audience
    }

    private static var backendURL: String? {
        guard let path = Bundle.main.path(forResource: "Auth0", ofType: "plist"),
              let values = NSDictionary(contentsOfFile: path),
              let backendURL = values["BackendURL"] as? String,
              !backendURL.isEmpty else { return nil }
        return backendURL
    }

    private static func storedDemoAccount() -> DemoAccount {
        guard let values = UserDefaults.standard.dictionary(forKey: demoAccountKey),
              let displayName = values["displayName"] as? String,
              let email = values["email"] as? String,
              let subject = values["subject"] as? String else {
            return DemoAccount(displayName: "Isabel",
                               email: "skmpe15@gmail.com",
                               subject: "demo-isabel-001")
        }
        return DemoAccount(displayName: displayName, email: email, subject: subject)
    }

    private static func storeDemoAccount(_ account: DemoAccount) {
        UserDefaults.standard.set([
            "displayName": account.displayName,
            "email": account.email,
            "subject": account.subject
        ], forKey: demoAccountKey)
    }

    /// Minimal JWT payload decoder (we only need custom claims; signature
    /// verification already happened in the SDK's token exchange).
    private static func decodeJWTPayload(_ jwt: String) -> [String: Any]? {
        let parts = jwt.split(separator: ".")
        guard parts.count == 3 else { return nil }
        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }
        guard let data = Data(base64Encoded: base64) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}
