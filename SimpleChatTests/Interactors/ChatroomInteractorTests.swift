import XCTest
import SwiftUI
import Combine
import Alamofire
@testable import SimpleChat

final class ChatroomInteractorTests: XCTestCase {

    var sut: ChatroomInteractor!

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

        sut = RealChatroomInteractor(webRepository: RealChatroomWebRepository(session: session), dbRepository: coreDataOperationsContainer)
    }

    override func tearDownWithError() throws {
        super.tearDown()
        sut = nil
    }

    func test_createNewChatroom_successful1() throws {
        MockURLProtocol.responseWithDTO(type: .createNewChatroom_1)
        MockURLProtocol.responseWithStatusCode(code: 200)

        let exp = XCTestExpectation(description: "createChatroom completes")

        // MARK: Given
        let email = "dmswns0147@gmail.com"
        let members = ["nicode@gmail.com"]
        let friends = UserFriend.stub_1

        var userChatrooms: [UserChatroom] = UserChatroom.stub_1
        let bindedUserChatrooms = Binding(get: { userChatrooms }, set: { userChatrooms = $0 })

        var chatroomTitles: [String: String] = ApplicationViewModel.chatroomTitlesStub_1
        let bindedChatroomTitles = Binding(get: { chatroomTitles }, set: { chatroomTitles = $0 })

        var cancellables = Set<AnyCancellable>()

        // MARK: When
        sut.createChatroom(email, members, ChatroomType.group.rawValue, bindedUserChatrooms, friends, bindedChatroomTitles)
            .sink(receiveCompletion: { _ in }, receiveValue: { newChatroom in
                // MARK: Then
                XCTAssertTrue(bindedUserChatrooms.wrappedValue.contains(newChatroom), "can not found new chatroom")
                XCTAssertTrue(bindedChatroomTitles.wrappedValue[newChatroom.chatroomid] == "nicode", "can not found new chatroom title")
                exp.fulfill()
            }
        ).store(in: &cancellables)

        wait(for: [exp], timeout: 5.0)
    }

    func test_createNewChatroom_successful2() throws {
        MockURLProtocol.responseWithDTO(type: .createNewChatroom_2)
        MockURLProtocol.responseWithStatusCode(code: 200)

        let exp = XCTestExpectation(description: "createChatroom completes")

        let email = "vivani@gmail.com"
        let members = ["hongsg@naver.com", "dmswns0147@gmail.com"]
        let friends = UserFriend.stub_1

        var userChatrooms = UserChatroom.stub_1
        let bindedUserChatrooms = Binding(get: { userChatrooms }, set: { userChatrooms = $0 })

        var chatroomTitles = ApplicationViewModel.chatroomTitlesStub_1
        let bindedChatroomTitles = Binding(get: { chatroomTitles }, set: { chatroomTitles = $0 })

        var cancellables = Set<AnyCancellable>()

        sut.createChatroom(email, members, ChatroomType.group.rawValue, bindedUserChatrooms, friends, bindedChatroomTitles)
            .sink(receiveCompletion: { _ in }, receiveValue: { newChatroom in
                XCTAssertTrue(bindedUserChatrooms.wrappedValue.contains(newChatroom), "can not found new chatroom")
                XCTAssertTrue(bindedChatroomTitles.wrappedValue[newChatroom.chatroomid] == "dmswns0147,hongsg",
                    "\(bindedChatroomTitles.wrappedValue[newChatroom.chatroomid] ?? "N/A") not equals dmswns0147,hongsg")
                exp.fulfill()
            }
        ).store(in: &cancellables)
        
        wait(for: [exp], timeout: 5.0)
    }
}

