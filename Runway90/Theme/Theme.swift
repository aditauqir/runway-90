import SwiftUI

// MARK: - Runway 90 palette (Coolors: b60e41-e03068-c4dee5-292227-f5f5f5)
enum RW {
    static let raspberry = Color(hex: 0xB60E41)   // primary
    static let pink      = Color(hex: 0xE03068)   // accent
    static let mist      = Color(hex: 0xC4DEE5)   // glass tint / info
    static let plum      = Color(hex: 0x292227)   // background
    static let cloud     = Color(hex: 0xF5F5F5)   // surfaces / text on dark

    static let gradient = LinearGradient(
        colors: [raspberry.opacity(0.85), plum, plum],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

// MARK: - Liquid glass card
// Uses Apple's real Liquid Glass on iOS 26+, falls back to ultraThinMaterial.
struct GlassCard: ViewModifier {
    var tint: Color = RW.mist
    var corner: CGFloat = 24

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .padding(18)
                .glassEffect(.regular.tint(tint.opacity(0.12)).interactive(),
                             in: .rect(cornerRadius: corner))
        } else {
            content
                .padding(18)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: corner))
                .overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .strokeBorder(tint.opacity(0.25), lineWidth: 1)
                )
        }
    }
}

extension View {
    func glassCard(tint: Color = RW.mist, corner: CGFloat = 24) -> some View {
        modifier(GlassCard(tint: tint, corner: corner))
    }
}

// MARK: - Glass button style
struct GlassProminentButton: ViewModifier {
    var tint: Color = RW.raspberry
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glassProminent).tint(tint)
        } else {
            content.buttonStyle(.borderedProminent).tint(tint)
        }
    }
}

struct GlassPlainButton: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glass)
        } else {
            content.buttonStyle(.bordered).tint(RW.mist)
        }
    }
}

extension View {
    func rwPrimaryButton(_ tint: Color = RW.raspberry) -> some View {
        modifier(GlassProminentButton(tint: tint))
    }
    func rwGlassButton() -> some View {
        modifier(GlassPlainButton())
    }
}

// MARK: - Screen background
struct RWBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RW.gradient.ignoresSafeArea())
            .preferredColorScheme(.dark)
    }
}

extension View {
    func rwScreen() -> some View { modifier(RWBackground()) }
}
