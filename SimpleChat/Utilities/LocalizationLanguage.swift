import Foundation
import SwiftUI

enum LocalizationString {

    static let reportReasonOther: LocalizedStringKey = "Other"
    static let reportReason_1: LocalizedStringKey = "Inappropriate nickname and profile picture, background picture"
    static let reportReason_2: LocalizedStringKey = "Chat that violates the terms of service"

    static func startSystemMessage(_ members: String) -> String {
        String(format: NSLocalizedString("%@ joined this chatroom.", comment: ""), arguments: [members])
    }

    static func exitSystemMessage(_ member: String) -> String {
        String(format: NSLocalizedString("%@ left this chatroom.", comment: ""), arguments: [member])
    }

    static func enterSystemMessage(_ inviter: String, _ member: String) -> String {
        String(format: NSLocalizedString("%@ invited %@", comment: ""), arguments: [inviter, member])
    }

    static let completeReportUserMessageText: LocalizedStringKey
        = "This matter will be reviewed within 24 hours,\nand if inappropriate activity is confirmed, the user’s access to the service will be suspended."
    static let accountFailReason_emailFormat: LocalizedStringKey = "It is not a valid email format."
    static let accountFailReason_passwordLength: LocalizedStringKey = "There must be no more than 8 passwords and no more than 20."

    static let seconds = NSLocalizedString("s", comment: "")
    static let minutes = NSLocalizedString("m", comment: "")
    static let hour = NSLocalizedString("h", comment: "")
    static let day = NSLocalizedString("day", comment: "")
    static let month = NSLocalizedString("month", comment: "")
    static let year = NSLocalizedString("year", comment: "")
    static let now = NSLocalizedString("now", comment: "")

    static let videoConverting = NSLocalizedString("Video Converting", comment: "")
    static let thumbnailCreating = NSLocalizedString("Thumbnail Creating", comment: "")

    static let noTitleVideo = NSLocalizedString("No Title Video", comment: "")
    static let photoMessage = NSLocalizedString("photo", comment: "")
    static let blockedMessage = NSLocalizedString("blocked message", comment: "")
}

extension LocalizedStringKey {
    func toString() -> String {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let value = child.value as? String {
                return value
            }
        }
        return ""
    }
}

