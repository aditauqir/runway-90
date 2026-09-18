import SwiftUI

@main
struct Runway90App: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
                    store.quickExit()   // shake = quick exit (spec section 7)
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ZStack {
            switch store.route {
            case .disclosure: DisclosureView()
            case .roleEntry:  RoleEntryView()
            case .onboarding: OnboardingView()
            case .survivor:   SurvivorRootView()
            case .advocate:   AdvocateView()
            case .decoy:      DecoyView()
            }
        }
        .animation(.smooth(duration: 0.35), value: store.route)
    }
}

// MARK: - Shake detection (quick exit on physical devices)

extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}

// MARK: - Reusable safety toolbar (visible quick-exit fallback for simulator)

struct QuickExitButton: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        Button {
            store.quickExit()
        } label: {
            Label("Exit", systemImage: "xmark.shield.fill")
                .font(.footnote.weight(.semibold))
        }
        .rwGlassButton()
        .accessibilityLabel("Quick exit")
    }
}

struct SyntheticBanner: View {
    var body: some View {
        Text("Contents produced are for demo only.")
            .font(.caption2)
            .foregroundStyle(RW.cloud.opacity(0.7))
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}
