//
//  ChatroomInteractor.swift
//  SimpleChat
//
//  Created by Nicode . on 4/7/24.
//

import Foundation
import Combine
import Alamofire
import SwiftUI
import SDWebImageSwiftUI

protocol ChatroomInteractor {

    func createChatroom(_ email: String, _ members: [String], _ roomtype: String, _ uc: Binding<[UserChatroom]>,
        _ friends: [UserFriend], _ title: Binding<[String:String]>) -> AnyPublisher<UserChatroom, AFError>

    func inviteUser(email: String, audiences: [String], chatroomid: String,
        _ uc: Binding<[UserChatroom]>, _ shouldShowNewuserInviteView: Binding<Bool>) -> AnyCancellable

    func exitChatroom(_ email: String, _ chatroomid: String, _ uc: Binding<[UserChatroom]>,
        _ title: Binding<[String:String]>) -> AnyCancellable

    func readMessage(_ email: String, _ chatroomid: String, _ uc: Binding<[UserChatroom]>) -> AnyCancellable

    func startPairChat(_ email: String, _ audience: String, _ nickname: String, _ pairChatroomid: Binding<String>,
        _ title: Binding<[String:String]>, _ uc: Binding<[UserChatroom]>, _ subscription: Binding<Set<AnyCancellable>>)

    func modifyChatroomTitle(chatroomid: String, newTitle: String, title: Binding<String>, titleTable: Binding<[String:String]>) -> AnyCancellable

    func modifyChatroomProfilePhoto(chatroomid: String, newPhoto: UIImage)

    func modifyChatroomBackgroundPhoto(chatroomid: String, newPhoto: UIImage)

    func setChatroomNotification(email: String, chatroomid: String, notiStata: Binding<Bool>,
        isFlipped: Binding<Bool>, filpBackground: Binding<Bool>) -> AnyCancellable

    func createChatroomBundle(bundleName: String, bundleProfileImage: UIImage?,
        chatroomBundles: Binding<[ChatroomBundle]>, selectedRoomIdList: [String]) -> AnyCancellable

    func removeChatroomBundle(bundle: ChatroomBundle, chatroomBundles: Binding<[ChatroomBundle]>) -> AnyCancellable

    func changeBundlePosition(bundleId: String, position: BundlePosition, chatroomBundles: Binding<[ChatroomBundle]>) -> AnyCancellable

    func removeChatroomFromBundle(bundleId: String, chatroomid: String, chatroomBundles: Binding<[ChatroomBundle]>) -> AnyCancellable

    func editingBundle(bundleId: String, newBundleName: String, bundleIconImage: UIImage?,
        chatroomids: [String], chatroomBundles: Binding<[ChatroomBundle]>) -> AnyCancellable
}


struct RealChatroomInteractor: ChatroomInteractor {

    let webRepository: ChatroomWebRepository
    let dbRepository: DBOperationsContainer

    func createChatroom(_ email: String, _ members: [String], _ roomtype: String, _ uc: Binding<[UserChatroom]>,
        _ friends: [UserFriend], _ title: Binding<[String:String]>) -> AnyPublisher<UserChatroom, AFError> {

        webRepository.createChatroom(email: email, members: members, roomtype: roomtype)
            .map { newChatroom in
            uc.wrappedValue.append(newChatroom)
            dbRepository.chatroomPersistentOperations.createChatroom(chatroom: newChatroom)

            let newChatroomTitle = newChatroom.audiencelist
                .filter { $0 != email }
                .map { audi in friends.first(where: { $0.email == audi })?.nickname ?? audi }
                .sorted()
                .joined(separator: ",")

            title.wrappedValue[newChatroom.chatroomid] = newChatroomTitle
            return newChatroom
        }.eraseToAnyPublisher()
    }

    func inviteUser(email: String, audiences: [String], chatroomid: String,
        _ uc: Binding<[UserChatroom]>, _ shouldShowNewuserInviteView: Binding<Bool>) -> AnyCancellable {

        webRepository.inviteUser(email: email, audience: audiences.joined(separator: " "), chatroomid: chatroomid)
            .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                print("inviteUser finished")
                shouldShowNewuserInviteView.wrappedValue = false
            case .failure(let error):
                print(error.errorDescription ?? "nil")
            }
        }, receiveValue: { syslogs in
                if let idx = uc.wrappedValue.firstIndex(where: { $0.chatroomid == chatroomid }) {
                    syslogs.forEach { syslog in
                        dbRepository.messagePersistentOperations.createSystemMessage(chat: syslog, roomid: chatroomid)
                        uc.wrappedValue[idx].log.append(syslog)
                    }
                    audiences.forEach { audience in
                        dbRepository.chatroomPersistentOperations.insertMember(member: audience, roomid: chatroomid)
                        uc.wrappedValue[idx].audiencelist.insert(audience)
                    }
                }
            }
        )
    }

    func exitChatroom(_ email: String, _ chatroomid: String, _ uc: Binding<[UserChatroom]>,
        _ title: Binding<[String:String]>) -> AnyCancellable {

        if let idx = uc.wrappedValue.firstIndex(where: { $0.chatroomid == chatroomid }) {
            return webRepository.exitChatroom(email: email, chatroomid: chatroomid, chatroomtype: uc.wrappedValue[idx].roomtype)
                .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("exitChatroom finished")
                case .failure(let error):
                    print(error.errorDescription ?? "nil")
                }
            }, receiveValue: { res in
                    if res.code == .success {
                        dbRepository.chatroomPersistentOperations.removeChatroom(chatroom: uc.wrappedValue[idx])
                        UserDefaults.standard.removeObject(forKey: "notiState-\(chatroomid)")
                        title.wrappedValue.removeValue(forKey: chatroomid)
                        uc.wrappedValue.remove(at: idx)
                    }
                }
            )
        } else {
            debugPrint("방을 나가려했지만 방을 찾을 수 없음.")
            return Just<Void>.withErrorType(AFError.self).sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        }
    }

    func modifyChatroomProfilePhoto(chatroomid: String, newPhoto: UIImage) {
        let cacheKey = "chatroomPhoto\(chatroomid)"
        SDImageCache.shared.removeImage(forKey: cacheKey, withCompletion: {
            SDImageCache.shared.store(newPhoto, forKey: cacheKey, completion: {
                NotificationCenter.default.post(name: .updatedChatroomProfilePhoto, object: nil, userInfo: ["roomid": chatroomid])
            })
        })
    }

    func modifyChatroomBackgroundPhoto(chatroomid: String, newPhoto: UIImage) {
        let cacheKey = "chatroomBackground\(chatroomid)"
        SDImageCache.shared.removeImage(forKey: cacheKey, withCompletion: {
            SDImageCache.shared.store(newPhoto, forKey: cacheKey, completion: {
                NotificationCenter.default.post(name: .updatedChatroomBackgroundPhoto, object: nil, userInfo: ["roomid": chatroomid])
            })
        })
    }

    func readMessage(_ email: String, _ chatroomid: String, _ uc: Binding<[UserChatroom]>) -> AnyCancellable {
        if let idx = uc.wrappedValue.firstIndex(where: { $0.chatroomid == chatroomid }) {
            var unreadchatidlist: [String] = []
            var messageTypeList: [String] = []
            var readMessage: [() -> Void] = []

            for logidx in 0..<uc.wrappedValue[idx].log.count {
                if let chat = uc.wrappedValue[idx].log[logidx] as? UserChatLog {
                    if !(chat.readusers.contains(email)) {
                        unreadchatidlist.append(chat.id)
                        messageTypeList.append(chat.logType.rawValue)
                        readMessage.append({ uc.wrappedValue[idx].log[logidx].addReadusers(user: email) })
                    }
                }
            }

            if !unreadchatidlist.isEmpty {

                UNUserNotificationCenter.current().getDeliveredNotifications { remoteNotifications in
                    for notification in remoteNotifications {
                        if let notificationType = notification.request.content.userInfo["chatroomid"] {
                            if notificationType as! String == chatroomid {
                                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notification.request.identifier])
                            }
                        }
                    }
                }

                return webRepository.readMessage(email: email, chatroomid: chatroomid, chatidlist: unreadchatidlist, chattypelist: messageTypeList)
                    .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            print("readMessage finished")
                        case .failure(let error):
                            print(error.errorDescription ?? "nil")
                        }
                    },
                    receiveValue: { result in
                        if result.code == .success {
                            for read in readMessage { read() }
                            dbRepository.messagePersistentOperations.insertReadUser(email: email, roomid: chatroomid, chatids: unreadchatidlist)

                            UNUserNotificationCenter.current().getDeliveredNotifications { remoteNotifications in
                                for notification in remoteNotifications {
                                    if let roomid = notification.request.content.userInfo["roomid"] {
                                        if roomid as! String == chatroomid {
                                            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notification.request.identifier])
                                        }
                                    }
                                }
                            }
                        }
                    }
                )
            } else {
                print("not exist non-read messages")
                return Just<Void>.withErrorType(AFError.self).sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            }
        } else {
            print("can not found chatroom")
            return Just<Void>.withErrorType(AFError.self).sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        }
    }

    func startPairChat(_ email: String, _ audience: String, _ nickname: String, _ pairChatroomid: Binding<String>,
        _ title: Binding<[String:String]>, _ uc: Binding<[UserChatroom]>, _ subscription: Binding<Set<AnyCancellable>>) {

        for chatroom in uc.wrappedValue {
            if chatroom.roomtype == .pair && chatroom.audiencelist.contains(email) && chatroom.audiencelist.contains(audience) {
                pairChatroomid.wrappedValue = chatroom.chatroomid
                return
            }
        }

        webRepository.startPairChat(email: email, audience: audience)
            .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                print("start pairChatroom finished")
            case .failure(let error):
                print(error.errorDescription ?? "nil")
            }
        }, receiveValue: { newChatroom in
                uc.wrappedValue.append(newChatroom)
                dbRepository.chatroomPersistentOperations.createChatroom(chatroom: newChatroom)
                title.wrappedValue[newChatroom.chatroomid] = nickname
                pairChatroomid.wrappedValue = newChatroom.chatroomid
            }
        ).store(in: &subscription.wrappedValue)
    }

    func setChatroomNotification(email: String, chatroomid: String, notiStata: Binding<Bool>,
        isFlipped: Binding<Bool>, filpBackground: Binding<Bool>) -> AnyCancellable {
        webRepository.setChatroomNotification(email: email, chatroomid: chatroomid)
            .sink(receiveCompletion: { _ in }, receiveValue: {
                if $0.code == .success {
                    UserDefaults.standard.set("true", forKey: "notiState-\(chatroomid)")
                } else {
                    UserDefaults.standard.removeObject(forKey: "notiState-\(chatroomid)")
                }
                notiStata.wrappedValue = $0.code == .success
                withAnimation(.easeInOut(duration: 0.6)) {
                    isFlipped.wrappedValue = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        filpBackground.wrappedValue = false
                    }
                }
            })
    }

    func modifyChatroomTitle(chatroomid: String, newTitle: String, title: Binding<String>, titleTable: Binding<[String:String]>) -> AnyCancellable {
        dbRepository.chatroomPersistentOperations.updateChatroomTitle(title: newTitle, roomid: chatroomid)
            .sink(receiveCompletion: { _ in },
            receiveValue: { value in
                if value == 1 {
                    print("scu")
                    title.wrappedValue = newTitle
                    titleTable.wrappedValue[chatroomid] = newTitle
                } else {
                    print("fail : \(value)")
                }
            }
        )
    }

    func createChatroomBundle(bundleName: String, bundleProfileImage: UIImage?,
        chatroomBundles: Binding<[ChatroomBundle]>, selectedRoomIdList: [String]) -> AnyCancellable {
        let bundleId = UUID().uuidString

        if let bundleProfileImage {
            let cacheKey = "chatroomBundlePhoto/\(bundleId)"

            SDImageCache.shared.store(bundleProfileImage, forKey: cacheKey)

            let chatroomBundle = ChatroomBundle(
                bundleID: bundleId,
                bundleName: bundleName,
                bundleURL: cacheKey,
                bundlePosition: .none,
                chatroomList: selectedRoomIdList)

            return dbRepository.chatroomBundlePersistentOperations.createNewChatroomBundle(chatroomBundle)
                .sink(receiveCompletion: { _ in }, receiveValue: { newBundle in
                    withAnimation(.spring(duration: 0.3)) {
                        chatroomBundles.wrappedValue.append(newBundle)
                    }
                }
            )
        } else {
            let chatroomBundle = ChatroomBundle(
                bundleID: bundleId,
                bundleName: bundleName,
                bundlePosition: .none,
                chatroomList: selectedRoomIdList
            )

            return dbRepository.chatroomBundlePersistentOperations.createNewChatroomBundle(chatroomBundle)
                .sink(receiveCompletion: { _ in }, receiveValue: { newBundle in
                    withAnimation(.spring(duration: 0.3)) {
                        chatroomBundles.wrappedValue.append(newBundle)
                    }
                }
            )
        }
    }

    func removeChatroomBundle(bundle: ChatroomBundle, chatroomBundles: Binding<[ChatroomBundle]>) -> AnyCancellable {
        dbRepository.chatroomBundlePersistentOperations.removeChatroomBundle(bundle: bundle)
            .sink(receiveCompletion: { _ in }, receiveValue: { count in
                if count == 1 {
                    if let idx = chatroomBundles.wrappedValue.firstIndex(where: { $0.bundleID == bundle.bundleID }) {
                        withAnimation(.spring(duration: 0.3)) {
                            let _ = chatroomBundles.wrappedValue.remove(at: idx)
                        }
                    }
                }
            }
        )
    }

    func removeChatroomFromBundle(bundleId: String, chatroomid: String, chatroomBundles: Binding<[ChatroomBundle]>) -> AnyCancellable {
        dbRepository.chatroomBundlePersistentOperations.removeChatroomFromBundle(bundleId: bundleId, chatroomid: chatroomid)
            .sink(receiveCompletion: { _ in }, receiveValue: { result in
                if result == 1 {
                    if let bundleIdx = chatroomBundles.wrappedValue.firstIndex(where: { $0.bundleID == bundleId }) {
                        if let roomIdx = chatroomBundles.wrappedValue[bundleIdx].bundleChatroomList.firstIndex(where: { $0 == chatroomid }) {
                            withAnimation(.spring(duration: 0.3)) {
                                let _ = chatroomBundles.wrappedValue[bundleIdx].bundleChatroomList.remove(at: roomIdx)
                            }
                        }
                    }
                } else {
                    print("result : \(result)")
                }
            }
        )
    }

    func changeBundlePosition(bundleId: String, position: BundlePosition, chatroomBundles: Binding<[ChatroomBundle]>) -> AnyCancellable {
        dbRepository.chatroomBundlePersistentOperations.changeBundlePosition(bundleId: bundleId, bundlePosition: position)
            .sink(receiveCompletion: { _ in }, receiveValue: { result in
                if result == 1 {
                    if let idx = chatroomBundles.wrappedValue.firstIndex(where: { $0.bundleID == bundleId }) {
                        chatroomBundles.wrappedValue[idx].bundlePosition = position
                    }
                }
            }
        )
    }

    func editingBundle(bundleId: String, newBundleName: String, bundleIconImage: UIImage?,
        chatroomids: [String], chatroomBundles: Binding<[ChatroomBundle]>) -> AnyCancellable {
        dbRepository.chatroomBundlePersistentOperations.appendChatroomsToBundle(
            bundleId: bundleId, newBundleName: newBundleName,
            isExistNewBundleIcon: bundleIconImage != nil, chatroomids: chatroomids)
            .sink(receiveCompletion: { _ in }, receiveValue: { result in
                if result == chatroomids.count {
                    if let bundleIdx = chatroomBundles.wrappedValue.firstIndex(where: { $0.bundleID == bundleId }) {
                        withAnimation(.spring(duration: 0.3)) {
                            chatroomBundles.wrappedValue[bundleIdx].bundleChatroomList.append(contentsOf: chatroomids)
                            chatroomBundles.wrappedValue[bundleIdx].bundleName = newBundleName
                        }
                        if let bundleIconImage {
                            let cacheKey = "chatroomBundlePhoto/\(bundleId)"
                            SDImageCache.shared.removeImage(forKey: cacheKey)
                            SDImageCache.shared.store(bundleIconImage, forKey: cacheKey)
                            chatroomBundles.wrappedValue[bundleIdx].bundleProfileURL = cacheKey
                        }
                        NotificationCenter.default.post(name: .updatedBundleIcon, object: nil, userInfo: nil)
                    }
                } else {
                    print("error : editing bundle")
                }
            }
        )
    }
}

