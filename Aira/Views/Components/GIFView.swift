import SwiftUI
import WebKit

struct GIFView: UIViewRepresentable {
    let gifName: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .clear
        webView.isOpaque = false
        //if gif doesnt display check if extension is GIF or gif
        if let path = Bundle.main.path(forResource: gifName, ofType: "gif"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            webView.load(data,
                         mimeType: "image/gif",
                         characterEncodingName: "UTF-8",
                         baseURL: URL(fileURLWithPath: path).deletingLastPathComponent())
        } else {
            print("❌ Failed to load GIF named \(gifName).gif")
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
