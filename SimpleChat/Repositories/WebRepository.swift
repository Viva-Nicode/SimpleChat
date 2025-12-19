import Foundation
import Combine
import Alamofire
import PhotosUI
import SwiftUI


protocol WebRepository {
    var session: Session { get }

    @discardableResult func call<T>(_ endPoint: APIs, _ returnType: T.Type) -> AnyPublisher<T, AFError> where T: Decodable
    func upload<T>(_ endPoint: APIs, _ returnTYpe: T.Type, _ promise: @escaping (Result<T, AFError>) -> Void) throws where T: Decodable
}

extension WebRepository {

    @discardableResult
    func call<T>(_ endPoint: APIs, _ returnType: T.Type) -> AnyPublisher<T, AFError> where T: Decodable {
        let callResult = Future<T, AFError> { promise in
            do {
                switch endPoint {
                case .sendMessage, .sendWhisperMessage, .loadUserData, .signin, .searchOtherUser, .sendFriendRequest, .acceptFriendRequest, .deleteAccount, .exitChatroom, .createChatroom, .inviteUser, .signup, .getReactions, .readMessage, .refuseFriendRequest, .changeAppState, .changeNickname, .createPairChatroom, .exitPairChatroom, .removeFriend, .getBlackList, .unblockFriend, .getProfilesList, .secretAuth, .setChatroomNotification, .loadVideo, .setReaction, .chattingToAi, .removeProfile, .reportChat, .signout, .checkExistUser, .reportUser, .setReadNotification, .getReadNotificationMemberList, .knellVoicechat:
                    session.request(try endPoint.asURLRequest())
                        .validate()
                        .responseDecodable(of: T.self) { response in
                        switch response.result {
                        case .success(let result):
                            promise(.success(result))
                        case .failure(let error):
                            promise(.failure(error))
                        }
                    }
                case .sendPhotoMessage, .sendVideoMessage, .storeProfile, .storeBackgroundProfile:
                    try upload(endPoint, returnType.self, promise)
                }
            } catch(let error) {
                promise(.failure(error as! AFError))
            }
        }
        return callResult
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func upload<T>(_ endPoint: APIs, _ returnTYpe: T.Type, _ promise: @escaping (Result<T, AFError>) -> Void) throws where T: Decodable {
        session.upload(multipartFormData: endPoint.multipartFormData, with: try endPoint.asURLRequest())
            .validate()
            .responseDecodable(of: T.self) { response in
            switch response.result {
            case .success(let result):
                promise(.success(result))
            case.failure(let error):
                promise(.failure(error))
            }
        }
    }
}
