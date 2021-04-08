//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChatMessageActionButton_Tests: XCTestCase {
    struct TestChatMessageActionItem: ChatMessageActionItem {
        let title: String
        let icon: UIImage
        let isDestructive: Bool
        let isPrimary: Bool
        let action: (ChatMessageActionItem) -> Void = { _ in }
        
        init(
            title: String,
            icon: UIImage,
            isDestructive: Bool = false,
            isPrimary: Bool = false
        ) {
            self.title = title
            self.icon = icon
            self.isDestructive = isDestructive
            self.isPrimary = isPrimary
        }
    }
    
    private var content: TestChatMessageActionItem!
    
    override func setUp() {
        super.setUp()
        
        content = TestChatMessageActionItem(
            title: "Action 1",
            icon: UIImage(named: "icn_inline_reply", in: .streamChatUI)!
        )
    }
    
    override func tearDown() {
        content = nil
        
        super.tearDown()
    }

    func test_emptyState() {
        let view = ChatMessageActionButton().withoutAutoresizingMaskConstraints
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 50)
        ])
        view.content = content
        view.content = TestChatMessageActionItem(title: "", icon: UIImage())
        AssertSnapshot(view)
    }
    
    func test_defaultAppearance() {
        let view = ChatMessageActionButton()
        view.content = content
        AssertSnapshot(view)
    }

    func test_defaultAppearance_whenDestructive() {
        let view = ChatMessageActionButton()
        view.content = TestChatMessageActionItem(
            title: "Action 1",
            icon: UIImage(named: "icn_inline_reply", in: .streamChatUI)!,
            isDestructive: true
        )
        
        AssertSnapshot(view)
    }
    
    func test_defaultAppearance_whenPrimary() {
        let view = ChatMessageActionButton()
        view.content = TestChatMessageActionItem(
            title: "Action 1",
            icon: UIImage(named: "icn_inline_reply", in: .streamChatUI)!,
            isPrimary: true
        )
        
        AssertSnapshot(view)
    }
    
    func test_defaultAppearance_whenPrimaryAndDestructive() {
        let view = ChatMessageActionButton()
        view.content = TestChatMessageActionItem(
            title: "Action 1",
            icon: UIImage(named: "icn_inline_reply", in: .streamChatUI)!,
            isDestructive: true,
            isPrimary: true
        )
        
        AssertSnapshot(view)
    }
    
    func test_appearanceCustomization_usingUIConfig() {
        var config = UIConfig()
        config.colorPalette.text = .blue
        
        let view = ChatMessageActionButton()
        view.content = content
        view.uiConfig = config
        
        AssertSnapshot(view)
    }
    
    func test_appearanceCustomization_usingAppearanceHook() {
        class TestView: ChatMessageActionButton {}
        TestView.defaultAppearance {
            $0.backgroundColor = .cyan
        }

        let view = TestView()

        view.content = content
        AssertSnapshot(view)
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatMessageActionButton {
            override func setUpAppearance() {
                super.setUpAppearance()
                backgroundColor = .cyan
            }
            
            override func updateContent() {
                super.updateContent()
                
                setTitleColor(.red, for: .normal)
            }
        }

        let view = TestView()

        view.content = content
        AssertSnapshot(view)
    }
}
