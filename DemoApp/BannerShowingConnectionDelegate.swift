//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

final class BannerShowingConnectionDelegate {
    // MARK: - Private Properties
    
    private let navigationController: UINavigationController
    private var connectionEstablishmentTime: Date?
    
    // MARK: -
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
}

// MARK: - ChatConnectionControllerDelegate

extension BannerShowingConnectionDelegate: ChatConnectionControllerDelegate {
    public func connectionController(_ controller: ChatConnectionController, didUpdateConnectionStatus status: ConnectionStatus) {
        switch status {
        case .connected:
            connectionEstablishmentTime = Date()
        case .disconnecting:
            break
        case .connecting:
            if let time = connectionEstablishmentTime {
                let elapsedTime = time.distance(to: Date())
                if elapsedTime > 5 {
                    // TODO: We need to reset the property we make desicion on whether to show the banner or not
                    showBanner()
                }
            }
        case .disconnected, .initialized:
            break
        }
    }
}

// MARK: - Private Methods

private extension BannerShowingConnectionDelegate {
    func showBanner() {
        guard let view = navigationController.topViewController?.view else { return }
        let bannerView = BannerView()
        view.addSubview(bannerView)
        bannerView.alpha = 0
        bannerView.update(text: "Reconnecting...")
        
        UIView.animate(withDuration: 0.5) {
            bannerView.alpha = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            UIView.animate(withDuration: 1) {
                bannerView.alpha = 0
            } completion: { _ in
                bannerView.removeFromSuperview()
            }
        }
        
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate(
            [
                bannerView.topAnchor.constraint(equalTo: guide.topAnchor)
            ]
        )
    }
}
