//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import SwiftUI

struct MessengerChatMessageContentView: ChatMessageContentView.SwiftUIView {
    @EnvironmentObject var uiConfig: UIConfig.ObservableObject
    @ObservedObject var dataSource: ChatMessageContentView.ObservedObject<Self>
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()
    
    init(dataSource: _ChatMessageContentView<NoExtraData>.ObservedObject<MessengerChatMessageContentView>) {
        self.dataSource = dataSource
    }
    
    typealias ExtraData = NoExtraData
    
    var body: some View {
        if let message = dataSource.message {
            VStack {
                Text(dateFormatter.string(from: message.createdAt))
                    .font(Font(uiConfig.font.subheadline as CTFont))
                    .foregroundColor(Color(uiConfig.colorPalette.subtitleText))
                HStack(alignment: .bottom) {
                    if message.isSentByCurrentUser {
                        Spacer()
                    }
                    if message.isLastInGroup {
                        if let imageURL = message.author.imageURL,
                           !message.isSentByCurrentUser {
                            ImageView(url: imageURL)
                                .frame(width: 30, height: 30)
                        }
                    }
                    VStack(alignment: message.isSentByCurrentUser ? .trailing : .leading) {
                        if !message.text.isEmpty {
                            Text(message.text)
                                .foregroundColor(
                                    message.isSentByCurrentUser ? Color(uiConfig.colorPalette.text) : Color.white
                                )
                                .font(Font(uiConfig.font.body as CTFont))
                                .padding([.bottom, .top], 8)
                                .padding([.leading, .trailing], 12)
                                .background(
                                    message.isSentByCurrentUser ? Color(uiConfig.colorPalette.background2) : Color.blue
                                )
                                .cornerRadius(18)
                        }
                        if message.attachments.contains(where: { $0.type == .image || $0.type == .giphy || $0.type == .file }) {
                            uiConfig.messageList.messageContentSubviews.attachmentSubviews.attachmentsView
                                .asView(
                                    .init(
                                        attachments: message.attachments.compactMap { $0 as? ChatMessageDefaultAttachment },
                                        didTapOnAttachment: message.didTapOnAttachment,
                                        didTapOnAttachmentAction: message.didTapOnAttachmentAction
                                    )
                                )
                                .frame(width: 300, height: 300)
                        }
                    }
                    if !message.isSentByCurrentUser {
                        Spacer()
                    }
                }
            }
            .padding(.bottom, 10)
        }
    }
}
