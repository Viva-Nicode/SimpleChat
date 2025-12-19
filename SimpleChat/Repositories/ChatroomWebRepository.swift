import Foundation
import SwiftUI
import Combine
import Alamofire

protocol ChatroomWebRepository: WebRepository {
    func createChatroom(email: String, members: [String], roomtype: String) -> AnyPublisher<UserChatroom, AFError>
    func inviteUser(email: String, audience: String, chatroomid: String) -> AnyPublisher<[SystemLog], AFError>
    func exitChatroom(email: String, chatroomid: String, chatroomtype: ChatroomType) -> AnyPublisher<APIResponse, AFError>
    func startPairChat(email: String, audience: String) -> AnyPublisher<UserChatroom, AFError>
    func readMessage(email: String, chatroomid: String, chatidlist: [String], chattypelist: [String]) -> AnyPublisher <APIResponse, AFError>
    func setChatroomNotification(email: String, chatroomid: String) -> AnyPublisher <APIResponse, AFError>
}

struct RealChatroomWebRepository: ChatroomWebRepository {

    let session: Session

    init(session: Session) {
        self.session = session
    }

    func createChatroom(email: String, members: [String], roomtype: String) -> AnyPublisher<UserChatroom, AFError> {
        call(.createChatroom(email, members, roomtype), UserChatroomResponseModel.self)
            .map { UserChatroom($0) }
            .eraseToAnyPublisher()
    }

    func inviteUser(email: String, audience: String, chatroomid: String) -> AnyPublisher<[SystemLog], AFError> {
        call(.inviteUser(email, audience, chatroomid), [UserChatroomResponseModel.UserSystemLogResponseModel].self)
            .realFlattenMap { SystemLog($1) }
            .eraseToAnyPublisher()
    }

    func exitChatroom(email: String, chatroomid: String, chatroomtype: ChatroomType) -> AnyPublisher<APIResponse, AFError> {
        call(chatroomtype == .group ? .exitChatroom(email, chatroomid) : .exitPairChatroom(email, chatroomid), APIResponse.self)
    }

    func startPairChat(email: String, audience: String) -> AnyPublisher<UserChatroom, AFError> {
        call(.createPairChatroom(email, audience), UserChatroomResponseModel.self)
            .map { UserChatroom($0) }
            .eraseToAnyPublisher()
    }

    func setChatroomNotification(email: String, chatroomid: String) -> AnyPublisher <APIResponse, AFError> {
        call(.setChatroomNotification(email, chatroomid), APIResponse.self)
    }

    func readMessage(email: String, chatroomid: String, chatidlist: [String], chattypelist: [String]) -> AnyPublisher<APIResponse, AFError> {
        let requestBody = UserMessageReadRequestBody(
            email: email,
            chatroomid: chatroomid,
            chatidlist: chatidlist.joined(separator: " "),
            typelist: chattypelist.joined(separator: " "))
        return call(.readMessage(requestBody), APIResponse.self)
    }
}

