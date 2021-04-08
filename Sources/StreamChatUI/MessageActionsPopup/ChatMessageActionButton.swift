//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Button for action displayed in `_ChatMessageActionsView`
public typealias ChatMessageActionButton = _ChatMessageActionButton<NoExtraData>

/// Button for action displayed in `_ChatMessageActionsView`
open class _ChatMessageActionButton<ExtraData: ExtraDataTypes>: _Button, UIConfigProvider {
    /// The data this view component shows.
    public var content: ChatMessageActionItem? {
        didSet { updateContentIfNeeded() }
    }

    override public func defaultAppearance() {
        super.defaultAppearance()
        backgroundColor = uiConfig.colorPalette.background
        titleLabel?.font = uiConfig.font.body
        titleLabel?.adjustsFontForContentSizeCategory = true
        contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 32)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: -16)
        contentHorizontalAlignment = .left
    }

    override open func setUp() {
        super.setUp()
        
        addTarget(self, action: #selector(touchUpInsideHandler(_:)), for: .touchUpInside)
    }

    override open func tintColorDidChange() {
        super.tintColorDidChange()
        
        updateContentIfNeeded()
    }
    
    override open func updateContent() {
        let imageTintСolor: UIColor
        let titleTextColor: UIColor

        if content?.isDestructive == true {
            imageTintСolor = uiConfig.colorPalette.alert
            titleTextColor = imageTintСolor
        } else {
            imageTintСolor = content?.isPrimary == true ? tintColor : uiConfig.colorPalette.inactiveTint
            titleTextColor = uiConfig.colorPalette.text
        }

        setImage(content?.icon.tinted(with: imageTintСolor), for: .normal)
        setTitle(content?.title, for: .normal)
        setTitleColor(titleTextColor, for: .normal)
    }
    
    /// Triggered when `_ChatMessageActionButton` is tapped
    @objc open func touchUpInsideHandler(_ sender: Any) {
        guard let content = content else { return assertionFailure("Content is unexpectedly nil") }
        content.action(content)
    }
}
