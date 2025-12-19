import Foundation
import SwiftUI
import Alamofire

struct DIContainer: EnvironmentKey {
    let interactorContainer: InteractorsContainer
    let userEventHandler: UserEventHandler

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 180
        configuration.timeoutIntervalForResource = 180
        let session = Session(configuration: configuration)

        let accountWebRepository = RealAccountWebRepository(session: session)
        let messageWebRepository = RealMessageWebRepository(session: session)
        let notificationWebRepository = RealNotificationWebRepository(session: session)
        let chatroomWebRepository = RealChatroomWebRepository(session: session)

        let coreDataStack = CoreDataStack.manager

        let chatroomPersistentOperations = RealChatroomPersistentOperations(persistentStore: coreDataStack)
        let friendPersistentOperations = RealFriendPersistentOperations(persistentStore: coreDataStack)
        let messagePersistentOperations = RealMessagePersistentOperations(persistentStore: coreDataStack)
        let chatroomBundlePersistentOperations = RealChatroomBundlePersistentOperations(persistentStore: coreDataStack)

        let coreDataOperationsContainer = DBOperationsContainer(
            chatroomPersistentOperations: chatroomPersistentOperations,
            friendPersistentOperations: friendPersistentOperations,
            messagePersistentOperations: messagePersistentOperations,
            chatroomBundlePersistentOperations: chatroomBundlePersistentOperations)

        self.interactorContainer = InteractorsContainer(
            RealUserInteractor(webRepository: accountWebRepository, dbRepository: coreDataOperationsContainer),
            RealMessageInteractor(webRepository: messageWebRepository, dbRepository: coreDataOperationsContainer),
            RealNotificationInteractor(webRepository: notificationWebRepository, dbRepository: coreDataOperationsContainer),
            RealChatroomInteractor(webRepository: chatroomWebRepository, dbRepository: coreDataOperationsContainer))

        self.userEventHandler = ConcreteUserEventHandler(dbRepository: coreDataOperationsContainer)
    }

    static var defaultValue: Self { Self.default }
    private static let `default` = Self()
}

extension EnvironmentValues {
    var injected: DIContainer {
        get { self[DIContainer.self] }
        set { self[DIContainer.self] = newValue }
    }
    // self[InteractorsContainer.self] 에서 가장 왼쪽 self는 struct EnvironmentValues를 의미한다.
    // struct EnvironmentValues는 딕셔너리 형태인데, 아래와 같이 subscript가 정의 되어있다.
    // public subscript<K>(key: K.Type) -> K.Value where K : EnvironmentKey
    // 따라서 어떤 타입(InteractorsContainer.self)을 키값으로, 저장된 환경 변수를 반환한다.
}
