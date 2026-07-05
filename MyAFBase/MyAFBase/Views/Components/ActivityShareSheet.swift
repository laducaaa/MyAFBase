import SwiftUI

/// Thin wrapper so on-demand share sheets (e.g. after generating a file)
/// can be presented from a regular button, not just a `ShareLink` tap.
struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
