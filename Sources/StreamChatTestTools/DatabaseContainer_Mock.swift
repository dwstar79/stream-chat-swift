//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
import XCTest

/// A testable subclass of DatabaseContainer allowing response simulation.
class DatabaseContainerMock: DatabaseContainer {
    /// If set, the `write` completion block is called with this value.
    @Atomic var write_errorResponse: Error?
    @Atomic var init_kind: DatabaseContainer.Kind
    @Atomic var removeAllData_called = false
    @Atomic var removeAllData_errorResponse: Error?
    @Atomic var recreatePersistentStore_called = false
    @Atomic var recreatePersistentStore_errorResponse: Error?
    @Atomic var resetEphemeralValues_called = false
    
    /// If set to `true` and the mock will remove its database files once deinited.
    private var shouldCleanUpTempDBFiles = false
    
    convenience init(localCachingSettings: ChatClientConfig.LocalCaching? = nil) {
        try! self.init(kind: .onDisk(databaseFileURL: .newTemporaryFileURL()), localCachingSettings: localCachingSettings)
        shouldCleanUpTempDBFiles = true
    }
    
    override init(
        kind: DatabaseContainer.Kind,
        shouldFlushOnStart: Bool = false,
        shouldResetEphemeralValuesOnStart: Bool = true,
        modelName: String = "StreamChatModel",
        bundle: Bundle? = nil,
        localCachingSettings: ChatClientConfig.LocalCaching? = nil
    ) throws {
        init_kind = kind
        try super.init(
            kind: kind,
            shouldFlushOnStart: shouldFlushOnStart,
            shouldResetEphemeralValuesOnStart: shouldResetEphemeralValuesOnStart,
            modelName: modelName,
            bundle: bundle,
            localCachingSettings: localCachingSettings
        )
    }
    
    deinit {
        // Remove the database file if the container requests that
        if shouldCleanUpTempDBFiles, case let .onDisk(databaseFileURL: url) = init_kind {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                fatalError("Failed to remove temp database file: \(error)")
            }
        }
    }
    
    override func removeAllData(force: Bool = true) throws {
        removeAllData_called = true
        
        if let error = removeAllData_errorResponse {
            throw error
        }
        
        try super.removeAllData(force: force)
    }
    
    override func recreatePersistentStore() throws {
        recreatePersistentStore_called = true
        
        if let error = recreatePersistentStore_errorResponse {
            throw error
        }
        
        try super.recreatePersistentStore()
    }
    
    /// `true` if there is currently an active writing session
    @Atomic var isWriteSessionInProgress: Bool = false
    
    /// Every time a write session finishes this counter is increased
    @Atomic var writeSessionCounter: Int = 0
    
    override func write(_ actions: @escaping (DatabaseSession) throws -> Void, completion: @escaping (Error?) -> Void) {
        let wrappedActions: ((DatabaseSession) throws -> Void) = { session in
            self.isWriteSessionInProgress = true
            try actions(session)
            self.isWriteSessionInProgress = false
            self._writeSessionCounter { $0 += 1 }
        }
        
        if let error = write_errorResponse {
            super.write(wrappedActions, completion: { _ in })
            completion(error)
        } else {
            super.write(wrappedActions, completion: completion)
        }
    }
    
    override func resetEphemeralValues() {
        resetEphemeralValues_called = true
        super.resetEphemeralValues()
    }
}

extension DatabaseContainer {
    /// Writes changes to the DB synchronously. Only for test purposes!
    func writeSynchronously(_ actions: @escaping (DatabaseSession) throws -> Void) throws {
        let error = try await { completion in
            self.write(actions, completion: completion)
        }
        if let error = error {
            throw error
        }
    }
    
    /// Synchronously creates a new UserDTO in the DB with the given id.
    func createUser(id: UserId = .unique, extraData: NoExtraData = .defaultValue) throws {
        try writeSynchronously { session in
            try session.saveUser(payload: .dummy(userId: id, extraData: extraData))
        }
    }
    
    /// Synchronously creates a new CurrentUserDTO in the DB with the given id.
    func createCurrentUser(id: UserId = .unique) throws {
        try writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(
                userId: id,
                role: .admin,
                extraData: NoExtraData.defaultValue
            ))
        }
    }
    
    /// Synchronously creates a new ChannelDTO in the DB with the given cid.
    func createChannel(cid: ChannelId = .unique, withMessages: Bool = true) throws {
        try writeSynchronously { session in
            let dto = try session.saveChannel(payload: XCTestCase().dummyPayload(with: cid))
            
            // Delete possible messages from the payload if `withMessages` is false
            if !withMessages {
                let context = session as! NSManagedObjectContext
                dto.messages.forEach { context.delete($0) }
                dto.oldestMessageAt = .distantPast
            }
        }
    }
    
    func createChannelListQuery(
        filter: Filter<ChannelListFilterScope> = .query(.cid, text: .unique)
    ) throws {
        try writeSynchronously { session in
            let dto = NSEntityDescription
                .insertNewObject(
                    forEntityName: ChannelListQueryDTO.entityName,
                    into: session as! NSManagedObjectContext
                ) as! ChannelListQueryDTO
            dto.filterHash = filter.filterHash
            dto.filterJSONData = try JSONEncoder.default.encode(filter)
        }
    }
    
    func createUserListQuery(filter: Filter<UserListFilterScope> = .query(.id, text: .unique)) throws {
        try writeSynchronously { session in
            let dto = NSEntityDescription
                .insertNewObject(
                    forEntityName: UserListQueryDTO.entityName,
                    into: session as! NSManagedObjectContext
                ) as! UserListQueryDTO
            dto.filterHash = filter.filterHash
            dto.filterJSONData = try JSONEncoder.default.encode(filter)
        }
    }
    
    func createMemberListQuery<ExtraData: UserExtraData>(query: _ChannelMemberListQuery<ExtraData>) throws {
        try writeSynchronously { session in
            try session.saveQuery(query)
        }
    }
    
    /// Synchronously creates a new MessageDTO in the DB with the given id.
    func createMessage(
        id: MessageId = .unique,
        authorId: UserId = .unique,
        cid: ChannelId = .unique,
        text: String = .unique,
        pinned: Bool = false,
        pinnedByUserId: UserId? = nil,
        pinnedAt: Date? = nil,
        pinExpires: Date? = nil,
        attachments: [AttachmentPayload] = [],
        localState: LocalMessageState? = nil,
        type: MessageType? = nil
    ) throws {
        try writeSynchronously { session in
            try session.saveChannel(payload: XCTestCase().dummyPayload(with: cid))
            
            let message: MessagePayload<NoExtraData> = .dummy(
                type: type,
                messageId: id,
                attachments: attachments,
                authorUserId: authorId,
                text: text,
                pinned: pinned,
                pinnedByUserId: pinnedByUserId,
                pinnedAt: pinnedAt,
                pinExpires: pinExpires
            )
            
            let messageDTO = try session.saveMessage(payload: message, for: cid)
            messageDTO.localMessageState = localState
        }
    }
    
    func createMember(
        userId: UserId = .unique,
        role: MemberRole = .member,
        cid: ChannelId,
        query: ChannelMemberListQuery? = nil
    ) throws {
        try writeSynchronously { session in
            try session.saveMember(
                payload: .dummy(userId: userId, role: role),
                channelId: query?.cid ?? cid,
                query: query
            )
        }
    }
}

extension XCTestCase {
    static let channelCreatedDate = Date.unique

    // MARK: - Dummy data with extra data
    
    var dummyCurrentUser: CurrentUserPayload<NoExtraData> {
        CurrentUserPayload(
            id: "dummyCurrentUser",
            name: .unique,
            imageURL: nil,
            role: .user,
            createdAt: .unique,
            updatedAt: .unique,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: false,
            isBanned: false,
            extraData: .defaultValue
        )
    }
    
    var dummyUser: UserPayload<NoExtraData> {
        dummyUser(id: .unique)
    }
    
    func dummyUser(id: String) -> UserPayload<NoExtraData> {
        UserPayload(
            id: id,
            name: .unique,
            imageURL: .unique(),
            role: .user,
            createdAt: .unique,
            updatedAt: .unique,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            teams: [],
            extraData: .defaultValue
        )
    }
    
    func dummyMessagePayload(
        createdAt: Date = XCTestCase.channelCreatedDate.addingTimeInterval(.random(in: 60...900_000))
    ) -> MessagePayload<NoExtraData> {
        MessagePayload(
            id: .unique,
            type: .regular,
            user: dummyUser,
            createdAt: createdAt,
            updatedAt: .unique,
            deletedAt: nil,
            text: .unique,
            command: nil,
            args: nil,
            parentId: nil,
            showReplyInChannel: false,
            mentionedUsers: [dummyCurrentUser],
            replyCount: 0,
            extraData: .defaultValue,
            reactionScores: ["like": 1],
            isSilent: false,
            attachments: []
        )
    }
    
    func dummyPinnedMessagePayload(
        createdAt: Date = XCTestCase.channelCreatedDate.addingTimeInterval(.random(in: 50...99))
    ) -> MessagePayload<NoExtraData> {
        MessagePayload(
            id: .unique,
            type: .regular,
            user: dummyUser,
            // createAt should be lower than dummyMessage, so it does not come first in `latestMessages`
            createdAt: createdAt,
            updatedAt: .unique,
            deletedAt: nil,
            text: .unique,
            command: nil,
            args: nil,
            parentId: nil,
            showReplyInChannel: false,
            mentionedUsers: [dummyCurrentUser],
            replyCount: 0,
            extraData: .defaultValue,
            reactionScores: ["like": 1],
            isSilent: false,
            attachments: [],
            pinned: true,
            pinnedBy: dummyUser,
            pinnedAt: .unique,
            pinExpires: .unique
        )
    }
    
    var dummyChannelRead: ChannelReadPayload<NoExtraData> {
        ChannelReadPayload(user: dummyCurrentUser, lastReadAt: Date(timeIntervalSince1970: 1), unreadMessagesCount: 10)
    }
    
    func dummyPayload(
        with channelId: ChannelId,
        numberOfMessages: Int = 1,
        members: [MemberPayload<NoExtraData>] = [.unique],
        watchers: [UserPayload<NoExtraData>]? = nil,
        includeMembership: Bool = true,
        messages: [MessagePayload<NoExtraData>]? = nil,
        pinnedMessages: [MessagePayload<NoExtraData>] = []
    ) -> ChannelPayload<NoExtraData> {
        var payloadMessages: [MessagePayload<NoExtraData>] = []
        if let messages = messages {
            payloadMessages = messages
        } else {
            for _ in 0..<numberOfMessages {
                payloadMessages += [dummyMessagePayload()]
            }
        }
        
        let lastMessageAt: Date? = payloadMessages.map(\.createdAt).max()
        
        let payload: ChannelPayload<NoExtraData> =
            .init(
                channel: .init(
                    cid: channelId,
                    name: .unique,
                    imageURL: .unique(),
                    extraData: .defaultValue,
                    typeRawValue: channelId.type.rawValue,
                    lastMessageAt: lastMessageAt,
                    createdAt: XCTestCase.channelCreatedDate,
                    deletedAt: nil,
                    updatedAt: .unique,
                    createdBy: dummyUser,
                    config: .init(
                        reactionsEnabled: true,
                        typingEventsEnabled: true,
                        readEventsEnabled: true,
                        connectEventsEnabled: true,
                        uploadsEnabled: true,
                        repliesEnabled: true,
                        searchEnabled: true,
                        mutesEnabled: true,
                        urlEnrichmentEnabled: true,
                        messageRetention: "1000",
                        maxMessageLength: 100,
                        commands: [
                            .init(
                                name: "test",
                                description: "test commant",
                                set: "test",
                                args: "test"
                            )
                        ],
                        createdAt: XCTestCase.channelCreatedDate,
                        updatedAt: .unique
                    ),
                    isFrozen: true,
                    memberCount: 100,
                    team: .unique,
                    members: members,
                    cooldownDuration: .random(in: 0...120)
                ),
                watcherCount: watchers?.count ?? 1,
                watchers: watchers ?? [dummyUser],
                members: members,
                membership: includeMembership ? members.first : nil,
                messages: payloadMessages,
                pinnedMessages: pinnedMessages,
                channelReads: [dummyChannelRead]
            )
        
        return payload
    }
    
    // MARK: - Dummy data with no extra data
    
    enum NoExtraDataTypes: ExtraDataTypes {
        typealias Channel = NoExtraData
        typealias Message = NoExtraData
        typealias User = NoExtraData
        typealias Attachment = NoExtraData
    }
    
    var dummyMessageWithNoExtraData: MessagePayload<NoExtraDataTypes> {
        MessagePayload(
            id: .unique,
            type: .regular,
            user: dummyUser,
            createdAt: .unique,
            updatedAt: .unique,
            deletedAt: nil,
            text: .unique,
            command: nil,
            args: nil,
            parentId: nil,
            showReplyInChannel: false,
            mentionedUsers: [],
            replyCount: 0,
            extraData: NoExtraData(),
            reactionScores: [:],
            isSilent: false,
            attachments: []
        )
    }
    
    var dummyChannelReadWithNoExtraData: ChannelReadPayload<NoExtraDataTypes> {
        ChannelReadPayload(user: dummyUser, lastReadAt: .unique, unreadMessagesCount: .random(in: 0...10))
    }
    
    func dummyPayloadWithNoExtraData(with channelId: ChannelId) -> ChannelPayload<NoExtraDataTypes> {
        let member: MemberPayload<NoExtraData> =
            .init(
                user: .init(
                    id: .unique,
                    name: .unique,
                    imageURL: nil,
                    role: .admin,
                    createdAt: .unique,
                    updatedAt: .unique,
                    lastActiveAt: .unique,
                    isOnline: true,
                    isInvisible: true,
                    isBanned: true,
                    teams: [],
                    extraData: .init()
                ),
                role: .member,
                createdAt: .unique,
                updatedAt: .unique
            )
        
        let payload: ChannelPayload<NoExtraDataTypes> =
            .init(
                channel: .init(
                    cid: channelId,
                    name: .unique,
                    imageURL: .unique(),
                    extraData: .init(),
                    typeRawValue: channelId.type.rawValue,
                    lastMessageAt: .unique,
                    createdAt: .unique,
                    deletedAt: .unique,
                    updatedAt: .unique,
                    createdBy: dummyUser,
                    config: .init(
                        reactionsEnabled: true,
                        typingEventsEnabled: true,
                        readEventsEnabled: true,
                        connectEventsEnabled: true,
                        uploadsEnabled: true,
                        repliesEnabled: true,
                        searchEnabled: true,
                        mutesEnabled: true,
                        urlEnrichmentEnabled: true,
                        messageRetention: "1000",
                        maxMessageLength: 100,
                        commands: [
                            .init(
                                name: "test",
                                description: "test commant",
                                set: "test",
                                args: "test"
                            )
                        ],
                        createdAt: XCTestCase.channelCreatedDate,
                        updatedAt: .unique
                    ),
                    isFrozen: true,
                    memberCount: 100,
                    team: .unique,
                    members: nil,
                    cooldownDuration: .random(in: 0...120)
                ),
                watcherCount: 10,
                watchers: [dummyUser],
                members: [member],
                membership: member,
                messages: [dummyMessageWithNoExtraData],
                pinnedMessages: [dummyMessageWithNoExtraData],
                channelReads: [dummyChannelReadWithNoExtraData]
            )
        
        return payload
    }
}

private extension MemberPayload where ExtraData == NoExtraData {
    static var unique: MemberPayload<NoExtraData> {
        withLastActivity(at: .unique)
    }
    
    static func withLastActivity(at date: Date) -> MemberPayload<NoExtraData> {
        .init(
            user: .init(
                id: .unique,
                name: .unique,
                imageURL: nil,
                role: .admin,
                createdAt: .unique,
                updatedAt: .unique,
                lastActiveAt: date,
                isOnline: true,
                isInvisible: true,
                isBanned: true,
                teams: [],
                extraData: .defaultValue
            ),
            role: .moderator,
            createdAt: .unique,
            updatedAt: .unique
        )
    }
}

private extension UserPayload where ExtraData == NoExtraData {
    static func withLastActivity(at date: Date) -> UserPayload<NoExtraData> {
        .init(
            id: .unique,
            name: .unique,
            imageURL: nil,
            role: .admin,
            createdAt: .unique,
            updatedAt: .unique,
            lastActiveAt: date,
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            teams: [],
            extraData: .defaultValue
        )
    }
}
