import Foundation
import Alamofire
import Combine
import SwiftUI

protocol NotificationInteractor {

    func searchOtherUser(searchResult: LoadableSubject<OtherUserSearchResponseModel>, email: String, keyword: String)

    func sendFriendRequestToSearchedUser(searchResult: LoadableSubject<OtherUserSearchResponseModel>, me: String, audience: String)

    func refuseFriendRequest(_ email: String, _ un: Binding<[UserNotification]>,
        _ subscription: Binding<Set<AnyCancellable>>, _ targetNoti: UserNotification)

    func acceptFriendRequest(_ email: String, _ un: Binding<[UserNotification]>, _ uf: Binding<[UserFriend]>,
        _ subscription: Binding<Set<AnyCancellable>>, _ targetNoti: UserNotification)

    func removeAndBlockFriend(_ email: String, _ audience: String, _ isPresented: Binding<Bool>, _ uf: Binding<[UserFriend]>,
        _ uc: Binding<[UserChatroom]>) -> AnyCancellable

    func getBlackList(_ email: String, _ blacklist: LoadableSubject<[UserFriend]>)

    func unblockFriend(_ email: String, _ audience: String, _ disabledUnblockButton: @escaping () -> ()) -> AnyCancellable

    func knellVoiceChat(_ me: String, _ audience: String) -> AnyCancellable
}

struct RealNotificationInteractor: NotificationInteractor {

    let webRepository: NotificationWebRepository
    let dbRepository: DBOperationsContainer

    func searchOtherUser(searchResult: LoadableSubject<OtherUserSearchResponseModel>, email: String, keyword: String) {

        let cb = CancelBag()
        searchResult.wrappedValue.setIsLoading(cancelBag: cb)

        webRepository.getOtherUser(email: email, keyword: keyword)
            .sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("searchOtherUser finished")
                case .failure(let error):
                    print(error.errorDescription ?? "nil")
                }
            },
            receiveValue: { result in
                searchResult.wrappedValue = .loaded(result)
            }
        ).store(in: cb)
    }

    func sendFriendRequestToSearchedUser(searchResult: LoadableSubject<OtherUserSearchResponseModel>, me: String, audience: String) {

        let cb = CancelBag()
        searchResult.wrappedValue.setIsLoading(cancelBag: cb)

        webRepository.sendFriendRequestToSearchedUser(me: me, audience: audience)
            .sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("sendFriendRequest finished")
                case .failure(let error):
                    print(error.errorDescription ?? "nil")
                }
            },
            receiveValue: { result in
                if result.code == .success {
                    searchResult.wrappedValue = .loaded(.init(result: audience, requestState: .wait))
                }
            }
        ).store(in: cb)
    }

    func acceptFriendRequest(_ email: String, _ un: Binding<[UserNotification]>, _ uf: Binding<[UserFriend]>, _ subscription: Binding<Set<AnyCancellable>>, _ targetNoti: UserNotification) {

        webRepository.acceptFriendRequest(me: email, audience: targetNoti.fromEmail)
            .sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("acceptFriendRequest finished")
                case .failure(let error):
                    print(error.errorDescription ?? "nil")
                }
            },
            receiveValue: { result in
                if result.code == .success {
                    if let index = un.wrappedValue.firstIndex(of: targetNoti) {
                        un.wrappedValue.remove(at: index)
                    }
                    let newFriend = UserFriend(email: targetNoti.fromEmail)
                    uf.wrappedValue.append(newFriend)
                    dbRepository.friendPersistentOperations.createFriend(friend: newFriend)
                }
            }
        ).store(in: &subscription.wrappedValue)
    }

    func refuseFriendRequest(_ email: String,
        _ un: Binding<[UserNotification]>, _ subscription: Binding<Set<AnyCancellable>>, _ targetNoti: UserNotification) {

        webRepository.refuseFriendRequest(me: email, audience: targetNoti.fromEmail)
            .sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("refuseFriendRequest finished")
                case .failure(let error):
                    print(error.errorDescription ?? "nil")
                }
            },
            receiveValue: { result in
                if result.code == .success {
                    if let index = un.wrappedValue.firstIndex(of: targetNoti) {
                        un.wrappedValue.remove(at: index)
                    }
                }
            }
        ).store(in: &subscription.wrappedValue)
    }

    func removeAndBlockFriend(_ email: String, _ audience: String, _ isPresented: Binding<Bool>, _ uf: Binding<[UserFriend]>, _ uc: Binding<[UserChatroom]>) -> AnyCancellable {
        return webRepository.removeFriend(me: email, audience: audience)
            .sink(receiveCompletion: { comp in },
            receiveValue: { value in
                print("code : \(value.code)")
                if let idx = uf.wrappedValue.firstIndex(where: { $0.email == audience }) {
                    uf.wrappedValue.remove(at: idx)
                }
                dbRepository.friendPersistentOperations.remove(friend: UserFriend(email: audience))
                if let idx = uc.wrappedValue.firstIndex(
                    where: { $0.roomtype == .pair && $0.audiencelist.contains(email) && $0.audiencelist.contains(audience) }) {
                    dbRepository.chatroomPersistentOperations.removeChatroom(chatroom: uc.wrappedValue[idx])
                    uc.wrappedValue.remove(at: idx)
                    isPresented.wrappedValue = false
                }
                isPresented.wrappedValue = false
            })
    }

    func getBlackList(_ email: String, _ blacklist: LoadableSubject<[UserFriend]>) {
        let cb = CancelBag()
        blacklist.wrappedValue.setIsLoading(cancelBag: cb)

        webRepository.getBlackList(me: email)
            .sink(receiveCompletion: { _ in },
            receiveValue: { value in
                blacklist.wrappedValue = .loaded(value)
            }).store(in: cb)
    }

    func unblockFriend(_ email: String, _ audience: String, _ disabledUnblockButton: @escaping () -> ()) -> AnyCancellable {
        return webRepository.unblockFriend(me: email, audience: audience)
            .sink(receiveCompletion: { _ in },
            receiveValue: { value in disabledUnblockButton() })
    }

    func knellVoiceChat(_ me: String, _ audience: String) -> AnyCancellable {
        webRepository.knellVoiceChat(me: me, audience: audience)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    }
}

