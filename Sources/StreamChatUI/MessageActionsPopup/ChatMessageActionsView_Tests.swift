//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChatMessageActionsView_Tests: XCTestCase {
    struct TestChatMessageActionItem: ChatMessageActionItem {
        let title: String
        let icon: UIImage
        let isDestructive: Bool = false
        let isPrimary: Bool = false
        let action: (ChatMessageActionItem) -> Void = { _ in }
    }

    private var content: [TestChatMessageActionItem]!
    
    override func setUp() {
        super.setUp()
        
        content = [
            TestChatMessageActionItem(
                title: "Action 1",
                icon: UIImage(named: "icn_inline_reply", in: .streamChatUI)!
            ),
            TestChatMessageActionItem(
                title: "Action 2",
                icon: UIImage(named: "icn_thread_reply", in: .streamChatUI)!
            )
        ]
    }
    
    override func tearDown() {
        content = nil
        
        super.tearDown()
    }
    
    func test_emptyState() {
        let view = ChatMessageActionsView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 50)
        ])
        view.content = content
        view.content = []
        AssertSnapshot(view)
    }
    
    func test_defaultAppearance() {
        let view = ChatMessageActionsView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.content = content
        AssertSnapshot(view)
    }
    
    func test_appearanceCustomization_usingUIConfig() {
        var config = UIConfig()
        config.colorPalette.border = .red
        
        let view = ChatMessageActionsView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.content = content
        view.uiConfig = config
        
        AssertSnapshot(view)
    }
    
    func test_appearanceCustomization_usingAppearanceHook() {
        class TestView: ChatMessageActionsView {}
        TestView.defaultAppearance {
            $0.stackView.spacing = 10
            $0.backgroundColor = .cyan
        }
        
        let view = TestView().withoutAutoresizingMaskConstraints
        
        view.addSizeConstraints()
        
        view.content = content
        AssertSnapshot(view)
    }
    
    func test_appearanceCustomization_usingSubclassing() {
        class TestActionButton: ChatMessageActionButton {}
        class TestView: ChatMessageActionsView {
            override var actionButtonClass: _ChatMessageActionButton<NoExtraData>.Type { TestActionButton.self }
            
            override func setUpAppearance() {
                super.setUpAppearance()
                stackView.spacing = 10
                backgroundColor = .cyan
                layer.cornerRadius = 0
            }
        }
        
        let view = TestView().withoutAutoresizingMaskConstraints
        
        view.addSizeConstraints()
        
        view.content = content
        AssertSnapshot(view)
        XCTAssert(view.stackView.arrangedSubviews.allSatisfy { $0 is TestActionButton })
    }
}

private extension ChatMessageActionsView {
    func addSizeConstraints() {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 200)
        ])
    }
}
