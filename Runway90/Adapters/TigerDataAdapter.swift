import Foundation
import PostgresClientKit

/// Tiger Data adapter — event-backed runway history (spec section 6).
/// Live path (verified 2026-09-18): direct TLS connection from the app to the
/// Tiger Cloud (TimescaleDB) service using PostgresClientKit, inserting into
/// the `events` hypertable:
///   events(id text, case_id text, type text, timestamp timestamptz, payload jsonb)
/// Fallback: same event schema kept in the local store, labelled "Demo data source".
struct TigerDataAdapter {

    /// TIGER_DATA_URL in Secrets.plist is the full postgres:// connection string.
    static var isLive: Bool { connectionConfig() != nil }

    /// Event types recorded (spec):
    /// fact_confirmed, account_marked_not_mine, assistance_request_created,
    /// assistance_request_approved, runway_recalculated
    static func record(event: TimelineEvent) {
        guard let config = connectionConfig() else { return }
        // Fire-and-forget on a background queue; failures never block the demo.
        DispatchQueue.global(qos: .utility).async {
            do {
                let connection = try PostgresClientKit.Connection(configuration: config)
                defer { connection.close() }
                let stmt = try connection.prepareStatement(text: """
                    INSERT INTO events (id, case_id, type, timestamp, payload)
                    VALUES ($1, $2, $3, $4, $5::jsonb);
                    """)
                defer { stmt.close() }
                let payloadJSON = (try? JSONSerialization.data(withJSONObject: event.payload))
                    .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
                try stmt.execute(parameterValues: [
                    event.id,
                    event.caseId,
                    event.type,
                    PostgresTimestampWithTimeZone(date: event.timestamp),
                    payloadJSON
                ])
            } catch {
                // Live insert failed — local event store (in CaseState.timeline)
                // remains the source of truth for the UI. Never fake success.
                #if DEBUG
                print("TigerDataAdapter insert failed: \(error)")
                #endif
            }
        }
    }

    // MARK: - Connection string parsing

    private static func connectionConfig() -> PostgresClientKit.ConnectionConfiguration? {
        guard let urlString = Secrets.tigerDataURL,
              let comps = URLComponents(string: urlString),
              comps.scheme?.hasPrefix("postgres") == true,
              let host = comps.host,
              let user = comps.user,
              let password = comps.password
        else { return nil }

        var config = PostgresClientKit.ConnectionConfiguration()
        config.host = host
        config.port = comps.port ?? 5432
        config.database = comps.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        config.user = user
        config.credential = .scramSHA256(password: password)
        config.ssl = true
        return config
    }
}
