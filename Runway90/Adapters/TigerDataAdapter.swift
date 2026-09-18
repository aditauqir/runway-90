import Foundation
@preconcurrency import PostgresClientKit

/// Tiger Data adapter — event-backed runway history plus case snapshots.
/// Live path (verified 2026-09-18): direct TLS connection from the app to the
/// Tiger Cloud (TimescaleDB) service using PostgresClientKit, inserting into
/// the `events` hypertable and `case_snapshots` table:
///   events(id text, case_id text, type text, timestamp timestamptz, payload jsonb)
///   case_snapshots(owner_id text primary key, case_id text, updated_at timestamptz,
///                  payload jsonb)
/// Fallback: the same state and event schema are kept in the local store,
/// labelled "Demo data source".
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

    /// Persist the complete synthetic CaseState in Tiger Cloud so a new install
    /// can recover it after the survivor signs in again. The owner ID is the
    /// Auth0 `sub` for live sessions, or a stable demo ID for local demo login.
    static func saveSnapshot(_ state: CaseState, ownerID: String) {
        guard let config = connectionConfig(),
              let payload = encode(state) else { return }

        DispatchQueue.global(qos: .utility).async {
            do {
                let connection = try PostgresClientKit.Connection(configuration: config)
                defer { connection.close() }
                try ensureSnapshotTable(on: connection)

                let stmt = try connection.prepareStatement(text: """
                    INSERT INTO case_snapshots (owner_id, case_id, updated_at, payload)
                    VALUES ($1, $2, $3, $4::jsonb)
                    ON CONFLICT (owner_id) DO UPDATE SET
                        case_id = EXCLUDED.case_id,
                        updated_at = EXCLUDED.updated_at,
                        payload = EXCLUDED.payload;
                    """)
                defer { stmt.close() }
                try stmt.execute(parameterValues: [
                    ownerID,
                    state.caseRecord.id,
                    PostgresTimestampWithTimeZone(date: Date()),
                    payload
                ])
            } catch {
                #if DEBUG
                print("TigerDataAdapter snapshot save failed: \(error)")
                #endif
            }
        }
    }

    /// Load a complete case snapshot for an Auth0 subject or demo owner.
    static func loadSnapshot(ownerID: String) async -> CaseState? {
        guard let config = connectionConfig() else { return nil }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                do {
                    let connection = try PostgresClientKit.Connection(configuration: config)
                    defer { connection.close() }
                    try ensureSnapshotTable(on: connection)

                    let stmt = try connection.prepareStatement(text: """
                        SELECT payload::text
                        FROM case_snapshots
                        WHERE owner_id = $1
                        LIMIT 1;
                        """)
                    defer { stmt.close() }
                    let cursor = try stmt.execute(parameterValues: [ownerID])
                    defer { cursor.close() }

                    for row in cursor {
                        let columns = try row.get().columns
                        let payload = try columns[0].string()
                        guard let data = payload.data(using: .utf8) else { break }
                        let state = try decoder.decode(CaseState.self, from: data)
                        continuation.resume(returning: state)
                        return
                    }
                } catch {
                    #if DEBUG
                    print("TigerDataAdapter snapshot load failed: \(error)")
                    #endif
                }
                continuation.resume(returning: nil)
            }
        }
    }

    /// Delete a remote snapshot when the user deletes the demo case.
    static func deleteSnapshot(ownerID: String) {
        guard let config = connectionConfig() else { return }

        DispatchQueue.global(qos: .utility).async {
            do {
                let connection = try PostgresClientKit.Connection(configuration: config)
                defer { connection.close() }
                try ensureSnapshotTable(on: connection)
                let stmt = try connection.prepareStatement(text: """
                    DELETE FROM case_snapshots WHERE owner_id = $1;
                    """)
                defer { stmt.close() }
                try stmt.execute(parameterValues: [ownerID])
            } catch {
                #if DEBUG
                print("TigerDataAdapter snapshot delete failed: \(error)")
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

    private static func ensureSnapshotTable(on connection: PostgresClientKit.Connection) throws {
        let stmt = try connection.prepareStatement(text: """
            CREATE TABLE IF NOT EXISTS case_snapshots (
                owner_id text PRIMARY KEY,
                case_id text NOT NULL,
                updated_at timestamptz NOT NULL,
                payload jsonb NOT NULL
            );
            """)
        defer { stmt.close() }
        try stmt.execute()
    }

    private static func encode(_ state: CaseState) -> String? {
        guard let data = try? encoder.encode(state) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
