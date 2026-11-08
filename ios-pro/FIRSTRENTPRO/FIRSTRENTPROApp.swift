import SwiftUI
import WebKit

private let startURL = URL(string: "https://first-rent.vercel.app/admin.html?app=1")!

@main
struct FIRSTRENTPROApp: App {
  var body: some Scene {
    WindowGroup {
      WebScreen()
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
  }
}

struct WebScreen: View {
  @State private var ready = false
  @State private var failed = false

  var body: some View {
    ZStack {
      SiteWebView(url: startURL, ready: $ready, failed: $failed)
      if !ready {
        Splash(failed: failed) {
          failed = false
          NotificationCenter.default.post(name: .frReload, object: nil)
        }
      }
    }
    .background(Color.black)
  }
}

struct Splash: View {
  let failed: Bool
  let retry: () -> Void

  var body: some View {
    VStack(spacing: 22) {
      Image("LaunchLogo")
        .resizable()
        .scaledToFit()
        .frame(width: 120, height: 120)
      VStack(spacing: 8) {
        Text("FIRST RENT")
          .font(.system(size: 14, weight: .semibold))
          .tracking(3)
          .foregroundStyle(Color(red: 196 / 255, green: 167 / 255, blue: 106 / 255))
        Text("PRO")
          .font(.system(size: 10, weight: .semibold))
          .tracking(3)
          .foregroundStyle(.white)
      }
      if failed {
        Button("Réessayer", action: retry)
          .buttonStyle(.borderedProminent)
          .tint(.white)
          .foregroundStyle(.black)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
  }
}

struct SiteWebView: UIViewRepresentable {
  let url: URL
  @Binding var ready: Bool
  @Binding var failed: Bool

  func makeCoordinator() -> Coordinator {
    Coordinator(ready: $ready, failed: $failed)
  }

  func makeUIView(context: Context) -> WKWebView {
    let config = WKWebViewConfiguration()
    config.allowsInlineMediaPlayback = true
    config.mediaTypesRequiringUserActionForPlayback = []
    let view = WKWebView(frame: .zero, configuration: config)
    view.navigationDelegate = context.coordinator
    view.uiDelegate = context.coordinator
    view.isOpaque = false
    view.backgroundColor = .black
    view.scrollView.backgroundColor = .black
    view.scrollView.contentInsetAdjustmentBehavior = .never
    context.coordinator.webView = view
    view.load(URLRequest(url: url))
    return view
  }

  func updateUIView(_ uiView: WKWebView, context: Context) {}

  final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    @Binding var ready: Bool
    @Binding var failed: Bool
    weak var webView: WKWebView?
    private var observer: NSObjectProtocol?

    init(ready: Binding<Bool>, failed: Binding<Bool>) {
      _ready = ready
      _failed = failed
      super.init()
      observer = NotificationCenter.default.addObserver(forName: .frReload, object: nil, queue: .main) { [weak self] _ in
        self?.webView?.load(URLRequest(url: startURL))
      }
    }

    deinit {
      if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      ready = true
      failed = false
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
      failed = true
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
      failed = true
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
      guard let url = navigationAction.request.url else {
        decisionHandler(.allow)
        return
      }
      let scheme = url.scheme?.lowercased() ?? ""
      if ["tel", "mailto", "whatsapp", "sms"].contains(scheme) {
        UIApplication.shared.open(url)
        decisionHandler(.cancel)
        return
      }
      if navigationAction.targetFrame == nil {
        webView.load(URLRequest(url: url))
        decisionHandler(.cancel)
        return
      }
      decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
      if let url = navigationAction.request.url {
        webView.load(URLRequest(url: url))
      }
      return nil
    }

    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
      decisionHandler(.grant)
    }
  }
}

extension Notification.Name {
  static let frReload = Notification.Name("frReload")
}
