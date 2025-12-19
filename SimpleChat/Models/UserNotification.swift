import Foundation

enum UserNotificationTypes: String {
    case friendRequest = "friendRequest"
    case undefinedNotification = "undefinedNotification"
}

struct UserNotification: TimeStampable, Equatable, Hashable {

    var fromEmail: String
    var notificationType: UserNotificationTypes
    var timestamp: Date

    static func == (lhs: UserNotification, rhs: UserNotification) -> Bool {
        return lhs.fromEmail == rhs.fromEmail && lhs.notificationType == rhs.notificationType
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(fromEmail)
        hasher.combine(notificationType)
    }

    init(fromEmail: String, notitype: String, timestamp: String) {
        self.fromEmail = fromEmail
        self.notificationType = UserNotificationTypes(rawValue: notitype) ?? UserNotificationTypes.undefinedNotification
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.timestamp = dateFormatter.date(from: timestamp)!
    }

    init(_ responseModel: UserDataFetchResponseModel.UserNotificationResponseModel) {
        self.fromEmail = responseModel.fromemail
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.timestamp = dateFormatter.date(from: responseModel.timestamp)!
        self.notificationType = UserNotificationTypes(rawValue: responseModel.notitype) ?? UserNotificationTypes.undefinedNotification
    }
}
