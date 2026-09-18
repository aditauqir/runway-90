import Foundation
import UIKit

/// Gemini vision extraction adapter.
/// Live path: sends the synthetic letter image to the Gemini API and asks for JSON.
/// Fallback path: returns the bundled fixture and reports `isLive = false`
/// so the UI can show "Demo extraction". Never fakes a live call.
struct GeminiAdapter {

    struct Output {
        var result: ExtractionResult
        var isLive: Bool
    }

    static func extract(image: UIImage?) async -> Output {
        guard let key = Secrets.geminiAPIKey, let image, let jpeg = image.jpegData(compressionQuality: 0.7) else {
            try? await Task.sleep(nanoseconds: 1_200_000_000) // brief "extracting" state for the demo beat
            return Output(result: Fixture.extractionFixture, isLive: false)
        }
        do {
            let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(key)")!
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let prompt = """
            Extract the financial facts from this collection letter image. \
            Respond with JSON only, matching exactly this schema: \
            {"documentType": "collection_letter", "facts": [{"counterparty": string, \
            "accountLast4": string, "amount": number, "openedDate": "YYYY-MM", \
            "reviewStatus": "unconfirmed"}]}. \
            Never label anything as fraud. reviewStatus is always "unconfirmed".
            """

            let body: [String: Any] = [
                "contents": [[
                    "parts": [
                        ["text": prompt],
                        ["inline_data": ["mime_type": "image/jpeg", "data": jpeg.base64EncodedString()]]
                    ]
                ]],
                "generationConfig": ["response_mime_type": "application/json"]
            ]
            req.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }

            // Pull the JSON text out of the Gemini response envelope.
            struct Envelope: Codable {
                struct Candidate: Codable {
                    struct Content: Codable {
                        struct Part: Codable { let text: String? }
                        let parts: [Part]
                    }
                    let content: Content
                }
                let candidates: [Candidate]
            }
            let env = try JSONDecoder().decode(Envelope.self, from: data)
            guard let text = env.candidates.first?.content.parts.compactMap(\.text).joined(),
                  let jsonData = text.data(using: .utf8) else { throw URLError(.cannotParseResponse) }
            let result = try JSONDecoder().decode(ExtractionResult.self, from: jsonData)
            return Output(result: result, isLive: true)
        } catch {
            // Labelled fallback, never a fake success.
            return Output(result: Fixture.extractionFixture, isLive: false)
        }
    }
}
