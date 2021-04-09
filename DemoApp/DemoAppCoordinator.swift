//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class DemoAppCoordinator {
    static var shared: DemoAppCoordinator!
    
    private var connectionController: ChatConnectionController?
    private let navigationController: UINavigationController
    private let connectionDelegate: BannerShowingConnectionDelegate
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        connectionDelegate = BannerShowingConnectionDelegate(
            navigationController: navigationController
        )
    }
    
    func presentChat(userCredentials: UserCredentials) {
        LogConfig.level = .error
        
        // Create a token
        let token = try! Token(rawValue: userCredentials.token)
        
        // Create client
        let config = ChatClientConfig(apiKey: .init(userCredentials.apiKey))
        let client = ChatClient(config: config, tokenProvider: .static(token))
        
        // Config
        UIConfig.default.navigation.channelListRouter = DemoChatChannelListRouter.self
        
        // Channels with the current user
        let controller = client.channelListController(query: .init(filter: .containMembers(userIds: [userCredentials.id])))
        let chatList = ChatChannelListVC()
        chatList.controller = controller
        
        connectionController = client.connectionController()
        connectionController?.delegate = connectionDelegate
        
        navigationController.viewControllers = [chatList]
        navigationController.isNavigationBarHidden = false
        
        let window = navigationController.view.window!
        
        UIView.transition(with: window, duration: 0.3, options: .transitionFlipFromRight, animations: {
            window.rootViewController = self.navigationController
        })
    }
}
