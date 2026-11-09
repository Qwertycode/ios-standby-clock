import UIKit
import WebKit

/// Full-screen web view that shows the bundled clock (web/index.html).
/// Being a native view controller is what lets the app hide the home indicator.
final class ClockViewController: UIViewController, WKNavigationDelegate {
    private var webView: WKWebView!

    /// The page checks these to decide whether it's running as an "app" and whether
    /// it has a screen wake lock. The app keeps the screen on natively, so report
    /// both as available.
    private static let shim = """
    try { Object.defineProperty(navigator, 'standalone', { get: () => true }); } catch (e) {}
    try {
      const lock = { released: false, type: 'screen', addEventListener() {}, removeEventListener() {}, release: async () => {} };
      Object.defineProperty(navigator, 'wakeLock', { get: () => ({ request: async () => lock }) });
    } catch (e) {}
    """

    // Fades the home bar out a few seconds after the last touch.
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var prefersStatusBarHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(
            WKUserScript(source: Self.shim, injectionTime: .atDocumentStart, forMainFrameOnly: true))

        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = .black
        web.scrollView.backgroundColor = .black
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.scrollView.isScrollEnabled = false
        web.scrollView.bounces = false
        web.navigationDelegate = self
        webView = web
        view = web
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let index = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "web") else {
            return
        }
        webView.loadFileURL(index, allowingReadAccessTo: index.deletingLastPathComponent())
    }

    // If iOS kills the web content process (e.g. under memory pressure), reload instead of showing a blank screen.
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }
}
