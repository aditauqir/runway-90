import SwiftUI
import PhotosUI

/// Beat 2 + 3: document capture -> Gemini extraction -> confirm cards.
struct CaptureView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var pickedItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var showCamera = false
    @State private var started = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if !started {
                        capturePaths
                    } else if store.extracting {
                        extractingState
                    } else {
                        confirmCards
                    }
                }
                .padding()
            }
            .rwScreen()
            .navigationTitle("Review letter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }.tint(RW.mist)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                pickedImage = image
                start(with: image)
            }
            .ignoresSafeArea()
        }
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    pickedImage = img
                    start(with: img)
                }
            }
        }
    }

    private func start(with image: UIImage?) {
        started = true
        store.runExtraction(image: image)
    }

    // MARK: capture paths

    private var capturePaths: some View {
        VStack(spacing: 16) {
            SyntheticLetterView()
                .frame(maxWidth: .infinity)
                .glassCard()

            // Demo path — bundled synthetic letter always works
            Button {
                start(with: SyntheticLetterView.renderImage())
            } label: {
                Label("Use the demo letter", systemImage: "doc.text.image")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 6)
            }
            .rwPrimaryButton()

            // Photo picker path
            PhotosPicker(selection: $pickedItem, matching: .images) {
                Label("Choose from photos", systemImage: "photo.on.rectangle")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 6)
            }
            .rwGlassButton()

            // Device camera path
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button {
                    showCamera = true
                } label: {
                    Label("Use camera", systemImage: "camera")
                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 6)
                }
                .rwGlassButton()
            }

            SyntheticBanner()
        }
    }

    private var extractingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(RW.pink)
            Text("Reading the document…")
                .font(.headline).foregroundStyle(RW.cloud)
            Text("Gemini extracts the facts. You decide what is true.")
                .font(.caption).foregroundStyle(RW.mist)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .glassCard()
    }

    // MARK: confirm cards (Beat 3)

    private var confirmCards: some View {
        VStack(spacing: 16) {
            HStack {
                Label(store.extractionIsLive ? "Gemini extraction" : "Demo extraction",
                      systemImage: store.extractionIsLive ? "sparkles" : "shippingbox")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(store.extractionIsLive ? RW.pink : RW.mist)
                Spacer()
                Text("Status: requires review")
                    .font(.caption2).foregroundStyle(RW.mist)
            }

            if store.pendingFacts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.largeTitle).foregroundStyle(RW.pink)
                    Text("All facts reviewed")
                        .font(.headline).foregroundStyle(RW.cloud)
                    Text("The unrecognised account was added to your case timeline and neutral summary.")
                        .font(.caption).foregroundStyle(RW.mist)
                        .multilineTextAlignment(.center)
                    Button("Done") { dismiss() }
                        .rwPrimaryButton()
                }
                .frame(maxWidth: .infinity)
                .glassCard()
            } else {
                ForEach(store.pendingFacts) { fact in
                    FactConfirmCard(fact: fact)
                }
            }
        }
    }
}

/// One extracted fact with the three explicit choices: Mine / Not mine / Not sure.
struct FactConfirmCard: View {
    @EnvironmentObject var store: AppStore
    let fact: FinancialFact

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(fact.counterparty)
                .font(.headline).foregroundStyle(RW.cloud)

            VStack(alignment: .leading, spacing: 4) {
                if let last4 = fact.accountLast4 {
                    row("Account ending", last4)
                }
                if let amount = fact.amount {
                    row("Amount", amount.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                }
                if let opened = fact.openedDate {
                    row("Opened", opened)
                }
                row("Status", "requires review")
            }
            .font(.callout)

            Text("Nothing enters your confirmed record until you choose.")
                .font(.caption2).foregroundStyle(RW.mist)

            HStack(spacing: 10) {
                choice("Mine", .mine, RW.mist)
                choice("Not mine", .notMine, RW.raspberry)
                choice("Not sure", .notSure, RW.pink)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(tint: RW.pink)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(RW.mist)
            Spacer()
            Text(value).foregroundStyle(RW.cloud)
        }
    }

    private func choice(_ label: String, _ status: ReviewStatus, _ tint: Color) -> some View {
        Button {
            withAnimation(.smooth) { store.confirm(fact: fact, as: status) }
        } label: {
            Text(label).font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .rwPrimaryButton(tint)
    }
}

// MARK: - Camera wrapper

struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { parent.onImage(img) }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}
