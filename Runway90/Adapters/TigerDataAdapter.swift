import Foundation

/// Tiger Data adapter — event-backed runway history (spec section 6).
/// Live path: POST events to a Tiger Cloud (TimescaleDB) HTTP endpoint / proxy.
/// Fallback: same event schema kept in the local store, labelled "Demo data source".
struct TigerDataAdapter {

    static var isLive: Bool { Secrets.tigerDataURL != nil }

    /// Event types recorded (spec):
    /// fact_confirmed, account_marked_not_mine, assistance_request_created,
    /// assistance_request_approved, runway_recalculated
    static func record(event: TimelineEvent) {
        guard isLive, let base = Secrets.tigerDataURL, let url = URL(string: base + "/events") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = Secrets.tigerDataToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let payload: [String: Any] = [
            "id": event.id,
            "case_id": event.caseId,
            "type": event.type,
            "timestamp": ISO8601DateFormatter().string(from: event.timestamp),
            "payload": event.payload
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        Task { _ = try? await URLSession.shared.data(for: req) }
    }
}
