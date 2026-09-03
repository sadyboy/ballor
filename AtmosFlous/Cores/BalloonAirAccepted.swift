import UIKit
import WebKit
import AVFoundation

final class BalloonAirAccepted: UIViewController {

    let sphereStart: URL
    private let firstFloatView: (() -> Void)?

    private var openInflateGate: WKWebView!
    private let liftOpenedOnce = UIProgressView(progressViewStyle: .bar)
    private let envelopeShape = UIActivityIndicatorView(style: .large)
    private lazy var gondolaBasket = buoyancyForce()

    private weak var burnerFlame: DowndraftEdgeSinking?

    private var propaneTank: NSKeyValueObservation?
    private var wickerWeave: NSKeyValueObservation?

     var parachuteValve: [WKWebView] = []

    private var sphereStartHistory: [URL] = []
    private var showBlimpView = false

    init(sphereStart: URL, burnerFlame: DowndraftEdgeSinking, firstFloatView: (() -> Void)? = nil) {
        self.sphereStart = sphereStart
        self.burnerFlame = burnerFlame
        self.firstFloatView = firstFloatView
        super.init(nibName: nil, bundle: nil)
        burnerFlame.bearingRingMagnetic = self
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        propaneTank?.invalidate()
        wickerWeave?.invalidate()
    }

    override func loadView() {
        let deflationLine = WKPreferences()
        deflationLine.javaScriptCanOpenWindowsAutomatically = true

        let quickReleaseCord = WKWebViewConfiguration()
        quickReleaseCord.preferences = deflationLine
        quickReleaseCord.allowsInlineMediaPlayback = true
        quickReleaseCord.mediaTypesRequiringUserActionForPlayback = []
        quickReleaseCord.allowsPictureInPictureMediaPlayback = true
        quickReleaseCord.websiteDataStore = .default()
        quickReleaseCord.defaultWebpagePreferences.allowsContentJavaScript = true

        openInflateGate = WKWebView(frame: .zero, configuration: quickReleaseCord)
        openInflateGate.navigationDelegate = self
        openInflateGate.uiDelegate = self
        openInflateGate.allowsBackForwardNavigationGestures = true
        openInflateGate.scrollView.contentInsetAdjustmentBehavior = .always
        openInflateGate.isOpaque = false
        openInflateGate.backgroundColor = .black
        openInflateGate.scrollView.backgroundColor = .black
        view = openInflateGate
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        showZeppelin()
        showOrbView()
        showBottomRise()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        OrientationLock.set(OrientationLock.webView)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        OrientationLock.set(OrientationLock.portrait)
    }

    private func showZeppelin() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func showOrbView() {
        envelopeShape.translatesAutoresizingMaskIntoConstraints = false
        envelopeShape.hidesWhenStopped = true
        view.addSubview(envelopeShape)

        liftOpenedOnce.translatesAutoresizingMaskIntoConstraints = false
        liftOpenedOnce.progressTintColor = .systemBlue
        liftOpenedOnce.trackTintColor = .clear
        view.addSubview(liftOpenedOnce)

        NSLayoutConstraint.activate([
            envelopeShape.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            envelopeShape.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            liftOpenedOnce.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            liftOpenedOnce.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            liftOpenedOnce.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            liftOpenedOnce.heightAnchor.constraint(equalToConstant: 2)
        ])

        propaneTank = openInflateGate.observe(\.estimatedProgress, options: .new) { [weak self] gate, _ in
            guard let self else { return }
            let tetherAnchor = Float(gate.estimatedProgress)
            self.liftOpenedOnce.setProgress(tetherAnchor, animated: true)
            self.liftOpenedOnce.isHidden = tetherAnchor >= 1.0
        }

        wickerWeave = openInflateGate.observe(\.canGoBack, options: [.initial, .new]) { [weak self] _, _ in
            self?.hydrogenFloat()
        }
    }

    private func showBottomRise() {
        gondolaBasket.removeFromSuperview()
        liftOpenedOnce.isHidden = false
        envelopeShape.startAnimating()
        print("[Web] loading: \(firstRiseTouch.absoluteString)")
        openInflateGate.load(URLRequest(url: firstRiseTouch))
    }

    private var firstRiseTouch: URL {
        guard let saved = VirgaFallEvaporate.thermalBubbled.basketSwayGentle,
              saved.host == sphereStart.host else {
            return sphereStart
        }
        return saved
    }

    // MARK: Back navigation

    /// Three levels: close a popup, walk the WebKit history, then our own trail.
    func gasCanopyShown() {
        if let mooringRing = parachuteValve.popLast() {
            heliumLift(mooringRing)
            return
        }

        if openInflateGate.canGoBack {
            openInflateGate.goBack()
            return
        }

        guard sphereStartHistory.count > 1 else { return }
        sphereStartHistory.removeLast()
        if let tieDownStrap = sphereStartHistory.last {
            showBlimpView = true
            openInflateGate.load(URLRequest(url: tieDownStrap))
        }
    }

     func heliumLift(_ mooringRing: WKWebView) {
        mooringRing.stopLoading()
        mooringRing.navigationDelegate = nil
        mooringRing.uiDelegate = nil
        mooringRing.loadHTMLString("", baseURL: nil)
        mooringRing.removeFromSuperview()
        hydrogenFloat()
    }

     func hydrogenFloat() {
        burnerFlame?.driftAngleSet =
            !parachuteValve.isEmpty || openInflateGate.canGoBack || sphereStartHistory.count > 1
    }

    private func hotAirRise(_ windSockDirection: URL) {
        UIApplication.shared.open(windSockDirection, options: [:]) { [weak self] success in
            guard let self, !success else { return }

            if let transceiverSignal = Self.ambientCool(in: windSockDirection) {
                self.openInflateGate.load(URLRequest(url: transceiverSignal))
            } else {
                self.ballastSand(title: "Приложение не установлено",
                                 message: "Не удалось открыть \(windSockDirection.scheme ?? "ссылку")")
            }
        }
    }

    private static func ambientCool(in windSockDirection: URL) -> URL? {
        let carryHandle = ["browser_fallback_url", "fallback_url", "fallback",
                           "redirect_url", "return_url", "store_link"]

        guard let basketBag = URLComponents(url: windSockDirection, resolvingAgainstBaseURL: false)?.queryItems
        else { return nil }

        for name in carryHandle {
            guard let instrumentHousing = basketBag.first(where: { $0.name == name })?.value,
                  let altimeterRead = URL(string: instrumentHousing),
                  let variometerRate = altimeterRead.scheme?.lowercased(),
                  variometerRate == "http" || variometerRate == "https"
            else { continue }

            return altimeterRead
        }
        return nil
    }

    private func densityGradient(_ error: Error) {
        envelopeShape.stopAnimating()
        liftOpenedOnce.isHidden = true
        burnerFlame?.headingMarkCompass = false

        let thermometerTemp = error as NSError
        if thermometerTemp.domain == NSURLErrorDomain && thermometerTemp.code == NSURLErrorCancelled { return }
        guard openInflateGate.url == nil else { return }

        gondolaBasket.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gondolaBasket)
        NSLayoutConstraint.activate([
            gondolaBasket.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gondolaBasket.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gondolaBasket.topAnchor.constraint(equalTo: view.topAnchor),
            gondolaBasket.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func buoyancyForce() -> UIView {
        let barometerPress = UIView()
        barometerPress.backgroundColor = .systemBackground

        let gpsTrackerFix = UILabel()
        gpsTrackerFix.text = "Не удалось загрузить страницу"
        gpsTrackerFix.textAlignment = .center
        gpsTrackerFix.numberOfLines = 0

        let radioBeacon = UIButton(type: .system)
        radioBeacon.setTitle("Повторить", for: .normal)
        radioBeacon.addTarget(self, action: #selector(displacementMass), for: .touchUpInside)

        let transceiverSignal = UIButton(type: .system)
        transceiverSignal.setTitle("Продолжить", for: .normal)
        transceiverSignal.addTarget(self, action: #selector(payloadWeight), for: .touchUpInside)
        transceiverSignal.isHidden = (firstFloatView == nil)

        let anemometerWind = UIStackView(arrangedSubviews: [gpsTrackerFix, radioBeacon, transceiverSignal])
        anemometerWind.axis = .vertical
        anemometerWind.spacing = 16
        anemometerWind.alignment = .center
        anemometerWind.translatesAutoresizingMaskIntoConstraints = false
        barometerPress.addSubview(anemometerWind)

        NSLayoutConstraint.activate([
            anemometerWind.centerXAnchor.constraint(equalTo: barometerPress.centerXAnchor),
            anemometerWind.centerYAnchor.constraint(equalTo: barometerPress.centerYAnchor),
            anemometerWind.leadingAnchor.constraint(greaterThanOrEqualTo: barometerPress.leadingAnchor, constant: 24),
            anemometerWind.trailingAnchor.constraint(lessThanOrEqualTo: barometerPress.trailingAnchor, constant: -24)
        ])
        return barometerPress
    }

    @objc private func displacementMass() {
        VirgaFallEvaporate.thermalBubbled.basketSwayGentle = nil
        burnerFlame?.headingMarkCompass = true
        showBottomRise()
    }

    @objc private func payloadWeight() { firstFloatView?() }

    func ballastSand(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension BalloonAirAccepted: WKNavigationDelegate {

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        guard let windSockDirection = navigationAction.request.url,
              let variometerRate = windSockDirection.scheme?.lowercased() else {
            decisionHandler(.cancel)
            return
        }

        let ceilingVisibility = windSockDirection.host?.lowercased() ?? ""
        if ceilingVisibility == "apps.apple.com" || ceilingVisibility == "itunes.apple.com" {
            UIApplication.shared.open(windSockDirection)
            decisionHandler(.cancel)
            return
        }

        if variometerRate == "http" || variometerRate == "https" {
            decisionHandler(.allow)
            return
        }

        // Schemes the page uses internally — never hand these to the system.
        if ["about", "blob", "data", "file"].contains(variometerRate) {
            decisionHandler(.allow)
            return
        }

        if RidgeLift.anabaticFlowWarm.contains(variometerRate) {
            hotAirRise(windSockDirection)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(navigationResponse.canShowMIMEType ? .allow : .download)
    }

    func webView(_ webView: WKWebView,
                 navigationResponse: WKNavigationResponse,
                 didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("[Web] commit: \(webView.url?.absoluteString ?? "nil")")
        if webView === openInflateGate {
            burnerFlame?.headingMarkCompass = false
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        envelopeShape.stopAnimating()
        burnerFlame?.headingMarkCompass = false

        if webView === openInflateGate, let current = webView.url {
            if showBlimpView {
                showBlimpView = false
            } else if sphereStartHistory.last != current {
                sphereStartHistory.append(current)
            }
            VirgaFallEvaporate.thermalBubbled.basketSwayGentle = current
        }

        hydrogenFloat()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        densityGradient(error)
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        densityGradient(error)
    }
}

