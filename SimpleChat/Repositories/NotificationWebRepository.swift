import Foundation
import SwiftUI
import Combine
import Alamofire

protocol NotificationWebRepository: WebRepository {
    func getOtherUser(email: String, keyword: String) -> AnyPublisher<OtherUserSearchResponseModel, AFError>
    func sendFriendRequestToSearchedUser(me: String, audience: String) -> AnyPublisher<APIResponse, AFError>
    func acceptFriendRequest(me: String, audience: String) -> AnyPublisher<APIResponse, AFError>
    func refuseFriendRequest(me: String, audience: String) -> AnyPublisher<APIResponse, AFError>
    func removeFriend(me: String, audience: String) -> AnyPublisher<APIResponse, AFError>
    func getBlackList(me: String) -> AnyPublisher<[UserFriend], AFError>
    func unblockFriend(me: String, audience: String) -> AnyPublisher<APIResponse, AFError>
    func knellVoiceChat(me: String, audience: String) -> AnyPublisher<APIResponse, AFError>
}

struct RealNotificationWebRepository: NotificationWebRepository {

    let session: Session

    init(session: Session) {
        self.session = session
    }

    func getOtherUser(email: String, keyword: String) -> AnyPublisher<OtherUserSearchResponseModel, AFError> {
        call(.searchOtherUser(email, keyword), OtherUserSearchResponseModel.self)
    }

    func sendFriendRequestToSearchedUser(me: String, audience: String) -> AnyPublisher<APIResponse, AFError> {
        call(.sendFriendRequest(me, audience), APIResponse.self)
    }

    func acceptFriendRequest(me: String, audience: String) -> AnyPublisher<APIResponse, AFError> {
        call(.acceptFriendRequest(me, audience), APIResponse.self)
    }

    func refuseFriendRequest(me: String, audience: String) -> AnyPublisher<APIResponse, AFError> {
        call(.refuseFriendRequest(me, audience), APIResponse.self)
    }

    func removeFriend(me: String, audience: String) -> AnyPublisher<APIResponse, AFError> {
        call(.removeFriend(me, audience), APIResponse.self)
    }

    func getBlackList(me: String) -> AnyPublisher<[UserFriend], AFError> {
        call(.getBlackList(me), [UserDataFetchResponseModel.UserFriendResponseModel].self)
            .realFlattenMap { UserFriend($1) }.eraseToAnyPublisher()
    }

    func unblockFriend(me: String, audience: String) -> AnyPublisher<APIResponse, AFError> {
        call(.unblockFriend(me, audience), APIResponse.self)
    }

    func knellVoiceChat(me: String, audience: String) -> AnyPublisher<APIResponse, AFError> {
        call(.knellVoicechat(me, audience), APIResponse.self)
    }
}
