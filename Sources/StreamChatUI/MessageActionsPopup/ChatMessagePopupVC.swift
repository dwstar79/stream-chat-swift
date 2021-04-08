//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// `_ChatMessagePopupVC` is shown when user long-presses a message
/// By default, it has a blurred background, reactions, and actions which are shown for a given message
/// and with which user can interact
public typealias ChatMessagePopupVC = _ChatMessagePopupVC<NoExtraData>

/// `_ChatMessagePopupVC` is shown when user long-presses a message
/// By default, it has a blurred background, reactions, and actions which are shown for a given message
/// and with which user can interact
open class _ChatMessagePopupVC<ExtraData: ExtraDataTypes>: _ViewController, UIConfigProvider {
    /// `UIScrollView` for showing content and updating its position via setting its content offset
    open private(set) lazy var scrollView = UIScrollView()
        .withoutAutoresizingMaskConstraints
    /// `UIView` embedded in `scrollView`
    open private(set) lazy var scrollContentView = UIView()
        .withoutAutoresizingMaskConstraints
    /// `contentView` encapsulating underlying views `reactionsController`, `actionsController` and `messageContentView`
    open private(set) lazy var contentView = UIView()
        .withoutAutoresizingMaskConstraints
    /// `UIView` with `UIBlurEffect` that is shown as a background
    open private(set) lazy var blurView: UIView = {
        let blur: UIBlurEffect
        if #available(iOS 13.0, *) {
            blur = UIBlurEffect(style: .systemUltraThinMaterial)
        } else {
            blur = UIBlurEffect(style: .regular)
        }
        return UIVisualEffectView(effect: blur)
            .withoutAutoresizingMaskConstraints
    }()

    /// New instance of `messageContentViewClass` that is populated with `message` data
    open private(set) lazy var messageContentView = messageContentViewClass.init()
        .withoutAutoresizingMaskConstraints

    /// `messageContentView` class that is populated with `message` and shown
    public var messageContentViewClass: _ChatMessageContentView<ExtraData>.Type!
    /// Message data that is shown
    public var message: _ChatMessageGroupPart<ExtraData>!
    /// Initial frame of a message
    public var messageViewFrame: CGRect!
    /// `_ChatMessageActionsVC` instance for showing actions
    public var actionsController: _ChatMessageActionsVC<ExtraData>!
    /// `_ChatMessageReactionsVC` instance for showing reactions.
    public var reactionsController: _ChatMessageReactionsVC<ExtraData>?
    
    /// Spacing between reactions, message, and actions
    public var spacing: CGFloat = 8
    
    /// Layout properties of this view
    public private(set) var layout = Layout()
    
    /// Properties tied to `_ChatMessagePopupVC` layout
    public struct Layout {
        /// Constraints of `reactionsController.view`
        public fileprivate(set) var reactionsViewConstraints: [NSLayoutConstraint] = []
        /// Constraints of `actionsController.view`
        public fileprivate(set) var actionsViewConstraints: [NSLayoutConstraint] = []
        /// Constraints of `messageContentView`
        public fileprivate(set) var messageContentViewConstraints: [NSLayoutConstraint] = []
    }

    override open func setUp() {
        super.setUp()
        
        scrollView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapOnOverlay)))
        scrollView.contentInsetAdjustmentBehavior = .always
        scrollView.isScrollEnabled = false
    }

    override public func defaultAppearance() {
        super.defaultAppearance()
        view.backgroundColor = .clear
    }

    override open func setUpLayout() {
        if let reactionsController = reactionsController {
            reactionsController.view.translatesAutoresizingMaskIntoConstraints = false
            addChildViewController(reactionsController, targetView: contentView)
        }

        actionsController.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(actionsController, targetView: contentView)

        contentView.addSubview(messageContentView)
        messageContentView.setupMessageBubbleView()
        scrollContentView.addSubview(contentView)
        scrollView.embed(scrollContentView)
        view.embed(blurView)
        view.embed(scrollView)
        
        if let reactionsController = reactionsController {
            layout.reactionsViewConstraints = [
                reactionsController.view.topAnchor.pin(equalTo: contentView.topAnchor),
                reactionsController.view.leadingAnchor.pin(greaterThanOrEqualTo: contentView.leadingAnchor),
                reactionsController.view.trailingAnchor.pin(lessThanOrEqualTo: contentView.trailingAnchor),
                reactionsController.view.bottomAnchor.pin(equalTo: messageContentView.topAnchor, constant: -spacing)
            ]
            
            if message.isSentByCurrentUser {
                layout.reactionsViewConstraints += [
                    reactionsController.view.centerXAnchor.pin(equalTo: messageContentView.messageBubbleView!.leadingAnchor)
                        .with(priority: .defaultHigh),
                    reactionsController.reactionsBubble.tailTrailingAnchor
                        .pin(equalTo: messageContentView.messageBubbleView!.leadingAnchor)
                ]
            } else {
                layout.reactionsViewConstraints += [
                    reactionsController.view.centerXAnchor.pin(equalTo: messageContentView.messageBubbleView!.trailingAnchor)
                        .with(priority: .defaultHigh),
                    reactionsController.reactionsBubble.tailLeadingAnchor
                        .pin(equalTo: messageContentView.messageBubbleView!.trailingAnchor)
                ]
            }
        }
        
        layout.actionsViewConstraints = [
            actionsController.view.topAnchor.pin(equalTo: messageContentView.bottomAnchor, constant: spacing),
            actionsController.view.widthAnchor.pin(equalTo: contentView.widthAnchor, multiplier: 0.7),
            actionsController.view.bottomAnchor.pin(lessThanOrEqualTo: scrollContentView.bottomAnchor)
        ]
        
        if message.isSentByCurrentUser {
            layout.actionsViewConstraints.append(
                actionsController.view.trailingAnchor.pin(equalTo: messageContentView.trailingAnchor)
            )
        } else {
            layout.actionsViewConstraints.append(
                actionsController.view.leadingAnchor.pin(equalTo: messageContentView.messageBubbleView!.leadingAnchor)
            )
        }
        
        layout.messageContentViewConstraints = [
            messageContentView.topAnchor.pin(equalTo: contentView.topAnchor).almostRequired
        ]
        if message.isSentByCurrentUser {
            layout.messageContentViewConstraints.append(
                messageContentView.trailingAnchor.pin(
                    equalTo: contentView.leadingAnchor,
                    constant: messageViewFrame.maxX
                )
            )
        } else {
            layout.messageContentViewConstraints.append(
                messageContentView.leadingAnchor.pin(
                    equalTo: contentView.leadingAnchor,
                    constant: messageViewFrame.minX
                )
            )
        }

        let scrollContentViewConstraint = [
            scrollContentView.widthAnchor.pin(equalTo: view.widthAnchor)
        ]
        
        var contentViewConstraints = [
            contentView.leadingAnchor.pin(equalTo: scrollContentView.leadingAnchor),
            contentView.trailingAnchor.pin(equalTo: scrollContentView.trailingAnchor)
        ]

        if messageViewFrame.minY <= 0 {
            contentViewConstraints += [
                contentView.topAnchor.pin(equalTo: scrollContentView.topAnchor),
                contentView.bottomAnchor.pin(
                    equalTo: scrollContentView.bottomAnchor,
                    constant: -(view.bounds.height - messageViewFrame.maxY - actionsController.view.frame.height - spacing)
                )
            ]
        } else {
            reactionsController?.view.layoutIfNeeded()
            contentViewConstraints += [
                contentView.topAnchor.pin(
                    equalTo: scrollContentView.topAnchor,
                    constant: messageViewFrame.minY - (reactionsController?.view.frame.height ?? 0) - spacing
                ),
                contentView.bottomAnchor.pin(equalTo: scrollContentView.bottomAnchor)
            ]
        }

        NSLayoutConstraint.activate(
            layout.messageContentViewConstraints
                + layout.reactionsViewConstraints
                + layout.actionsViewConstraints
                + scrollContentViewConstraint
                + contentViewConstraints
        )
    }

    override open func updateContent() {
        messageContentView.message = message
        messageContentView.reactionsBubble?.isHidden = true
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Initial values for the animation
        blurView.alpha = 0

        reactionsController?.view.alpha = 0
        reactionsController?.view.transform = .init(scaleX: 0.5, y: 0.5)

        actionsController.view.alpha = 0
        actionsController.view.transform = .init(scaleX: 0.5, y: 0.5)
        
        // Initially, the `applyInitialContentOffset` invocation was in `viewDidLayoutSubviews`
        // since the content offset can be applied when all the views are laid out
        // and `scrollView` content size is calculated.
        //
        // The problem is that `viewDidLayoutSubviews` is also called when reaction is
        // added/removed OR the gif is loaded while the initial `contentOffset` should be applied just once.
        //
        // Dispatching the invocation from `viewWillAppear`:
        //  1. makes sure we do it once;
        //  2. postpones it to the next run-loop iteration which guarantees it happens after `viewDidLayoutSubviews`
        DispatchQueue.main.async {
            self.applyInitialContentOffset()
            
            Animate {
                self.scrollToMakeMessageVisible()
                self.blurView.alpha = 1

                self.actionsController.view.alpha = 1
                self.actionsController.view.transform = .identity
            }
            
            Animate(delay: 0.1) {
                self.reactionsController?.view.alpha = 1
                self.reactionsController?.view.transform = .identity
            }
        }
    }
    
    /// Computes initial content offset of `scrollView` for initial possition of its contents
    open func applyInitialContentOffset() {
        let contentOffset = CGPoint(
            x: 0,
            y: max(0, -messageViewFrame.minY + spacing + (reactionsController?.view.frame.height ?? 0))
        )
        scrollView.setContentOffset(contentOffset, animated: false)
    }

    /// Updates`scrollView.contentOffset`, so that `contentView` si visible
    open func scrollToMakeMessageVisible() {
        let contentRect = scrollContentView.convert(contentView.frame, to: scrollView)
        scrollView.scrollRectToVisible(contentRect, animated: false)
    }

    /// Triggered when `blurView` is tapped
    @objc open func didTapOnOverlay() {
        dismiss(animated: true)
    }
}
