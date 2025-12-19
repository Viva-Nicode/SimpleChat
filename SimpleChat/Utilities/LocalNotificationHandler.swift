//
//  LocalNotificationHandler.swift
//  SimpleChat
//
//  Created by Nicode . on 4/17/24.
//

import Foundation
import SwiftUI

protocol UserEventHandler {
    var dbRepository: DBOperationsContainer { get }

    func handleArrivedMessageNotification(notification: Notification, uc: Binding<[UserChatroom]>,
        uf: Binding<[UserFriend]>, utt: Binding<[String:String]>)
    func handleReadMessageNotification(notification: Notification, uc: Binding<[UserChatroom]>)
    func handleArrivedFriendRequestNotification(notification: Notification, un: Binding<[UserNotification]>)
    func handleArrivedSystemMessageNotification(notification: Notification, uc: Binding<[UserChatroom]>)
    func handleArrivedAcceptedFriendRequest(notification: Notification, uf: Binding<[UserFriend]>)
    func handleArrivedFriendRemoveRequest(notification: Notification, uf: Binding<[UserFriend]>)
}

struct ConcreteUserEventHandler: UserEventHandler {

    let dbRepository: DBOperationsContainer

    func handleArrivedMessageNotification(notification: Notification, uc: Binding<[UserChatroom]>, uf: Binding<[UserFriend]>, utt: Binding<[String:String]>) {

        let newChatLog = UserChatLog(
            id: notification.userInfo!["chatid"] as! String,
            logType: notification.userInfo!["messageType"] as! String,
            writer: notification.userInfo!["sender"] as! String,
            timestamp: notification.userInfo!["timestamp"] as! String,
            detail: notification.userInfo!["detail"] as! String,
            isSetReadNotification: false,
            readusers: notification.userInfo!["readusers"] as! String)

        let roomid = notification.userInfo!["roomid"] as! String
        let roomtype = notification.userInfo!["roomtype"] as! String

        if let idx = uc.wrappedValue[roomid] {

            withAnimation(.spring(duration: 0.3)) { uc.wrappedValue[idx].log.append(newChatLog) }
            dbRepository.messagePersistentOperations.createMessage(chat: newChatLog, roomid: roomid)

        } else {
            var newChatroom = UserChatroom(
                chatroomid: notification.userInfo!["roomid"] as! String,
                audiencelist: notification.userInfo!["audiencelist"] as! String, roomtype: roomtype)

            dbRepository.chatroomPersistentOperations.createChatroom(chatroom: newChatroom)
            dbRepository.messagePersistentOperations.createMessage(chat: newChatLog, roomid: newChatroom.chatroomid)

            newChatroom.log.append(newChatLog)

            if let me: String = UserDefaultsKeys.userEmail.value() {
                let defaultChatroomTitle = newChatroom.audiencelist
                    .filter { $0 != me }
                    .map { audienceEmail in
                    uf.wrappedValue.first(where: { $0.email == audienceEmail })?.nickname ?? audienceEmail }
                    .sorted()
                    .joined(separator: ",")
                utt.wrappedValue[newChatroom.chatroomid] = defaultChatroomTitle
            }
            withAnimation(.spring(duration: 0.3)) { uc.wrappedValue.append(newChatroom) }
        }
    }

    func handleReadMessageNotification(notification: Notification, uc: Binding<[UserChatroom]>) {
        let chatroomid = notification.userInfo!["chatroomid"] as! String
        if let idx = uc.wrappedValue[chatroomid] {
            let chatidList = (notification.userInfo!["idlist"] as! String).components(separatedBy: " ")
            let who = notification.userInfo!["who"] as! String
            for chatid in chatidList {
                if let chatidx = uc.wrappedValue[idx].log.firstIndex(where: { $0.id == chatid }) {
                    withAnimation(.spring(duration: 0.3)) {
                        uc.wrappedValue[idx].log[chatidx].addReadusers(user: who)
                    }
                }
            }
            dbRepository.messagePersistentOperations.insertReadUser(email: who, roomid: chatroomid, chatids: chatidList)
        } else {
            print("not found chatroomid")
        }
    }

    func handleArrivedFriendRequestNotification(notification: Notification, un: Binding<[UserNotification]>) {
        un.wrappedValue.append(UserNotification(
            fromEmail: notification.userInfo!["fromemail"] as! String,
            notitype: "friendRequest",
            timestamp: notification.userInfo!["timestamp"] as! String))
    }

    func handleArrivedSystemMessageNotification(notification: Notification, uc: Binding<[UserChatroom]>) {
        let roomid = notification.userInfo!["roomid"] as! String
        if let idx = uc.wrappedValue[roomid] {

            let logType = LogType(rawValue: notification.userInfo!["type"] as! String) ?? LogType.undefined

            switch(logType) {
            case .exit:
                let newSystemLog = SystemLog(
                    id: notification.userInfo!["sysid"] as! String,
                    logType: notification.userInfo!["type"] as! String,
                    timestamp: notification.userInfo!["timestamp"] as! String,
                    detail: notification.userInfo!["detail"] as! String)

                uc.wrappedValue[idx].log.append(newSystemLog)
                dbRepository.messagePersistentOperations.createSystemMessage(chat: newSystemLog, roomid: roomid)

                uc.wrappedValue[idx].audiencelist.remove(newSystemLog.detail)
                dbRepository.chatroomPersistentOperations.removeMember(member: newSystemLog.detail, roomid: roomid)

            case .enter:
                let details = (notification.userInfo!["detail"] as! String).components(separatedBy: " ")
                let ids = (notification.userInfo!["sysid"] as! String).components(separatedBy: " ")

                for (sysid, detail) in zip(ids, details[1...]) {
                    uc.wrappedValue[idx].audiencelist.insert(detail)
                    dbRepository.chatroomPersistentOperations.insertMember(member: detail, roomid: roomid)

                    let newSystemLog = SystemLog(
                        id: sysid,
                        logType: notification.userInfo!["type"] as! String,
                        timestamp: notification.userInfo!["timestamp"] as! String,
                        detail: details[0] + " " + detail)
                    uc.wrappedValue[idx].log.append(newSystemLog)
                    dbRepository.messagePersistentOperations.createSystemMessage(chat: newSystemLog, roomid: roomid)
                }
            default:
                print("undefined behaivor")
            }
        }
    }

    func handleArrivedAcceptedFriendRequest(notification: Notification, uf: Binding<[UserFriend]>) {
        let nickname = notification.userInfo!["nickname"] as! String
        let email = notification.userInfo!["fromemail"] as! String

        let newFriend = UserFriend(email: email, nickname: nickname == email ? nil : nickname)
        uf.wrappedValue.append(newFriend)
        dbRepository.friendPersistentOperations.createFriend(friend: newFriend)
    }

    func handleArrivedFriendRemoveRequest(notification: Notification, uf: Binding<[UserFriend]>) {
        let removedFriend = UserFriend(email: notification.userInfo!["audience"] as! String)
        if let idx = uf.wrappedValue.firstIndex(where: { $0.email == removedFriend.email }) {
            uf.wrappedValue.remove(at: idx)
        }
        dbRepository.friendPersistentOperations.remove(friend: removedFriend)
    }
}
