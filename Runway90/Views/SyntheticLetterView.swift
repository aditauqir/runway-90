import SwiftUI

/// The bundled, clearly fictional collection letter ("maya_collection_letter").
/// Rendered in-app so the fixture always works, and rasterised with
/// ImageRenderer so the live Gemini path has a real image to read.
struct SyntheticLetterView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("NORTHSTAR COLLECTIONS")
                    .font(.system(.subheadline, design: .serif).weight(.bold))
                Spacer()
                Text("FICTIONAL")
                    .font(.caption2.weight(.heavy))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.red.opacity(0.85), in: Capsule())
                    .foregroundStyle(.white)
            }
            Divider().background(Color.black.opacity(0.3))

            Group {
                Text("RE: Outstanding balance — account ending 4471")
                    .font(.system(.footnote, design: .serif).weight(.semibold))
                Text("""
                Dear Account Holder,

                Our records indicate an outstanding balance of $2,310 on the \
                account referenced above, opened 03/2024. Please contact our \
                office to resolve this matter.
                """)
                .font(.system(.caption, design: .serif))
                Text("Amount due: $2,310")
                    .font(.system(.footnote, design: .serif).weight(.bold))
                Text("Account opened: March 2024 · Ref: NSC-4471-DEMO")
                    .font(.system(.caption2, design: .serif))
            }
            .foregroundStyle(Color.black.opacity(0.85))

            Text("SYNTHETIC DEMO DOCUMENT — not a real debt, company, or person")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.red.opacity(0.8))
        }
        .padding(14)
        .background(Color(hex: 0xF5F0E8), in: RoundedRectangle(cornerRadius: 10))
        .foregroundStyle(.black)
    }

    /// Rasterise the letter for the Gemini vision call.
    @MainActor
    static func renderImage() -> UIImage? {
        let renderer = ImageRenderer(content: SyntheticLetterView().frame(width: 360))
        renderer.scale = 3
        return renderer.uiImage
    }
}
