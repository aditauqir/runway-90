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

    static func extract(image: UIImage?, accessToken: String?) async -> Output {
        guard let image, let accessToken,
              BackendAPI.isLive(accessToken: accessToken) else {
            try? await Task.sleep(nanoseconds: 1_200_000_000) // brief "extracting" state for the demo beat
            return Output(result: Fixture.extractionFixture, isLive: false)
        }
        do {
            let result = try await BackendAPI.extract(image: image, accessToken: accessToken)
            return Output(result: result, isLive: true)
        } catch {
            // Labelled fallback, never a fake success.
            return Output(result: Fixture.extractionFixture, isLive: false)
        }
    }
}
