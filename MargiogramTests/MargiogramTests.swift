//
//  MargiogramTests.swift
//  MargiogramTests
//
//  Created by Andrea Margiovanni on 2024.
//

import XCTest
@testable import Margiogram

final class MargiogramTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testUserFullName() throws {
        let user = User.mock(firstName: "John", lastName: "Doe")
        XCTAssertEqual(user.fullName, "John Doe")
    }

    func testUserFullNameWithoutLastName() throws {
        let user = User.mock(firstName: "John", lastName: "")
        XCTAssertEqual(user.fullName, "John")
    }

    func testChatIsPrivate() throws {
        let chat = Chat.mock(type: .private(userId: 1, isBot: false))
        XCTAssertTrue(chat.isPrivate)
        XCTAssertFalse(chat.isGroup)
        XCTAssertFalse(chat.isChannel)
    }

    func testChatIsGroup() throws {
        let chat = Chat.mock(type: .basicGroup(groupId: 1, memberCount: 5))
        XCTAssertTrue(chat.isGroup)
        XCTAssertFalse(chat.isPrivate)
        XCTAssertFalse(chat.isChannel)
    }

    func testChatIsChannel() throws {
        let chat = Chat.mock(type: .supergroup(supergroupId: 1, isChannel: true, memberCount: 1000))
        XCTAssertTrue(chat.isChannel)
        XCTAssertFalse(chat.isPrivate)
        XCTAssertFalse(chat.isGroup)
    }

    func testMessagePreviewText() throws {
        let textMessage = Message.mock(text: "Hello, World!")
        XCTAssertTrue(textMessage.isTextMessage)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
            _ = User.mockContacts
        }
    }
}
