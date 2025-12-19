import XCTest
import SwiftUI
import Combine
import Alamofire
@testable import SimpleChat

final class MessageInteractorTests: XCTestCase {

    var sut: MessageInteractor!

    override func setUpWithError() throws {
        super.setUp()

        let session: Session = {
            let configuration: URLSessionConfiguration = {
                let configuration = URLSessionConfiguration.default

                configuration.protocolClasses = [MockURLProtocol.self]
                return configuration
            }()
            return Session(configuration: configuration)
        }()

        let coreDataStack = CoreDataStack.manager

        let chatroomPersistentOperations = RealChatroomPersistentOperations(persistentStore: coreDataStack)
        let friendPersistentOperations = RealFriendPersistentOperations(persistentStore: coreDataStack)
        let messagePersistentOperations = RealMessagePersistentOperations(persistentStore: coreDataStack)
        let chatroomBundlePersistentOperations = RealChatroomBundlePersistentOperations(persistentStore: coreDataStack)

        let coreDataOperationsContainer = DBOperationsContainer(
            chatroomPersistentOperations: chatroomPersistentOperations,
            friendPersistentOperations: friendPersistentOperations,
            messagePersistentOperations: messagePersistentOperations,
            chatroomBundlePersistentOperations: chatroomBundlePersistentOperations)

        sut = RealMessageInteractor(webRepository: RealMessageWebRepository(session: session), dbRepository: coreDataOperationsContainer)
    }

    override func tearDownWithError() throws {
        super.tearDown()
        sut = nil
    }

    func test_sendMessage_successful() throws {
        MockURLProtocol.responseWithDTO(type: .test_sendMessage_successful)
        MockURLProtocol.responseWithStatusCode(code: 200)

        let exp = XCTestExpectation(description: "send message completes")

        var userChatrooms: [UserChatroom] = UserChatroom.stub_1
        let bindedUserChatrooms = Binding(get: { userChatrooms }, set: { userChatrooms = $0 })

        let messageSendingViewModel = MessageSendingViewModel()

        let sender = "nicode@gmail.com"
        let roomid = "f674044f-2610-4fc2-a559-89082089add5"
        let detail = "test message"

        var cancellables = Set<AnyCancellable>()

        sut.sendMessage(sender: sender, roomid: roomid, detail: detail, chatrooms: bindedUserChatrooms, vm: messageSendingViewModel)
            .sink(receiveCompletion: { _ in },
            receiveValue: { chat in
                XCTAssertNotNil(userChatrooms[userChatrooms[roomid]!].log.firstIndex(where: { $0.id == chat.id }), "can not found chatid")
                exp.fulfill()
            }
        ).store(in: &cancellables)

        wait(for: [exp], timeout: 5.0)
    }

    func test_sendMessage_failed_roomNotFound() throws {
        MockURLProtocol.responseWithDTO(type: .test_sendMessage_failed_roomNotFound)
        MockURLProtocol.responseWithStatusCode(code: 200)

        let exp = XCTestExpectation(description: "send message completes")

        var userChatrooms: [UserChatroom] = UserChatroom.stub_1
        let bindedUserChatrooms = Binding(get: { userChatrooms }, set: { userChatrooms = $0 })

        let messageSendingViewModel = MessageSendingViewModel()

        let sender = "nicode@gmail.com"
        let roomid = "f674044f-2610-4fc2-a559-89082089add5"
        let detail = "test message"

        var cancellables = Set<AnyCancellable>()

        sut.sendMessage(sender: sender, roomid: roomid, detail: detail, chatrooms: bindedUserChatrooms, vm: messageSendingViewModel)
            .sink(receiveCompletion: { _ in },
            receiveValue: { chat in
                XCTAssertNil(userChatrooms[userChatrooms[roomid]!].log.firstIndex(where: { $0.id == chat.id }))
                XCTAssertTrue(messageSendingViewModel.activeAlert == .messageSendFail)
                XCTAssertTrue(messageSendingViewModel.shouldShowAlert)
                exp.fulfill()
            }
        ).store(in: &cancellables)

        wait(for: [exp], timeout: 5.0)
    }
}
