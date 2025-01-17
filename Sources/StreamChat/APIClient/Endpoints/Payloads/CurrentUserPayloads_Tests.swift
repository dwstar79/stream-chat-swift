//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

class CurrentUserPayload_Tests: XCTestCase {
    let currentUserJSON = XCTestCase.mockData(fromFile: "CurrentUser")
    
    func test_currentUserJSON_isSerialized_withDefaultExtraData() throws {
        let payload = try JSONDecoder.default.decode(CurrentUserPayload<NoExtraData>.self, from: currentUserJSON)
        XCTAssertEqual(payload.id, "broken-waterfall-5")
        XCTAssertEqual(payload.isBanned, false)
        XCTAssertEqual(payload.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.lastActiveAt, "2020-06-10T13:24:00.501797Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertEqual(payload.name, "Broken Waterfall")
        XCTAssertEqual(payload.teams.count, 3)

        XCTAssertEqual(
            payload.imageURL,
            URL(string: "https://getstream.io/random_svg/?id=broken-waterfall-5&amp;name=Broken+waterfall")!
        )
        XCTAssertEqual(payload.role, .user)
        XCTAssertEqual(payload.isOnline, true)
        XCTAssertEqual(payload.devices.map(\.id), [
            "cjqZTUHaQIykfH-706Xefw:APA91bF0Ig0gi4ro6w3iPfmE8",
            "e25wfsxcnyA:APA91bFgZR_hfd6GvR42OqCUgIhvpBajjxw7"
        ])
        XCTAssertEqual(payload.mutedUsers.map(\.mutedUser.id), ["dawn-grass-7"])
    }
    
    func test_currentUserJSON_isSerialized_withCustomExtraData() throws {
        struct TestExtraData: UserExtraData {
            static var defaultValue: TestExtraData = .init(secretNote: nil)
            
            let secretNote: String?
            private enum CodingKeys: String, CodingKey {
                case secretNote = "secret_note"
            }
        }
        
        let payload = try JSONDecoder.default.decode(CurrentUserPayload<TestExtraData>.self, from: currentUserJSON)
        XCTAssertEqual(payload.id, "broken-waterfall-5")
        XCTAssertEqual(payload.isBanned, false)
        XCTAssertEqual(payload.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.lastActiveAt, "2020-06-10T13:24:00.501797Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertEqual(payload.role, .user)
        XCTAssertEqual(payload.isOnline, true)
        XCTAssertEqual(payload.teams.count, 3)
        
        XCTAssertEqual(payload.devices.map(\.id), [
            "cjqZTUHaQIykfH-706Xefw:APA91bF0Ig0gi4ro6w3iPfmE8",
            "e25wfsxcnyA:APA91bFgZR_hfd6GvR42OqCUgIhvpBajjxw7"
        ])

        XCTAssertEqual(payload.mutedUsers.map(\.mutedUser.id), ["dawn-grass-7"])
        
        XCTAssertEqual(payload.extraData.secretNote, "Anaking is Vader!")
    }
}
