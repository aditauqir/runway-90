import SwiftUI
import Photos

/// Generates and saves realistic-looking synthetic financial documents to the
/// photo library so they can be picked during the demo. All documents are
/// clearly marked FICTIONAL / SYNTHETIC. None contain real data.
///
/// Documents generated:
/// 1. Collection letter (Northstar Collections, account 4471, $2,310)
/// 2. Bank statement (Peachtree Federal CU, checking ****8802)
/// 3. Credit bureau notice (TransUnion dispute acknowledgement)
enum SyntheticDocuments {

    /// Save all 3 sample documents to the photo library.
    /// Returns the number of documents saved successfully.
    @MainActor
    static func saveAllToPhotos() async -> Int {
        let docs: [UIImage?] = [
            renderCollectionLetter(),
            renderBankStatement(),
            renderCreditNotice()
        ]
        var saved = 0
        for img in docs.compactMap({ $0 }) {
            if await saveToPhotos(img) { saved += 1 }
        }
        return saved
    }

    /// Request photo library write permission.
    static func requestAccess() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        return status == .authorized || status == .limited
    }

    private static func saveToPhotos(_ image: UIImage) async -> Bool {
        await withCheckedContinuation { cont in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, _ in
                cont.resume(returning: success)
            }
        }
    }

    // MARK: - Document 1: Collection Letter

    @MainActor
    static func renderCollectionLetter() -> UIImage? {
        let view = CollectionLetterDoc().frame(width: 380, height: 540)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        return renderer.uiImage
    }

    // MARK: - Document 2: Bank Statement

    @MainActor
    static func renderBankStatement() -> UIImage? {
        let view = BankStatementDoc().frame(width: 380, height: 600)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        return renderer.uiImage
    }

    // MARK: - Document 3: Credit Bureau Notice

    @MainActor
    static func renderCreditNotice() -> UIImage? {
        let view = CreditNoticeDoc().frame(width: 380, height: 520)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        return renderer.uiImage
    }
}

// MARK: - Document Views (rendered to images, not displayed in the app)

private let docBg = Color(hex: 0xF5F0E8)
private let docText = Color.black.opacity(0.85)
private let fictionalBadge = Color.red.opacity(0.85)

private struct FictionalBadge: View {
    var body: some View {
        Text("FICTIONAL")
            .font(.caption2.weight(.heavy))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(fictionalBadge, in: Capsule())
            .foregroundStyle(.white)
    }
}

private struct DocDisclaimer: View {
    var body: some View {
        Text("SYNTHETIC DEMO DOCUMENT — not a real debt, company, person, or account")
            .font(.system(size: 8, weight: .semibold))
            .foregroundStyle(Color.red.opacity(0.8))
    }
}

// Document 1
private struct CollectionLetterDoc: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("NORTHSTAR COLLECTIONS")
                    .font(.system(.subheadline, design: .serif).weight(.bold))
                Spacer()
                FictionalBadge()
            }
            Text("P.O. Box 19042 · Atlanta, GA 30325 · (555) 012-0000")
                .font(.system(size: 9, design: .serif))
                .foregroundStyle(docText.opacity(0.6))
            Divider().background(Color.black.opacity(0.3))

            Text("September 3, 2024").font(.system(size: 10, design: .serif))
            Text("RE: Outstanding balance — account ending 4471")
                .font(.system(.footnote, design: .serif).weight(.semibold))

            Text("""
            Dear Account Holder,

            Our records indicate an outstanding balance of $2,310.00 on the \
            account referenced above, originally opened March 2024. \
            This amount remains unpaid and has been referred to our office \
            for collection.

            Please contact our office at (555) 012-0000 within 30 days to \
            discuss resolution options. You have the right to dispute this \
            debt in writing within 30 days of receiving this notice.

            Sincerely,
            Northstar Collections — Recovery Department
            """)
            .font(.system(size: 11, design: .serif))

            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Amount due: $2,310.00").font(.system(size: 11, design: .serif).weight(.bold))
                    Text("Account opened: March 2024").font(.system(size: 10, design: .serif))
                    Text("Reference: NSC-4471-DEMO").font(.system(size: 9, design: .serif))
                }
                Spacer()
            }
            Spacer()
            DocDisclaimer()
        }
        .foregroundStyle(docText)
        .padding(16)
        .background(docBg)
    }
}

// Document 2
private struct BankStatementDoc: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PEACHTREE FEDERAL CREDIT UNION")
                        .font(.system(.subheadline, design: .serif).weight(.bold))
                    Text("Monthly Statement · September 2024")
                        .font(.system(size: 10, design: .serif))
                        .foregroundStyle(docText.opacity(0.6))
                }
                Spacer()
                FictionalBadge()
            }
            Divider()

            Text("Account: Checking ····8802")
                .font(.system(size: 11, design: .serif).weight(.semibold))
            Text("Statement Period: 09/01/2024 — 09/30/2024")
                .font(.system(size: 10, design: .serif))

            VStack(alignment: .leading, spacing: 2) {
                Text("Account Summary").font(.system(size: 11, design: .serif).weight(.bold))
                summaryLine("Beginning Balance", "$1,204.33")
                summaryLine("Total Deposits", "$1,480.00")
                summaryLine("Total Withdrawals", "–$2,134.67")
                Divider()
                summaryLine("Ending Balance", "$549.66")
            }
            .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 2) {
                Text("Recent Transactions").font(.system(size: 11, design: .serif).weight(.bold))
                txnLine("09/01", "Paycheck — Midtown Clinic", "+$1,480.00")
                txnLine("09/03", "Peachtree Flats (rent)", "–$1,150.00")
                txnLine("09/05", "MARTA transit pass", "–$68.50")
                txnLine("09/08", "Kroger grocery", "–$47.22")
                txnLine("09/11", "Walgreens pharmacy", "–$23.45")
                txnLine("09/14", "Unknown — online payment ????", "–$412.00")
                txnLine("09/18", "Metro PCS phone", "–$55.00")
                txnLine("09/22", "Target household", "–$38.50")
                txnLine("09/28", "ATM withdrawal — Peachtree Ctr", "–$340.00")
            }
            .padding(.vertical, 4)

            Text("? = Transaction the account holder may not recognize.")
                .font(.system(size: 9, design: .serif))
                .foregroundStyle(Color.orange.opacity(0.9))

            Spacer()
            DocDisclaimer()
        }
        .foregroundStyle(docText)
        .padding(16)
        .background(docBg)
    }

    private func summaryLine(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 10, design: .serif))
            Spacer()
            Text(value).font(.system(size: 10, design: .serif).weight(.medium))
        }
    }

    private func txnLine(_ date: String, _ desc: String, _ amount: String) -> some View {
        HStack {
            Text(date).font(.system(size: 9, design: .serif)).frame(width: 36, alignment: .leading)
            Text(desc).font(.system(size: 9, design: .serif)).lineLimit(1)
            Spacer()
            Text(amount)
                .font(.system(size: 9, design: .serif).weight(.medium))
                .foregroundStyle(amount.hasPrefix("–") ? Color.red.opacity(0.8) : docText)
        }
    }
}

// Document 3
private struct CreditNoticeDoc: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TRANSUNION")
                    .font(.system(.subheadline, design: .serif).weight(.bold))
                Spacer()
                FictionalBadge()
            }
            Text("Consumer Relations · P.O. Box 20000 · Chester, PA 19016")
                .font(.system(size: 9, design: .serif))
                .foregroundStyle(docText.opacity(0.6))
            Divider()

            Text("October 1, 2024").font(.system(size: 10, design: .serif))
            Text("RE: Dispute Acknowledgement — File #TU-DEMO-7734")
                .font(.system(.footnote, design: .serif).weight(.semibold))

            Text("""
            Dear Consumer,

            We received your dispute regarding the following item(s) on \
            your credit report. We are required to investigate your dispute \
            within 30 days under the Fair Credit Reporting Act.

            Disputed item(s):

            1. Northstar Collections — Account ····4471
               Reported balance: $2,310.00
               Status: In dispute — investigation pending

            2. Creditline Plus — Account ····5509
               Reported balance: $875.00
               Status: In dispute — investigation pending

            You will receive the results of our investigation by mail. \
            Your credit report has been updated to reflect the disputed \
            status of these items.

            For questions, contact us at (800) 916-0000 or visit \
            transunion.com/dispute (DEMO).

            Sincerely,
            TransUnion Consumer Relations
            """)
            .font(.system(size: 11, design: .serif))

            Spacer()
            DocDisclaimer()
        }
        .foregroundStyle(docText)
        .padding(16)
        .background(docBg)
    }
}
