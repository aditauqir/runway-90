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

    /// Live when Auth0.plist is bundled with real values.
    static var isLive: Bool {
        guard let path = Bundle.main.path(forResource: "Auth0", ofType: "plist"),
              let values = NSDictionary(contentsOfFile: path),
              let clientId = values["ClientId"] as? String, !clientId.isEmpty,
              let domain = values["Domain"] as? String, !domain.isEmpty
        else { return false }
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

        var errorDescription: String? {
            "Auth0 did not return a stable user identifier."
        }
    }

    // MARK: - Demo fallback (always available)

    static func demoLogin(role: Role) -> Session {
        Session(role: role,
                displayName: role == .survivor ? "Maya" : "Demo Advocate",
                isDemo: true,
                mfaVerified: role == .survivor, // advocate must pass the demo-MFA sheet
                accessToken: nil,
                subject: role == .survivor ? "demo-maya-001" : "demo-advocate-001")
    }

    // MARK: - Live Auth0

    private static let rolesClaim = "https://runway90.app/roles"

    @MainActor
    static func loginLive() async throws -> Session {
        let webAuth = apiAudience.map { Auth0.webAuth().audience($0) } ?? Auth0.webAuth()
        let credentials = try await webAuth
            .scope("openid profile email")
            .start()

        let claims = decodeJWTPayload(credentials.idToken) ?? [:]
        guard let subject = claims["sub"] as? String, !subject.isEmpty else {
            throw AuthError.missingSubject
        }
        let roles = (claims[rolesClaim] as? [String]) ?? []
        let role: Role = roles.contains("advocate") ? .advocate : .survivor
        let name = (claims["name"] as? String)
            ?? (claims["nickname"] as? String)
            ?? (claims["email"] as? String)
            ?? (role == .survivor ? "Survivor" : "Advocate")

        return Session(role: role,
                       displayName: role == .survivor ? "Maya" : name,
                       isDemo: false,
                       mfaVerified: true, // tenant policy enforces MFA before we get here
                       accessToken: credentials.accessToken,
                       subject: subject)
    }

    @MainActor
    static func logoutLive() async {
        try? await Auth0.webAuth().clearSession()
    }

    private static var apiAudience: String? {
        guard let path = Bundle.main.path(forResource: "Auth0", ofType: "plist"),
              let values = NSDictionary(contentsOfFile: path),
              let audience = values["Audience"] as? String,
              !audience.isEmpty,
              !audience.contains("YOUR_") else { return nil }
        return audience
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
