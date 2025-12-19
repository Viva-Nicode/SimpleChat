//
//  PushNotificationsHandler.swift
//  Capstone_2
//
//  Created by Nicode . on 3/14/24.
//

import Foundation
import UserNotifications
import SDWebImageSwiftUI

enum RemoteNotificationTypes: String {
    case arrivedMessage = "receive"
    case arrivedReaction = "react"
    case messageReading = "reply"
    case arrivedSystemMessage = "syslog"
    case arrivedFriendRequest = "friendAddNoti"
    case acceptedFriendRequest = "friendAddReplyNoti"
    case removeFriend = "removeFriend"
    case knellVoicechat = "knellVoicechat"

}


extension Notification.Name {
    static let arrivedMessage = Notification.Name("arrivedMessage")
    static let arrivedReaction = Notification.Name("arrivedReaction")
    static let arrivedSystemMessage = Notification.Name("arrivedSystemMessage")
    static let arrivedFriendRequest = Notification.Name("arrivedFriendRequest")
    static let acceptedFriendRequest = Notification.Name("acceptedFriendRequest")
    static let messageReading = Notification.Name("messageReading")
    static let completeDataInit = Notification.Name("completeDataInit")
    static let removeFriend = Notification.Name("removeFriend")

    static let openedByRemoteNotificationFromBackground = Notification.Name("openedByRemoteNotificationFromBackground")
    static let updatedMyProfilePhoto = Notification.Name("updatedMyProfilePhoto")
    static let updateMyBackgroundPhoto = Notification.Name("updateMyBackgroundPhoto")
    static let updatedFriendProfilePhoto = Notification.Name("updatedFriendProfilePhoto")
    static let updatedChatroomProfilePhoto = Notification.Name("updatedChatroomProfilePhoto")
    static let updatedChatroomBackgroundPhoto = Notification.Name("updatedChatroomBackgroundPhoto")
}

@available(iOS 10, *)
extension AppDelegate: UNUserNotificationCenterDelegate {


    // 앱이 foreground 상태에서 푸시를 받았을 때
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        if receivedMessageIdentifierSet.contains(notification.request.identifier) {
            completionHandler([])
            return
        } else {
            receivedMessageIdentifierSet.insert(notification.request.identifier)
        }

        var userInfo = notification.request.content.userInfo
        let remoteNotificationType = RemoteNotificationTypes(rawValue: userInfo["notitype"] as! String)
        print(remoteNotificationType?.rawValue ?? "")

        switch remoteNotificationType {
        case .arrivedMessage:
            print("arrived Message")
            guard let aps = userInfo["aps"] as? Dictionary<String, Any> else { return }
            if let v = aps["alert"] {
                let dic = v as! Dictionary<String, String> as Dictionary
                userInfo["sender"] = dic["title"]!
                userInfo["notificationIdentifier"] = notification.request.identifier

                NotificationCenter.default.post(name: .arrivedMessage, object: nil, userInfo: userInfo)
            }

            if let currentChatroomid = self.currentViewObject.currentChatroomid {
                if currentChatroomid == userInfo["roomid"] as! String {
                    completionHandler([])
                }
            }

            if let _ = UserDefaults.standard.string(forKey: "notiState-\(userInfo["roomid"] as! String)") {
                completionHandler([])
            } else {
                completionHandler([[.banner, .badge, .sound]])
            }

        case .messageReading:
            print("arrived message reading remote notification")
            NotificationCenter.default.post(name: .messageReading, object: nil, userInfo: userInfo)
            completionHandler([])

        case .arrivedReaction:
            NotificationCenter.default.post(name: .arrivedReaction, object: nil, userInfo: userInfo)
            completionHandler([])

        case .arrivedSystemMessage:
            NotificationCenter.default.post(name: .arrivedSystemMessage, object: nil, userInfo: userInfo)
            completionHandler([])

        case .arrivedFriendRequest:
            NotificationCenter.default.post(name: .arrivedFriendRequest, object: nil, userInfo: userInfo)
            completionHandler([[.banner, .badge, .sound]])

        case .acceptedFriendRequest:
            NotificationCenter.default.post(name: .acceptedFriendRequest, object: nil, userInfo: userInfo)
            completionHandler([])

        case .removeFriend:
            NotificationCenter.default.post(name: .removeFriend, object: nil, userInfo: userInfo)
            completionHandler([])

        case .knellVoicechat:
            completionHandler([[.banner, .badge, .sound]])

        default:
            print("undefined notification type")
        }
    }

    // 백, 포그라운드에서 push notification을 탭한경우
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void) {
        var userInfo = response.notification.request.content.userInfo
        print("tap noti")
        userInfo["isTapedOnForeground"] = UIApplication.shared.applicationState == .active
        handleRemoteNotification(userInfo: userInfo)
        completionHandler()
    }

    func handleRemoteNotification(userInfo: [AnyHashable: Any]) {
        let remoteNotificationType = RemoteNotificationTypes(rawValue: userInfo["notitype"] as! String)

        switch remoteNotificationType {
        case .arrivedMessage:
            NotificationCenter.default.post(name: .openedByRemoteNotificationFromBackground, object: nil, userInfo: userInfo)
        case .messageReading:
            NotificationCenter.default.post(name: .openedByRemoteNotificationFromBackground, object: nil, userInfo: userInfo)

        default:
            print("undefined notification type")
        }
    }
}
