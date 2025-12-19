import Foundation
import Combine

protocol Persistable { var persistentStore: PersistentStore { get } }

struct DBOperationsContainer {
    let chatroomPersistentOperations: ChatroomPersistentOperations
    let friendPersistentOperations: FriendPersistentOperations
    let messagePersistentOperations: MessagePersistentOperations
    let chatroomBundlePersistentOperations: ChatroomBundlePersistentOperations
}
