import SwiftUI
import Combine
import Foundation
import Alamofire

extension DIContainer {
    struct InteractorsContainer {
        let userInteractor: UserInteractor
        let messageInteractor: MessageInteractor
        let notificationInteractor: NotificationInteractor
        let chatroomInteractor: ChatroomInteractor

        init(_ userInteractor: UserInteractor, _ messageInteractor: MessageInteractor,
            _ notificationInteractor: NotificationInteractor, _ chatroomInteractor: ChatroomInteractor) {
            self.userInteractor = userInteractor
            self.messageInteractor = messageInteractor
            self.notificationInteractor = notificationInteractor
            self.chatroomInteractor = chatroomInteractor
        }
    }
}
