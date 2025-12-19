//
//  MessageDBRepository.swift
//  SimpleChat
//
//  Created by Nicode . on 5/12/24.
//

import Foundation
import Combine

protocol MessagePersistentOperations {
    @discardableResult func createMessage(chat: UserChatLog, roomid: String) -> AnyPublisher<Void, Error>
    @discardableResult func createSystemMessage(chat: SystemLog, roomid: String) -> AnyPublisher<Void, Error>

    func insertReadUser(email: String, roomid: String, chatids: [String])
}

struct RealMessagePersistentOperations: Persistable, MessagePersistentOperations {

    let persistentStore: PersistentStore

    @discardableResult
    func createMessage(chat: UserChatLog, roomid: String) -> AnyPublisher<Void, Error> {
        return persistentStore.update { ctx in
            let fetchResult = try ctx.fetch(UserChatroomEntity.fetchByChatroomid(chatroomid: roomid))
            
            if let chatroom = fetchResult.first(where: { $0.chatroomid == roomid }) {
                if Set(chatroom.log.map { ($0 as! UserMessageEntity).chatid }).contains(chat.id) {
                    throw DataConsistencyError.DuplicateChatLogId(chat.id)
                } else {
                    chat.store(in: ctx, chatroomEntity: chatroom)
                }
            } else {
                throw DataConsistencyError.cannotFoundChatroomFromCoreData(roomid)
            }
        }
    }

    @discardableResult
    func createSystemMessage(chat: SystemLog, roomid: String) -> AnyPublisher<Void, Error> {
        return persistentStore.update { ctx in
            let fetchResult = try ctx.fetch(UserChatroomEntity.fetchByChatroomid(chatroomid: roomid))
            if let chatroom = fetchResult.first(where: { $0.chatroomid == roomid }) {
                if Set(chatroom.syslog.map { ($0 as! UserSystemMessageEntity).sysid }).contains(chat.id) {
                    throw DataConsistencyError.DuplicateChatLogId(chat.id)
                } else {
                    chat.store(in: ctx, chatroomEntity: chatroom)
                }
            } else {
                throw DataConsistencyError.cannotFoundChatroomFromCoreData(roomid)
            }
        }
    }

    func insertReadUser(email: String, roomid: String, chatids: [String]) {
        persistentStore.update { ctx in
            let fetchResult = try ctx.fetch(UserChatroomEntity.fetchByChatroomid(chatroomid: roomid))
            if let room = fetchResult.first(where: { $0.chatroomid == roomid }) {
                chatids.forEach { id in
                    if let chat = room.log.first(where: { ($0 as! UserMessageEntity).chatid == id }) {
                        var new = Set((chat as! UserMessageEntity).readusers.components(separatedBy: " "))
                        new.insert(email)
                        (chat as! UserMessageEntity).readusers = new.joined(separator: " ")
                        print("readed : \((chat as! UserMessageEntity).detail)")
                    }
                }
            }
        }
    }
}
