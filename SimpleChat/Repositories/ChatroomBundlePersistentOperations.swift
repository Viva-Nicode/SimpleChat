import Foundation
import Combine

protocol ChatroomBundlePersistentOperations {
    func createNewChatroomBundle(_ chatroomBundle: ChatroomBundle) -> AnyPublisher<ChatroomBundle, Error>
    func readChatroomBundles() -> AnyPublisher<[ChatroomBundle], Error>
    func removeChatroomBundle(bundle: ChatroomBundle) -> AnyPublisher<Int?, Error>
    func changeBundlePosition(bundleId: String, bundlePosition: BundlePosition) -> AnyPublisher<Int?, Error>
    func removeChatroomFromBundle(bundleId: String, chatroomid: String) -> AnyPublisher<Int, Error>
    func appendChatroomsToBundle(bundleId: String, newBundleName: String,
        isExistNewBundleIcon: Bool, chatroomids: [String]) -> AnyPublisher<Int, any Error>
}

struct RealChatroomBundlePersistentOperations: Persistable, ChatroomBundlePersistentOperations {

    let persistentStore: PersistentStore

    func createNewChatroomBundle(_ chatroomBundle: ChatroomBundle) -> AnyPublisher<ChatroomBundle, Error> {
        persistentStore.update {
            chatroomBundle.store(in: $0)
        }.map { ChatroomBundle(chatroomBundleEntity: $0) }
            .eraseToAnyPublisher()
    }

    func removeChatroomBundle(bundle: ChatroomBundle) -> AnyPublisher<Int?, Error> {
        persistentStore.update { bundle.remove(in: $0) }
    }

    func readChatroomBundles() -> AnyPublisher<[ChatroomBundle], Error> {
        let fetchRequest = UserChatroomBundle.fetchRequest()
        return persistentStore.fetch(fetchRequest) {
            $0
        }.map { $0.map { ChatroomBundle(chatroomBundleEntity: $0) } }
            .eraseToAnyPublisher()
    }

    func changeBundlePosition(bundleId: String, bundlePosition: BundlePosition) -> AnyPublisher<Int?, Error> {
        persistentStore.update { ctx in
            let fetchRequest = UserChatroomBundle.fetchRequestById(bundleId)
            let fetchResult = try ctx.fetch(fetchRequest)
            if fetchResult.count == 1 {
                fetchResult.first!.bundlePosition = bundlePosition.rawValue
            }
            return fetchResult.count
        }
    }

    func removeChatroomFromBundle(bundleId: String, chatroomid: String) -> AnyPublisher<Int, any Error> {
        persistentStore.update { ctx in
            let fetchRequest = UserChatroomBundle.fetchRequestById(bundleId)
            let fetchResult = try ctx.fetch(fetchRequest)
            var chatroomidList: [String] = []
            if fetchResult.count == 1 {
                if !fetchResult.first!.chatroomList.isEmpty {
                    chatroomidList = fetchResult.first!.chatroomList.components(separatedBy: ",")
                    if let idx = chatroomidList.firstIndex(where: { $0 == chatroomid }) {
                        chatroomidList.remove(at: idx)
                        fetchResult.first!.chatroomList = chatroomidList.joined(separator: ",")
                        return fetchResult.count
                    } else {
                        return -2
                    }
                } else {
                    return -1
                }
            } else {
                return .zero
            }
        }
    }

    func appendChatroomsToBundle(bundleId: String, newBundleName: String,
        isExistNewBundleIcon: Bool, chatroomids: [String]) -> AnyPublisher<Int, any Error> {
        persistentStore.update { ctx in
            let fetchRequest = UserChatroomBundle.fetchRequestById(bundleId)
            let fetchResult = try ctx.fetch(fetchRequest)
            var result: Int = .zero
            if fetchResult.count == 1 {
                var roomidSet: Set<String> = Set()
                if !fetchResult.first!.chatroomList.isEmpty {
                    roomidSet = Set(fetchResult.first!.chatroomList.components(separatedBy: ","))
                }
                chatroomids.forEach {
                    if roomidSet.insert($0).inserted { result += 1 }
                }
                fetchResult.first!.chatroomList = roomidSet.joined(separator: ",")
                fetchResult.first!.bundleName = newBundleName
                if isExistNewBundleIcon {
                    fetchResult.first!.bundleURL = "chatroomBundlePhoto/\(bundleId)"
                }
                return result
            } else {
                return .zero
            }
        }
    }
}
