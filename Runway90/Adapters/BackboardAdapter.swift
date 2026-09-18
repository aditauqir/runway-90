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
        // Backboard API (verified live 2026-09-18): base https://app.backboard.io/api,
        // auth header `X-API-Key`. Memory is attached to an assistant; we keep one
        // assistant per case and send memory as a thread message the assistant
        // remembers. Docs: https://docs.backboard.io
        let base = "https://app.backboard.io/api"
        var headers = ["Content-Type": "application/json", "X-API-Key": key]

        // Reuse (or create) the case assistant.
        var assistantId = UserDefaults.standard.string(forKey: "backboard_assistant_id")
        if assistantId == nil {
            var req = URLRequest(url: URL(string: "\(base)/assistants")!)
            req.httpMethod = "POST"
            headers.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }
            req.httpBody = try? JSONSerialization.data(withJSONObject: [
                "name": "runway90-\(state.caseRecord.id)",
                "instructions": "You store case memory for a synthetic demo. Remember every fact you are told."
            ])
            if let (data, resp) = try? await URLSession.shared.data(for: req),
               (resp as? HTTPURLResponse)?.statusCode ?? 500 < 300,
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let id = (obj["assistant_id"] ?? obj["id"]) as? String {
                assistantId = id
                UserDefaults.standard.set(id, forKey: "backboard_assistant_id")
            }
        }
        guard let assistantId else { return }

        // Push the memory snapshot as a message so Backboard memory retains it.
        let memoryText = state.memory.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        var req = URLRequest(url: URL(string: "\(base)/threads/messages")!)
        req.httpMethod = "POST"
        headers.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "assistant_id": assistantId,
            "content": "Case memory update for \(state.caseRecord.id) (synthetic demo data):\n\(memoryText)",
            "memory": "auto"
        ])
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
