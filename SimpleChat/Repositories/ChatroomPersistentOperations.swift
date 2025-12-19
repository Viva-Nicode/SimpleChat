//
//  ChatroomDBRepository.swift
//  SimpleChat
//
//  Created by Nicode . on 4/30/24.
//

import Foundation
import Combine

protocol ChatroomPersistentOperations {
    @discardableResult func createChatroom(chatroom: UserChatroom) -> AnyPublisher<UserChatroomEntity, Error>
    @discardableResult func createChatrooms(chatrooms: [UserChatroom]) -> AnyPublisher<[UserChatroomEntity], Error>

    func readChatroom(chatroom: UserChatroom) -> AnyPublisher<[UserChatroom], Error>
    func readChatroomTitles() -> AnyPublisher<[String:String?], Error>
    func readAllChatroom() -> AnyPublisher<[UserChatroom], Error>
    func isDifferent(ucr: [UserChatroom]) -> AnyPublisher<Bool, Error>

    func insertMember(member: String, roomid: String)
    func removeMember(member: String, roomid: String)
    func updateChatroomTitle(title: String, roomid: String) -> AnyPublisher<Int, Error>

    @discardableResult func removeChatroom(chatroom: UserChatroom) -> AnyPublisher<Int?, Error>
    @discardableResult func removeChatrooms(chatrooms: [UserChatroom]) -> AnyPublisher<Int?, Error>

    func synchronizeChatrooms(des: [UserChatroom])
}

struct RealChatroomPersistentOperations: Persistable, ChatroomPersistentOperations {

    let persistentStore: PersistentStore

    func updateChatroomTitle(title: String, roomid: String) -> AnyPublisher<Int, Error> {
        return persistentStore.update { ctx in
            let fetchResult = try ctx.fetch(UserChatroomEntity.fetchByChatroomid(chatroomid: roomid))
            if let resultChatroom = fetchResult.first(where: { $0.chatroomid == roomid }) {
                resultChatroom.chatroomTitle = title
                return fetchResult.count
            } else {
                return 0
            }
        }
    }

    func readChatroomTitles() -> AnyPublisher<[String:String?], Error> {
        let fetchRequest = UserChatroomEntity.fetchRequest()
        return persistentStore.fetch(fetchRequest) {
            $0
        }.map { titles in
            var resultChatroomTitleTable: [String: String?] = [:]
            titles.forEach {
                resultChatroomTitleTable[$0.chatroomid] = $0.chatroomTitle
            }
            return resultChatroomTitleTable
        }.eraseToAnyPublisher()
    }

    @discardableResult
    func createChatroom(chatroom: UserChatroom) -> AnyPublisher<UserChatroomEntity, Error> {
        return persistentStore.update { ctx in
            let fetchResult = try ctx.fetch(UserChatroomEntity.fetchRequest())
            if Set(fetchResult.map { $0.chatroomid }).contains(chatroom.chatroomid) {
                throw DataConsistencyError.DuplicateChatLogId(chatroom.chatroomid)
            } else {
                return chatroom.store(in: ctx)
            }
        }
    }

    @discardableResult
    func createChatrooms(chatrooms: [UserChatroom]) -> AnyPublisher<[UserChatroomEntity], Error> {
        persistentStore.update { chatrooms.store(in: $0) }
    }

    func readChatroom(chatroom: UserChatroom) -> AnyPublisher<[UserChatroom], Error> {
        let fetchRequest = UserChatroomEntity.fetchByChatroomid(chatroomid: chatroom.chatroomid)
        return persistentStore.fetch(fetchRequest) {
            UserChatroom($0)
        }.eraseToAnyPublisher()
    }

    func readAllChatroom() -> AnyPublisher<[UserChatroom], Error> {
        let fetchRequest = UserChatroomEntity.fetchRequest()
        return persistentStore.fetch(fetchRequest) {
            UserChatroom($0)
        }.eraseToAnyPublisher()
    }

    func isDifferent(ucr: [UserChatroom]) -> AnyPublisher<Bool, Error> {

        return readAllChatroom()
            .receive(on: DispatchQueue.global(qos: .background))
            .map { chatrooms in
            if ucr.count != chatrooms.count { return true }

            let sortedLhs = ucr.sorted(by: { $0.chatroomid > $1.chatroomid })
            let sortedRhs = chatrooms.sorted(by: { $0.chatroomid > $1.chatroomid })

            return zip(sortedLhs, sortedRhs).map { (lchatroom, rchatroom) in lchatroom != rchatroom }
                .reduce(false) { $0 || $1 }
        }.eraseToAnyPublisher()
    }

    @discardableResult
    func removeChatroom(chatroom: UserChatroom) -> AnyPublisher<Int?, Error> {
        persistentStore.update { chatroom.remove(in: $0) }
    }

    @discardableResult
    func removeChatrooms(chatrooms: [UserChatroom]) -> AnyPublisher<Int?, Error> {
        persistentStore.update { chatrooms.remove(in: $0) }
    }


    func insertMember(member: String, roomid: String) {
        persistentStore.update { ctx in
            let fetchResult = try ctx.fetch(UserChatroomEntity.fetchByChatroomid(chatroomid: roomid))
            let room = fetchResult.first(where: { $0.chatroomid == roomid })!
            var new = Set(room.audiencelist.components(separatedBy: " "))
            new.insert(member)
            room.audiencelist = new.joined(separator: " ")
        }
    }

    func removeMember(member: String, roomid: String) {
        persistentStore.update { ctx in
            let fetchResult = try ctx.fetch(UserChatroomEntity.fetchByChatroomid(chatroomid: roomid))
            let room = fetchResult.first(where: { $0.chatroomid == roomid })!
            var new = Set(room.audiencelist.components(separatedBy: " "))
            new.remove(member)
            room.audiencelist = new.joined(separator: " ")
        }
    }

    func synchronizeChatrooms(des: [UserChatroom]) {
        persistentStore.update { ctx in
            print("sync : \(des.count)")
            let fetchRequest = UserChatroomEntity.fetchRequest()

            let fetchResult = try ctx.fetch(fetchRequest)
            try des.forEach { serverChatroom in
                if let synchronizeTarget = fetchResult.first(where: { $0.chatroomid == serverChatroom.chatroomid }) {

                    guard synchronizeTarget.log.count + synchronizeTarget.syslog.count <= serverChatroom.log.count else {
                        throw DataConsistencyError.ServerDataShortageThanLocalData(serverChatroom.chatroomid)
                    }

                    synchronizeTarget.audiencelist = serverChatroom.audiencelist.joined(separator: " ")

                    try synchronizeTarget.log.forEach { l in
                        let coreDataLog = l as! UserMessageEntity
                        if let serverLog = serverChatroom.log.first(where: { $0.id == coreDataLog.chatid }) {
                            if let serverChatLog = serverLog as? UserChatLog {
                                coreDataLog.readusers = serverChatLog.readusers.joined(separator: " ")
                            } else {
                                throw DataConsistencyError.CanNotConvertingToUserChatLog(serverLog.id)
                            }
                        } else {
                            throw DataConsistencyError.NotFoundLogFromServerData(serverChatroom.chatroomid, coreDataLog.chatid)
                        }
                    }

                    serverChatroom.log.forEach { log in
                        if (synchronizeTarget.log.first(where: { ($0 as! UserMessageEntity).chatid == log.id }) == nil) &&
                            (synchronizeTarget.syslog.first(where: { ($0 as! UserSystemMessageEntity).sysid == log.id }) == nil) {
                            switch log {
                            case let newChatLog as UserChatLog:
                                newChatLog.store(in: ctx, chatroomEntity: synchronizeTarget)
                            case let newSystemLog as SystemLog:
                                newSystemLog.store(in: ctx, chatroomEntity: synchronizeTarget)
                            default:
                                break
                            }
                        }
                    }
                }
            }
        }
    }
}
