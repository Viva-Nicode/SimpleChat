//
//  FriendDBRepository.swift
//  SimpleChat
//
//  Created by Nicode . on 4/30/24.
//

import Foundation
import Combine

protocol FriendPersistentOperations {

    @discardableResult func createFriend(friend: UserFriend) -> AnyPublisher<UserFriendEntity, Error>
    @discardableResult func createFriends(friends: [UserFriend]) -> AnyPublisher<[UserFriendEntity], Error>

    func synchronizeFriends(friends: [UserFriend])

    func readfriend(friend: UserFriend) -> AnyPublisher<[UserFriend], Error>
    func readAllFriend() -> AnyPublisher<[UserFriend], Error>
    func isDifferent(uf: [UserFriend]) -> AnyPublisher<Bool, Error>

    @discardableResult func remove(friend: UserFriend) -> AnyPublisher<Int?, Error>
}

struct RealFriendPersistentOperations: Persistable, FriendPersistentOperations {

    let persistentStore: PersistentStore

    @discardableResult
    func createFriend(friend: UserFriend) -> AnyPublisher<UserFriendEntity, Error> {
        persistentStore.update { friend.store(in: $0) }
    }

    @discardableResult
    func createFriends(friends: [UserFriend]) -> AnyPublisher<[UserFriendEntity], Error> {
        persistentStore.update { friends.store(in: $0) }
    }

    func synchronizeFriends(friends: [UserFriend]) {
        persistentStore.update { ctx in
            try friends.forEach { friend in
                let fetchRequest = UserFriendEntity.fetchRequestByEmail(email: friend.email)
                let fetchResult = try ctx.fetch(fetchRequest)

                fetchResult.first!.nickname = friend.nickname
            }
        }
    }

    func readfriend(friend: UserFriend) -> AnyPublisher<[UserFriend], Error> {
        let fetchRequest = UserFriendEntity.fetchRequestByEmail(email: friend.email)
        return persistentStore.fetch(fetchRequest) {
            UserFriend($0)
        }.eraseToAnyPublisher()
    }

    func readAllFriend() -> AnyPublisher<[UserFriend], Error> {
        let fetchRequest = UserFriendEntity.fetchRequest()
        return persistentStore.fetch(fetchRequest) {
            UserFriend($0) }
            .map { friends in friends.sorted(by: { $0.email > $1.email }) }
            .eraseToAnyPublisher()
    }

    func isDifferent(uf: [UserFriend]) -> AnyPublisher<Bool, Error> {

        return readAllFriend()
            .receive(on: DispatchQueue.global(qos: .background))
            .map { friends in
            if uf.count != friends.count { return true }

            let sortedLhs = uf.sorted(by: { $0.email > $1.email })
            let sortedRhs = friends.sorted(by: { $0.email > $1.email })

            return sortedLhs.enumerated().map { i, v in
                sortedRhs[i] != v
            }.reduce(false) { $0 || $1 }
        }.eraseToAnyPublisher()
    }

    @discardableResult
    func remove(friend: UserFriend) -> AnyPublisher<Int?, Error> {
        persistentStore.update { friend.remove(in: $0) }
    }
}
