//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

/// A view that displays the avatar image. By default a circular image.
open class ChatAvatarView: _View {
    /// The `UIImageView` instance that shows the avatar image.
    open private(set) var imageView: UIImageView = UIImageView().withoutAutoresizingMaskConstraints
    
    override open var intrinsicContentSize: CGSize {
        imageView.image?.size ?? super.intrinsicContentSize
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = min(imageView.bounds.width, imageView.bounds.height) / 2
    }

    override public func defaultAppearance() {
        super.defaultAppearance()
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }

    override open func setUpLayout() {
        embed(imageView)
    }
}
