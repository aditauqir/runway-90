import Foundation

/// Backboard memory adapter.
/// Purpose: persistent case memory across app restarts (spec section 6).
/// Live path: sync MemoryEntry key/values + case state to Backboard when a key exists.
/// Fallback: local JSON persistence in Documents. UI shows "Demo memory fallback"
/// only in a small debug indicator.
struct BackboardAdapter {

    static var isLive: Bool { Secrets.backboardAPIKey != nil }

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("runway90_case_state.json")
    }

    static func load() -> CaseState? {
        // TODO(live): if isLive, fetch memory from Backboard API and merge.
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? decoder.decode(CaseState.self, from: data)
    }

    static func save(_ state: CaseState) {
        if let data = try? encoder.encode(state) {
            try? data.write(to: fileURL, options: .atomic)
        }
        if isLive {
            Task { await syncToBackboard(state) }
        }
    }

    static func deleteAll() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    /// Best-effort remote sync of the memory entries. Failures never block the app.
    private static func syncToBackboard(_ state: CaseState) async {
        guard let key = Secrets.backboardAPIKey else { return }
        // Backboard exposes an OpenAI-compatible / REST API; adjust the path to
        // the endpoint given in the hackathon sponsor docs.
        guard let url = URL(string: "https://app.backboard.io/api/memories") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        let payload: [String: Any] = [
            "caseId": state.caseRecord.id,
            "memories": state.memory.map { ["key": $0.key, "value": $0.value] }
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        _ = try? await URLSession.shared.data(for: req)
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
