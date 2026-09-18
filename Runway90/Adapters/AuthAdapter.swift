import Foundation

/// Auth0 adapter — role separation and scoped sharing (spec section 6).
/// Live path: Auth0 universal login (add the Auth0.swift SPM package and wire
/// `loginLive` when AUTH0_DOMAIN / AUTH0_CLIENT_ID are configured).
/// Fallback: local role switch clearly labelled "Demo login". Never implies
/// production authentication.
struct AuthAdapter {

    static var isLive: Bool { Secrets.auth0Domain != nil && Secrets.auth0ClientId != nil }

    struct Session {
        var role: Role
        var displayName: String
        var isDemo: Bool
        var mfaVerified: Bool
    }

    /// Demo login fallback. `demoMFA` simulates the MFA step with a labelled sheet.
    static func demoLogin(role: Role) -> Session {
        Session(role: role,
                displayName: role == .survivor ? "Maya" : "Demo Advocate",
                isDemo: true,
                mfaVerified: role == .survivor) // advocate must pass the demo-MFA sheet
    }

    // TODO(live): implement with Auth0.swift:
    //   Auth0.webAuth().audience(...).scope("openid profile").start { ... }
    // Map Auth0 roles claim -> Role. Enforce MFA for the advocate role via an
    // Auth0 Action ("Require MFA for advocate").
}
