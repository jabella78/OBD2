import SwiftUI

#if os(iOS)
import UIKit

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

struct ExportHelper {
    static func shareURL(_ url: URL, onPresentiOS: @escaping (URL) -> Void) {
        #if os(iOS)
        onPresentiOS(url)
        #elseif os(macOS)
        // Su macOS apre direttamente il file generato (es. Anteprima/Finder per PDF o foglio di calcolo per CSV)
        NSWorkspace.shared.open(url)
        #endif
    }
}
