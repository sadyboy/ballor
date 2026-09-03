import UIKit

enum OrientationLock {

    static let portrait: UIInterfaceOrientationMask = .portrait
    static let webView: UIInterfaceOrientationMask = [.portrait, .landscapeLeft, .landscapeRight]
    private(set) static var mask: UIInterfaceOrientationMask = portrait
    static func set(_ new: UIInterfaceOrientationMask) {
        guard mask != new else { return }
        mask = new

        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else { return }

        if #available(iOS 16.0, *) {
            scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: new)) {
                print("[Orientation] geometry update failed: \($0)")
            }
        } else {
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
}
