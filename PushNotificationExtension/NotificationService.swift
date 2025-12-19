import UserNotifications
import Intents
import UIKit
import SwiftUI

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {

        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        let baseURL: String = "http://1.246.134.84/rest/get-thumbnail/"
//        let baseURL: String = "http://localhost:51699/rest/get-thumbnail/"

        if let notificationType = bestAttemptContent?.userInfo["notitype"] as? String {
            if ["receive", "friendAddNoti", "reply", "knellVoicechat"].contains(notificationType) {
                if let aps = bestAttemptContent?.userInfo["aps"] as? Dictionary<String, Any> {
                    if let alertInfo = aps["alert"] {
                        let dic = alertInfo as! Dictionary<String, String> as Dictionary
                        if let titleSender = dic["title"] {
                            if let imageURL = URL(string: baseURL + titleSender) {
                                if let sender = bestAttemptContent?.userInfo["sender"] as? String {
                                    downloadImage(from: imageURL) { imageData in
                                        if let data = imageData {
                                            self.setAppIconToCustom(imageData: data,
                                                sender: sender,
                                                request: request,
                                                notificationType: notificationType,
                                                contentHandler: contentHandler)
                                        } else {
                                            NSLog("data is nil")
                                            contentHandler(request.content)
                                        }
                                    }
                                } else {
                                    NSLog("sender else")
                                    contentHandler(request.content)
                                }
                            } else {
                                NSLog("URL else")
                                contentHandler(request.content)
                            }
                        } else {
                            NSLog("title else")
                            contentHandler(request.content)
                        }
                    } else {
                        NSLog("alert nil")
                        contentHandler(request.content)
                    }
                } else {
                    NSLog("aps nil")
                    contentHandler(request.content)
                }
            } else {
                NSLog("is not receive or friendAddNoti")
                contentHandler(request.content)
            }
        } else {
            NSLog("can not found notitype")
            contentHandler(request.content)
        }
    }

    private func downloadImage(from url: URL, completion: @escaping (Data?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, error == nil {
                completion(data)
            } else {
                NSLog("Error downloading image: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
        task.resume()
    }

    private func setAppIconToCustom(imageData: Data, sender: String, request: UNNotificationRequest, notificationType: String,
        contentHandler: @escaping (UNNotificationContent) -> Void) {

        let avatar = INImage(imageData: imageData)

        let senderPerson = INPerson(
            personHandle: INPersonHandle(value: "unique-sender-id-2", type: .unknown),
            nameComponents: nil,
            displayName: sender,
            image: avatar,
            contactIdentifier: nil,
            customIdentifier: nil,
            isMe: false,
            suggestionType: .none)

        let intent = INSendMessageIntent(recipients: [],
            outgoingMessageType: .outgoingMessageText,
            content: "Message content",
            speakableGroupName: nil,
            conversationIdentifier: "unique-conversation-id-1",
            serviceName: nil,
            sender: senderPerson,
            attachments: nil)

        intent.setImage(avatar, forParameterNamed: \.sender)

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .incoming

        interaction.donate { error in
            if let error = error {
                print(error)
                return
            }
            do {
                let updatedContent = try request.content.updating(from: intent)
                if notificationType == "reply" {
                    let mutableContent = (updatedContent.mutableCopy() as? UNMutableNotificationContent) ?? UNMutableNotificationContent()

                    mutableContent.body = String(localized: "Your message was read")
                    contentHandler(mutableContent)
                } else if notificationType == "friendAddNoti" {
                    let mutableContent = (updatedContent.mutableCopy() as? UNMutableNotificationContent) ?? UNMutableNotificationContent()

                    mutableContent.body = String(localized: "arrived friend Request")
                    contentHandler(mutableContent)
                } else if notificationType == "knellVoicechat" {
                    let mutableContent = (updatedContent.mutableCopy() as? UNMutableNotificationContent) ?? UNMutableNotificationContent()

                    mutableContent.body = String(localized: "join the voice chatroom")
                    contentHandler(mutableContent)
                } else {
                    contentHandler(updatedContent)
                }
            } catch {
                print(error)
            }
        }
    }

    override func serviceExtensionTimeWillExpire() { }
}
