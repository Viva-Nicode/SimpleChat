//
//  AppDelegate.swift
//  SimpleChat
//
//  Created by Nicode . on 4/3/24.
//

import Foundation
import SwiftUI
import Alamofire
import Firebase
import FirebaseCore
import FirebaseMessaging
import SDWebImageSwiftUI


class AppDelegate: NSObject, UIApplicationDelegate {

    let gcmMessageIDKey = "gcm.message_id"
    var receivedMessageIdentifierSet = Set<String>()
    @ObservedObject var currentViewObject: CurrentViewObject = CurrentViewObject()

    // 앱이 켜졌을 때
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        #if DEBUG
            print("debuging...")
        #else
            FirebaseApp.configure()

            if #available(iOS 10.0, *) {
                UNUserNotificationCenter.current().delegate = self

                let authOption: UNAuthorizationOptions = [.alert, .badge, .sound]
                UNUserNotificationCenter.current().requestAuthorization(
                    options: authOption,
                    completionHandler: { isAllow, error in })
            } else {
                let settings: UIUserNotificationSettings =
                    UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
                application.registerUserNotificationSettings(settings)
            }

            application.registerForRemoteNotifications()

            Messaging.messaging().delegate = self
            UNUserNotificationCenter.current().delegate = self

        #endif
        return true
    }

    // 앱이 꺼졌을 떄
    func applicationWillTerminate(_ application: UIApplication) {
        print("applicationWillTerminate return")
    }

    // fcm 토큰이 등록 되었을 때
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("apns token : \(deviceToken)")
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("error : \(error.localizedDescription)")
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("fcm token : \(fcmToken ?? "")")
        UserDefaultsKeys.fcmToken.setValue(fcmToken)
    }
}
