import Foundation

/// Backboard memory adapter.
/// Purpose: persistent case memory across app restarts (spec section 6).
/// Live path: sync MemoryEntry key/values + case state to Backboard when a key exists.
/// Fallback: local JSON persistence in Documents. UI shows "Demo memory fallback"
/// only in a small debug indicator.
struct BackboardAdapter {

    static var isLive: Bool { BackendAPI.isConfigured }

    static func isLive(for accessToken: String?) -> Bool {
        BackendAPI.isLive(accessToken: accessToken)
    }

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("runway90_case_state.json")
    }

    static func load() -> CaseState? {
        // TODO(live): if isLive, fetch memory from Backboard API and merge.
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? decoder.decode(CaseState.self, from: data)
    }

    static func save(_ state: CaseState, accessToken: String? = nil) {
        if let data = try? encoder.encode(state) {
            try? data.write(to: fileURL, options: .atomic)
        }
        if let accessToken, BackendAPI.isLive(accessToken: accessToken) {
            Task { await BackendAPI.syncMemory(state, accessToken: accessToken) }
        }
    }

    static func deleteAll() {
        try? FileManager.default.removeItem(at: fileURL)
    }


    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
