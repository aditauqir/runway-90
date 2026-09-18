import Foundation
import UIKit

/// Authenticated API client for the hosted Runway 90 backend.
///
/// The iPhone keeps only a small offline cache. Live case state, Tiger Data
/// writes, Gemini extraction, and Backboard memory go through this API so
/// database/API credentials never ship inside the TestFlight binary.
struct BackendAPI {

    struct BackendError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    private struct SnapshotRequest: Encodable {
        let state: CaseState
    }

    private struct EventRequest: Encodable {
        let event: TimelineEvent
    }

    private struct MemoryRequest: Encodable {
        let state: CaseState
    }

    private struct ExtractionRequest: Encodable {
        let imageBase64: String
        let mimeType: String
    }

    private struct ExtractionResponse: Decodable {
        let result: ExtractionResult
        let isLive: Bool
    }

    private struct ErrorResponse: Decodable {
        let error: String?
    }

    /// Public, non-secret backend URL stored in Auth0.plist. Replace the
    /// placeholder after deploying the `api/` folder to Vercel.
    static var baseURL: URL? {
        guard let path = Bundle.main.path(forResource: "Auth0", ofType: "plist"),
              let values = NSDictionary(contentsOfFile: path),
              let raw = values["BackendURL"] as? String,
              !raw.isEmpty,
              !raw.contains("YOUR_") else { return nil }
        return URL(string: raw.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }

    static var isConfigured: Bool { baseURL != nil }

    static func isLive(accessToken: String?) -> Bool {
        isConfigured && !(accessToken?.isEmpty ?? true)
    }

    static func loadCase(accessToken: String) async throws -> CaseState? {
        let (data, response) = try await request(path: "case", method: "GET", accessToken: accessToken)
        guard response.statusCode != 204 else { return nil }
        return try decoder.decode(CaseState.self, from: data)
    }

    static func saveCase(_ state: CaseState, accessToken: String) async {
        do {
            _ = try await request(path: "case", method: "PUT", accessToken: accessToken,
                                  body: try encoder.encode(SnapshotRequest(state: state)))
        } catch {
            log("case save", error: error)
        }
    }

    static func record(event: TimelineEvent, accessToken: String) async {
        do {
            _ = try await request(path: "events", method: "POST", accessToken: accessToken,
                                  body: try encoder.encode(EventRequest(event: event)))
        } catch {
            log("event record", error: error)
        }
    }

    static func deleteCase(accessToken: String) async {
        do {
            _ = try await request(path: "case", method: "DELETE", accessToken: accessToken)
        } catch {
            log("case delete", error: error)
        }
    }

    static func extract(image: UIImage, accessToken: String) async throws -> ExtractionResult {
        guard let jpeg = image.jpegData(compressionQuality: 0.7) else {
            throw BackendError(message: "The document image could not be encoded.")
        }
        let body = try encoder.encode(ExtractionRequest(imageBase64: jpeg.base64EncodedString(),
                                                         mimeType: "image/jpeg"))
        let (data, _) = try await request(path: "extract", method: "POST", accessToken: accessToken,
                                           body: body)
        return try decoder.decode(ExtractionResponse.self, from: data).result
    }

    static func syncMemory(_ state: CaseState, accessToken: String) async {
        do {
            _ = try await request(path: "memory", method: "POST", accessToken: accessToken,
                                  body: try encoder.encode(MemoryRequest(state: state)))
        } catch {
            log("memory sync", error: error)
        }
    }

    private static func request(path: String, method: String, accessToken: String,
                                body: Data? = nil) async throws -> (Data, HTTPURLResponse) {
        guard let baseURL,
              let url = URL(string: baseURL.absoluteString + "/" + path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        else { throw BackendError(message: "Runway 90 backend URL is not configured.") }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw BackendError(message: "The backend returned an invalid response.")
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? decoder.decode(ErrorResponse.self, from: data).error)
                ?? "Backend request failed (HTTP \(http.statusCode))."
            throw BackendError(message: message ?? "Backend request failed (HTTP \(http.statusCode)).")
        }
        return (data, http)
    }

    private static func log(_ operation: String, error: Error) {
        #if DEBUG
        print("BackendAPI \(operation) failed: \(error)")
        #endif
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
