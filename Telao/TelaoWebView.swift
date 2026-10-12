import SwiftUI
import WebKit

/// O Telão rodando num WKWebView.
/// - Janelas novas (os anúncios que os players abrem ao tocar no play) são bloqueadas.
/// - A página principal nunca sai do devlumo.com.br: redirecionamento de anúncio é cancelado.
///   Os players continuam livres dentro dos iframes.
/// - Vídeo em linha, tela cheia de elemento e picture-in-picture ligados.
struct TelaoWebView: UIViewRepresentable {
    static let endereco = URL(string: "https://devlumo.com.br/telao/")!
    static let hostPermitido = "devlumo.com.br"

    @Binding var carregou: Bool
    @Binding var semRede: Bool
    var recarregar: Int

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.isElementFullscreenEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        // iPad pede a versão "computador" dos sites por padrão; o Telão tem layout próprio para tablet
        config.defaultWebpagePreferences.preferredContentMode = .mobile
        config.applicationNameForUserAgent = "Version/26.0 Mobile/15E148 Safari/604.1 TelaoApp/1.0"

        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.uiDelegate = context.coordinator
        web.isOpaque = false
        web.backgroundColor = UIColor(red: 0.078, green: 0.078, blue: 0.078, alpha: 1)
        web.scrollView.backgroundColor = web.backgroundColor
        // O site cuida das áreas seguras (viewport-fit=cover + env(safe-area-inset-*))
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.allowsBackForwardNavigationGestures = true
        web.allowsLinkPreview = false

        let refresh = UIRefreshControl()
        refresh.tintColor = .white
        refresh.addTarget(context.coordinator, action: #selector(Coordinator.puxouParaAtualizar(_:)), for: .valueChanged)
        web.scrollView.refreshControl = refresh

        context.coordinator.ultimoRecarregar = recarregar
        web.load(URLRequest(url: Self.endereco))
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        if recarregar != context.coordinator.ultimoRecarregar {
            context.coordinator.ultimoRecarregar = recarregar
            web.load(URLRequest(url: Self.endereco))
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let pai: TelaoWebView
        var ultimoRecarregar = 0

        init(_ pai: TelaoWebView) { self.pai = pai }

        @objc func puxouParaAtualizar(_ controle: UIRefreshControl) {
            (controle.superview?.superview as? WKWebView)?.reload()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { controle.endRefreshing() }
        }

        // MARK: Navegação

        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = action.request.url else { return decisionHandler(.cancel) }
            // Dentro dos iframes (os players) tudo é permitido
            guard action.targetFrame?.isMainFrame ?? false else { return decisionHandler(.allow) }
            if url.scheme == "about" || url.scheme == "blob" || url.scheme == "data" { return decisionHandler(.allow) }
            if let host = url.host, host == Self.hostPermitidoValor || host.hasSuffix("." + Self.hostPermitidoValor) {
                return decisionHandler(.allow)
            }
            // Um anúncio tentou trocar a página inteira: fica no Telão
            decisionHandler(.cancel)
        }

        private static var hostPermitidoValor: String { TelaoWebView.hostPermitido }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.pai.semRede = false
                self.pai.carregou = true
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            falhou(error)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            falhou(error)
        }

        private func falhou(_ error: Error) {
            let codigo = (error as NSError).code
            // Navegação cancelada por nós (anúncio bloqueado) não é erro
            guard codigo != NSURLErrorCancelled, codigo != 102 else { return }
            DispatchQueue.main.async {
                if !self.pai.carregou { self.pai.semRede = true }
            }
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            webView.reload()
        }

        // MARK: Janelas novas e diálogos

        /// window.open / target=_blank: anúncios. Nunca abre janela nova.
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            nil
        }

        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            // Alertas só da própria página (os players usam alerta para empurrar anúncio)
            guard frame.isMainFrame, let vc = Self.topo() else { return completionHandler() }
            let alerta = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
            vc.present(alerta, animated: true)
        }

        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            guard frame.isMainFrame, let vc = Self.topo() else { return completionHandler(false) }
            let alerta = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "Cancelar", style: .cancel) { _ in completionHandler(false) })
            alerta.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
            vc.present(alerta, animated: true)
        }

        private static func topo() -> UIViewController? {
            let cena = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
            var vc = cena?.keyWindow?.rootViewController
            while let apresentado = vc?.presentedViewController { vc = apresentado }
            return vc
        }
    }
}
