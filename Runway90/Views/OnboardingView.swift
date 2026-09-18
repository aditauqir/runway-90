import SwiftUI

/// 5-page trauma-informed onboarding flow for new survivor accounts.
/// - Page 0: Welcome
/// - Page 1: Privacy and safety (requires acknowledgement)
/// - Page 2: How the recovery loop works
/// - Page 3: Personalization (display name + preferences)
/// - Page 4: Ready screen (one primary action)
///
/// Quick exit works from every page. Advocates never see this flow.
/// Onboarding completion is scoped per Auth0 subject / demo subject via
/// `UserDefaults` key `runway90.onboarding.completed.<subject>`.
struct OnboardingView: View {
    @EnvironmentObject var store: AppStore
    @State private var savingDocs = false
    @State private var docsSaved = 0
    @State private var docsSaveError: String?

    private let totalPages = 5

    var body: some View {
        ZStack {
            RW.gradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress + safety exit
                HStack {
                    progressDots
                    Spacer()
                    Button {
                        store.quickExit()
                    } label: {
                        Text("Exit")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(RW.cloud.opacity(0.9))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                TabView(selection: $store.onboardingPage) {
                    welcomePage.tag(0)
                    safetyPage.tag(1)
                    loopPage.tag(2)
                    personalizationPage.tag(3)
                    readyPage.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.smooth(duration: 0.35), value: store.onboardingPage)

                // Navigation buttons
                HStack(spacing: 16) {
                    if store.onboardingPage > 0 {
                        Button {
                            withAnimation { store.onboardingPage -= 1 }
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RW.cloud)
                                .frame(height: 50)
                                .padding(.horizontal, 20)
                        }
                        .rwGlassButton()
                    }

                    Spacer()

                    if store.onboardingPage < totalPages - 1 {
                        Button {
                            withAnimation { store.onboardingPage += 1 }
                        } label: {
                            Label("Continue", systemImage: "chevron.right")
                                .font(.subheadline.weight(.semibold))
                                .frame(height: 50)
                                .padding(.horizontal, 24)
                        }
                        .rwPrimaryButton()
                        .disabled(store.onboardingPage == 1 && !store.onboardingSafetyAcked)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Progress dots

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalPages, id: \.self) { i in
                Circle()
                    .fill(i == store.onboardingPage ? RW.pink : RW.cloud.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
            Text("\(store.onboardingPage + 1) of \(totalPages)")
                .font(.caption2)
                .foregroundStyle(RW.mist)
        }
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                Image(systemName: "airplane.departure")
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(RW.pink)

                Text("Welcome to Runway 90")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(RW.cloud)
                    .multilineTextAlignment(.center)

                Text("Runway 90 helps you organize the first steps of financial recovery after leaving an unsafe or controlling situation.")
                    .font(.body)
                    .foregroundStyle(RW.cloud.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    featureRow(icon: "doc.text.magnifyingglass", text: "Capture and review financial documents")
                    featureRow(icon: "checkmark.circle", text: "You decide what is true — never the app")
                    featureRow(icon: "calendar.badge.clock", text: "See how many days of essentials you have covered")
                    featureRow(icon: "hand.raised.fill", text: "Share only what you choose with an advocate")
                }
                .glassCard()
                .padding(.horizontal, 16)

                SyntheticBanner()
                Spacer()
            }
        }
    }

    // MARK: - Page 2: Privacy and safety

    private var safetyPage: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer().frame(height: 24)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(RW.mist)

                Text("Privacy and safety")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(RW.cloud)

                VStack(alignment: .leading, spacing: 16) {
                    safetyRow(icon: "theatermasks", title: "Synthetic data only",
                              text: "This demo uses entirely fictional data. No real financial accounts, survivors, or organisations.")

                    safetyRow(icon: "hand.raised.circle", title: "You are the source of truth",
                              text: "Documents are not treated as facts until you confirm them. The app never labels anything as fraud.")

                    safetyRow(icon: "xmark.shield.fill", title: "Quick exit is always available",
                              text: "Shake the phone, triple-tap, or tap the Exit button. Runway 90 will instantly switch to the Weather app so your screen looks completely normal.")

                    safetyRow(icon: "eye.slash", title: "Decoy protection",
                              text: "If the Weather app is unavailable, a neutral decoy screen appears with no case data, names, or amounts visible.")
                }
                .glassCard()
                .padding(.horizontal, 16)

                // Acknowledgement toggle — Continue is disabled until checked
                Button {
                    withAnimation { store.onboardingSafetyAcked.toggle() }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: store.onboardingSafetyAcked ? "checkmark.square.fill" : "square")
                            .font(.title3)
                            .foregroundStyle(store.onboardingSafetyAcked ? RW.pink : RW.mist)
                        Text("I understand how quick exit works")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RW.cloud)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Acknowledge quick exit")

                if !store.onboardingSafetyAcked {
                    Text("Please acknowledge to continue")
                        .font(.caption2)
                        .foregroundStyle(RW.mist.opacity(0.7))
                }

                SyntheticBanner()
                Spacer()
            }
        }
    }

    // MARK: - Page 3: How the recovery loop works

    private var loopPage: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer().frame(height: 24)

                Text("How it works")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(RW.cloud)

                Text("Five steps. You control every one.")
                    .font(.subheadline)
                    .foregroundStyle(RW.mist)

                VStack(alignment: .leading, spacing: 0) {
                    stepRow(number: 1, icon: "camera.fill", title: "Capture a document",
                            text: "Photograph a letter, bill, or statement.")
                    stepDivider()
                    stepRow(number: 2, icon: "sparkles", title: "Review extracted details",
                            text: "The app reads the document and shows you structured cards.")
                    stepDivider()
                    stepRow(number: 3, icon: "hand.tap.fill", title: "Decide: Mine, Not mine, or Not sure",
                            text: "Nothing enters your record without your explicit choice.")
                    stepDivider()
                    stepRow(number: 4, icon: "airplane.departure", title: "See one next action",
                            text: "Your runway estimate and exactly one practical next step.")
                    stepDivider()
                    stepRow(number: 5, icon: "person.badge.shield.checkmark.fill", title: "Share only what you approve",
                            text: "A neutral summary for your advocate. Private notes stay private.")
                }
                .glassCard()
                .padding(.horizontal, 16)

                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(RW.pink)
                    Text("The app never labels an account as fraud. Only you decide what is unrecognised, inconsistent, or requires review.")
                        .font(.caption)
                        .foregroundStyle(RW.cloud.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                SyntheticBanner()
                Spacer()
            }
        }
    }

    // MARK: - Page 4: Personalization

    private var personalizationPage: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer().frame(height: 24)

                Image(systemName: "person.crop.circle")
                    .font(.system(size: 44))
                    .foregroundStyle(RW.pink)

                Text("Make it yours")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(RW.cloud)

                Text("Only low-risk preferences. We will never ask for a real address, employer, bank, or account number.")
                    .font(.caption)
                    .foregroundStyle(RW.mist)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Display name")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RW.mist)
                        TextField("Maya", text: $store.onboardingDisplayName)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.name)
                    }

                    Toggle(isOn: $store.onboardingShowDemoLetter) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show demo letter on home screen")
                                .font(.subheadline).foregroundStyle(RW.cloud)
                            Text("The bundled synthetic collection letter will be ready to review.")
                                .font(.caption2).foregroundStyle(RW.mist)
                        }
                    }
                    .tint(RW.pink)

                    if store.session?.isDemo == true {
                        Toggle(isOn: $store.onboardingRememberSession) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Remember this demo session")
                                    .font(.subheadline).foregroundStyle(RW.cloud)
                                Text("Next launch will show a welcome-back button.")
                                    .font(.caption2).foregroundStyle(RW.mist)
                            }
                        }
                        .tint(RW.pink)
                    }
                }
                .glassCard()
                .padding(.horizontal, 16)

                // Save synthetic documents to Photos
                VStack(alignment: .leading, spacing: 12) {
                    Label("Sample documents", systemImage: "doc.on.doc.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(RW.mist)

                    Text("Save 3 synthetic financial documents to your photo library so you can pick them during the demo. All fictional — no real data.")
                        .font(.caption)
                        .foregroundStyle(RW.cloud.opacity(0.82))

                    if docsSaved > 0 {
                        Label("\(docsSaved) documents saved to Photos", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RW.pink)
                    } else {
                        Button {
                            Task { await saveDemoDocuments() }
                        } label: {
                            HStack {
                                if savingDocs {
                                    ProgressView().tint(RW.cloud)
                                }
                                Text(savingDocs ? "Saving..." : "Save demo documents to Photos")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                        }
                        .rwPrimaryButton(RW.pink)
                        .disabled(savingDocs)
                    }

                    if let docsSaveError {
                        Text(docsSaveError)
                            .font(.caption2)
                            .foregroundStyle(RW.raspberry)
                    }

                    Text("Documents: Collection letter (Northstar), Bank statement (Peachtree FCU), Credit notice (TransUnion)")
                        .font(.caption2)
                        .foregroundStyle(RW.mist.opacity(0.7))
                }
                .glassCard(tint: RW.pink)
                .padding(.horizontal, 16)

                SyntheticBanner()
                Spacer()
            }
        }
    }

    // MARK: - Page 5: Ready

    private var readyPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 48)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(RW.pink)

                Text("You are in control")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(RW.cloud)

                // Summarize choices
                VStack(alignment: .leading, spacing: 10) {
                    summaryRow("Name", store.onboardingDisplayName.isEmpty ? "Maya" : store.onboardingDisplayName)
                    summaryRow("Demo letter on home", store.onboardingShowDemoLetter ? "Yes" : "No")
                    if store.session?.isDemo == true {
                        summaryRow("Remember session", store.onboardingRememberSession ? "Yes" : "No")
                    }
                    summaryRow("Quick exit", "Shake, triple-tap, or Exit button")
                }
                .glassCard()
                .padding(.horizontal, 16)

                // Primary action
                Button {
                    store.completeOnboarding()
                    store.route = .survivor
                } label: {
                    Label("Review the demo letter", systemImage: "doc.viewfinder")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .rwPrimaryButton()
                .padding(.horizontal, 24)

                Button {
                    store.completeOnboarding()
                    store.route = .survivor
                } label: {
                    Text("Skip for now — go to Home")
                        .font(.subheadline)
                        .foregroundStyle(RW.mist)
                }
                .buttonStyle(.plain)

                Text("Contents produced are for demo only.")
                    .font(.caption2)
                    .foregroundStyle(RW.cloud.opacity(0.7))

                Spacer()
            }
        }
    }

    // MARK: - Save demo docs

    @MainActor
    private func saveDemoDocuments() async {
        savingDocs = true
        docsSaveError = nil
        let granted = await SyntheticDocuments.requestAccess()
        guard granted else {
            docsSaveError = "Photo library access denied. Go to Settings > Privacy > Photos to allow."
            savingDocs = false
            return
        }
        let count = await SyntheticDocuments.saveAllToPhotos()
        docsSaved = count
        if count == 0 {
            docsSaveError = "Could not save documents. Please try again."
        }
        savingDocs = false
    }

    // MARK: - Helpers

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(RW.pink)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(RW.cloud)
            Spacer()
        }
    }

    private func safetyRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(RW.mist)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(RW.cloud)
                Text(text).font(.caption).foregroundStyle(RW.cloud.opacity(0.82))
            }
            Spacer()
        }
    }

    private func stepRow(number: Int, icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(RW.raspberry)
                    .frame(width: 30, height: 30)
                Text("\(number)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RW.cloud)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: icon).font(.footnote).foregroundStyle(RW.pink)
                    Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(RW.cloud)
                }
                Text(text).font(.caption).foregroundStyle(RW.cloud.opacity(0.82))
            }
            Spacer()
        }
    }

    private func stepDivider() -> some View {
        HStack {
            Rectangle()
                .fill(RW.mist.opacity(0.25))
                .frame(width: 2, height: 16)
                .padding(.leading, 14)
            Spacer()
        }
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.callout).foregroundStyle(RW.mist)
            Spacer()
            Text(value).font(.callout.weight(.medium)).foregroundStyle(RW.cloud)
        }
    }
}
