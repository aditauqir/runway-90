/// Tiger Data facade.
///
/// The app no longer opens a Postgres connection directly. Auth0 supplies the
/// bearer token, the backend validates it, and the backend scopes every query
/// to that token's `sub` before reading or writing Tiger Data.
struct TigerDataAdapter {

    static var isLive: Bool { BackendAPI.isConfigured }

    static func isLive(accessToken: String?) -> Bool {
        BackendAPI.isLive(accessToken: accessToken)
    }

    static func record(event: TimelineEvent, accessToken: String?) {
        guard let accessToken, BackendAPI.isLive(accessToken: accessToken) else { return }
        Task { await BackendAPI.record(event: event, accessToken: accessToken) }
    }

    static func saveSnapshot(_ state: CaseState, ownerID: String, accessToken: String?) {
        // ownerID remains in the facade for call-site clarity. The backend
        // intentionally ignores client-supplied ownership and uses Auth0 sub.
        guard let accessToken, BackendAPI.isLive(accessToken: accessToken) else { return }
        Task { await BackendAPI.saveCase(state, accessToken: accessToken) }
    }

    static func loadSnapshot(ownerID: String, accessToken: String) async throws -> CaseState? {
        guard BackendAPI.isLive(accessToken: accessToken) else { return nil }
        return try await BackendAPI.loadCase(accessToken: accessToken)
    }

    static func deleteSnapshot(ownerID: String, accessToken: String?) {
        guard let accessToken, BackendAPI.isLive(accessToken: accessToken) else { return }
        Task { await BackendAPI.deleteCase(accessToken: accessToken) }
    }
}
