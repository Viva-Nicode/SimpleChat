import Foundation
import CoreData
import Combine
import SwiftUI

/**
 이 클래스는 NSManagedObjectContext가 제공해주는 인터페이스들을 앱의 비즈니스에 적합하게 한번더 추상화한다.
 */

protocol PersistentStore {
    func fetch<T, V>(_ fetchRequest: NSFetchRequest<T>, map: @escaping (T) throws -> V?) -> AnyPublisher<[V], Error>

    @discardableResult
    func update<Result>(_ operation: @escaping (NSManagedObjectContext) throws -> Result) -> AnyPublisher<Result, Error>
}

class CoreDataStack: PersistentStore {
    private let isStoreLoaded = CurrentValueSubject<Bool, Error>(false)
    private let container: NSPersistentContainer
    private let bgQueue = DispatchQueue(label: "coredata")
    private let queueKey = DispatchSpecificKey<String>()
    public var resetChildContext: (() -> Void)?
    public static let manager: CoreDataStack = .init()

    private init() {

        bgQueue.setSpecific(key: queueKey, value: "coredata")

        #if DEBUG
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            let persistentContainer = NSPersistentContainer(name: "SimpleChat")
            persistentContainer.persistentStoreDescriptions = [description]
            container = persistentContainer

            bgQueue.async { [weak isStoreLoaded, weak container] in
                container?.loadPersistentStores { (storeDescription, error) in
                    DispatchQueue.main.async {
                        if let error = error {
                            isStoreLoaded?.send(completion: .failure(error))
                        } else {
                            container?.viewContext.configureAsReadOnlyContext()
                            isStoreLoaded?.send(true)
                        }
                    }
                }
            }
        #else
            container = NSPersistentContainer(name: "SimpleChat")

            bgQueue.async { [weak isStoreLoaded, weak container] in
                container?.loadPersistentStores { (storeDescription, error) in
                    DispatchQueue.main.async {
                        if let error = error {
                            isStoreLoaded?.send(completion: .failure(error))
                        } else {
                            container?.viewContext.configureAsReadOnlyContext()
                            isStoreLoaded?.send(true)
                        }
                    }
                }
            }
        #endif
    }

    func printAllEntities() {
        let context = container.viewContext
        let entityNames = container.managedObjectModel.entities.compactMap { $0.name }

        entityNames.forEach { entityName in
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
            do {
                let results = try context.fetch(fetchRequest)
                print("Entity: \(entityName), Count: \(results.count)")
                results.forEach {
                    if let userChatroom = $0 as? UserChatroomEntity {
                        print("Chatroom id: \(userChatroom.chatroomid)")
                        print("Chatroom audiencelist: \(userChatroom.audiencelist)")
                        print("Chatroom type: \(userChatroom.chatroomtype)")
                        print("Chatroom title: \(userChatroom.chatroomTitle ?? "N/A")")
                    } else if let userFriend = $0 as? UserFriendEntity {
                        print("friend email: \(userFriend.email)")
                        print("friend nickname: \(userFriend.nickname ?? "N/A")")
                    } else if let userMessage = $0 as? UserMessageEntity {
                        print("message id: \(userMessage.chatid)")
                        print("message type: \(userMessage.messageType)")
                        print("message writer: \(userMessage.writer)")
                        print("message detail: \(userMessage.detail)")
                        print("message readusers: \(userMessage.readusers)")
                        print("message timestamp: \(userMessage.timestamp)")
                    } else if let systemMessage = $0 as? UserSystemMessageEntity {
                        print("systemMessage id: \(systemMessage.sysid)")
                        print("systemMessage type: \(systemMessage.type)")
                        print("systemMessage detail: \(systemMessage.detail)")
                        print("systemMessage timestamp: \(systemMessage.timestamp)")
                    } else {
                        print("undefined entity")
                    }
                }
            } catch {
                print("Failed to fetch \(entityName): \(error)")
            }
        }
    }

    func fetch<T, V>(_ fetchRequest: NSFetchRequest<T>, map: @escaping (T) throws -> V?) -> AnyPublisher<[V], Error> {
        let fetch = Future<[V], Error> { [weak container] promise in
            guard let context = container?.viewContext else { return }
            context.performAndWait {
                do {
                    let managedObjects = try context.fetch(fetchRequest)
                    let results = try managedObjects.map { try map($0)! }
                    promise(.success(results))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        return onStoreIsReady
            .flatMap { fetch }
            .eraseToAnyPublisher()
    }

    func update<Result>(_ operation: @escaping (NSManagedObjectContext) throws -> Result) -> AnyPublisher<Result, Error> {
        let update = Future<Result, Error> { [weak bgQueue, weak container] promise in
            /** bgQueue?.async {} 블록 안의 코드를 bgQueue 스레드에서 실행하고 update()를 호출한 메인 스레드는 즉시 자기할일 하러간다.*/
            bgQueue?.async {
                /**
                 viewContext가 아닌 newBackgroundContext()로 새로운 context를 생성하여 사용한 이유.
                 newBackgroundContext() : persistent container가 concurrencyType이 privateQueueConcurrencyType인 NSManagedObjectContext를 만들고 리턴해준다.
                 
                 스레드 안전성:
                 viewContext는 기본적으로 메인 스레드에서 사용되도록 설계되어 있다.
                 NSManagedObjectContext는 생성 시 ConcurrencyType을 설정할 수 있으며, viewContext는 NSMainQueueConcurrencyType으로 설정된다.
                 내부적으로 자세히는 모르겠지만, viewContext는 사용자 인터페이스와 뷰 업데이트등과 동기화하고 상호작용이 용이하도록 설계되었다고 한다.
                 이 컨텍스트를 메인 스레드 외부에서 사용하려고 하면, 스레드 충돌이 발생할 위험이 있다.
                 CoreData의 컨텍스트는 스레드에 안전하지 않으므로, 각 컨텍스트는 생성된 스레드에서만 사용해야 한다.
                 
                 UI와의 상호작용: 
                 viewContext는 사용자 인터페이스와 직접 연동되어 데이터를 표시하고 사용자의 입력을 처리하는 데 사용됨.
                 이 컨텍스트에서 데이터를 변경하고 저장하는 작업은 UI의 응답성에 영향을 줄 수 있음.
                 
                 newBackgroundContext() 대신 아래와 같이 자식 컨텍스트를 만드는 방법도 있다.
                 
                 let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                 childContext.parent = container?.viewContext
                 context.configureAsUpdateContext()
                 */

                guard let context = container?.newBackgroundContext() else { return }

                /**
                 
                 NSPersistentContainer는 CoreDataStack의생성과 관리를 좀더 간단하게 해줄 수 있는 클래스로 CoreDataStack을 초기화 해준다.
                 NSPersistentContainer는 NSManagedObjectContext, NSManagedObjectModel, NSPersistentStoreCoordinator로 구성되어 있다.
                 
                 NSManagedObjectModel은 앱의 데이터 모델을 나타내. 이는 관계형DB의 논리적 스키마와 유사하며, 어떤 엔티티(entity)들이 있고,
                 각 엔티티들이 어떤 속성(attributes)과 관계(relationships)를 가지고 있는지 정의한다.
                 
                 NSPersistentStoreCoordinator는 물리적인 저장 공간(예: SQLite 데이터베이스, XML, 이진 파일 등)과 모델을 연결한다.
                 내부적으로 데이터베이스에 대한 CRUD(Create, Read, Update, Delete) 연산들이 이 코디네이터를 통해 수행된다.
                 
                 NSManagedObjectContext는 실제 coredata 작업을 수행하기 위해 사용된다.
                 NSManagedObjectContext는 fetch, save, 새로운 entity생성 등의 coredata를 제어하기위한 인터페이스를 제공한다.
                 각 context마다 메인 메모리에 독자적인 공간을 할당받고, context를 통한 작업들은 이 공간에 저장된다.
                 save()를 통해 해당 context에서 이루어진 작업들을 NSPersistentStoreCoordinator를 통해 실제 디스크에 반영할 수 있다.
                 reset()을 통해 저장된 작업들을 전부 삭제하고 context를 초기상태로 되돌릴수 있다.
                 
                 save()하기 전에 reset()하면 그동안 context로 했던 변경사항들이 실제 물리적 저장소에 반영되지 않으므로 주의.

                 물리적 저장소에 저장되어 있던 entity를 서로 다른 두 context가 수정했을 때, 병합 시 충돌이 발생할 수 있으므로 주의.
                 
                 contextA에서 물리적 저장소에 어떤 entity를 수정했지만 contextB의 자신의 메모리에서 해당 entity를 가지고 어떤 작업을 수행하는 경우,
                 contextB는 contextA가 수정하기 이전 데이터를 가지고 작업하게 되므로 주의.
                 
                 마치 java의 JPA와 비슷하게 동작한다.
                 
                 DBRepository CRUD unit test중에 update()를 호출하는 DBRepository의 store()를 sink했지만, receiveValue 클로저에서 value.email이 빈 문자열이 되버리는 문제 발생.
                 
                 update()는 새로운 contextB를 생성한 후, 해당 contextB를 통해 새로운 entity를 생성한다.
                 해당 entity는 contextB의 메모리에 저장되어 있는 엔티티이고 update()가 종료되는 시점에 지역변수 contextB도 해제되므로 contextB에 저장된 entity도 해제된다.
                 save()로 저장은 했지만, store()가 반환하는 퍼블리셔가 발행하는 값은 물리 저장소에서 가져온 entity가 아닌 contextB의 메인 메모리에 종속된 entity이다.
                 
                 따라서 update()가 종료되면서 지역변수인 contextB의 reference count가 0이 되어 ARC(Automatic Reference Counting)에 의해 해제되고 entity는 댕글링 포인터가 된다.
                 
                 (value.email이 빈문자열이 되긴 하지만 출력이 되는것을 보면 인스턴스가 해제되지는 않았고? 댕글링 포인터는 아닌듯하다.
                 coredata 내부적으로 context가 없어진 entity는 nil이나 빈문자열이 되게끔 하는듯?)
                 
                 store().sink 의 receiveValue 클로저에서 값을 받는 시점이전에 이미 promise()가 실행되었고 contextB는 해제된 상태이기 때문에 value.email가 비어있었던것.
                 
                 따라서 store().sink 의 receiveValue 클로저에서 값을 확인하기 전까지 contextB를 해제시키지 않기 위해 CoreDataStack의 맴버 변수로 클로저 하나를 만들고,
                 해당 클로저에 contextB를 강한 참조 캡처 시킨다.(reference count를 1증가시켜서 해제되는것을 막는다.)
                 
                 update()를 실행할 때마다 self.c = nil로 이전에 캡처했던 context를 해제시키고 새로운 context를 캡처시킨다.
                 이 코드를 추가한 이후로 계속 정상적으로 값을 받아볼수 있었다.
                 
                 ARC(Automatic Reference Counting)
                 자바에 가비지 컬렉터가 있다면 swift는 ARC가 있다.
                 referenc type의 객체를 하나 생성했을 때, 주소값은 스택에, 주소가 가리키는 실제 인스턴스틑 힙에 할당된다.
                 이때 해당 객체의 refence count는 1 증가하는데 이는 해당 인스턴스가 참조되고있는 횟수를 의미한다.
                 refence count가 0이되어 더이상 참조되고 있지 않은 인스턴스는 ARC에 의해 메모리에서 해제된다.
                 
                 가비지 컬렉터는 GC, ARC는 RC에 해당되고 각각의 특징은 아래와 같다.
                 
                 GC
                 Run Time 어플 실행 동안 주기적으로 참조를 추적하여 사용하지 않는 instance를 해제함
                 인스턴스가 해제될 확률이 높음 (RC에 비해)
                 개발자가 참조 해제 시점을 파악할 수 없음
                 RunTime 중에 계속 추적하는 추가 리소스가 필요하여 성능저하 발생될 수 있음
                 ===================================================================
                 RC
                 Compile Time 컴파일 시점에 언제 참조되고 해제되는지 결정되어 런타임 때 그대로 실행됨
                 개발자가 참조 해제 시점을 파악할 수 있음
                 RunTime 시점에 추가 리소스가 발생하지 않음
                 순환 참조가 발생 시 영구적으로 메모리가 해제되지 않을 수 있음
                 */
                self.resetChildContext = nil
                self.resetChildContext = { [context] () -> Void in context.reset() }

                context.configureAsUpdateContext()
                /** 
                 performAndWait는 블록 내 코드(임계 영역이된다.)가 완료될때 까지 bgQueue 스레드를 block시킨다
                 마치 공유자원이 하나인 binary semaphore와 비슷하다.
                 coredata는 thread safe하지 않기 때문에 서로 다른 스레드 같은 context로 동시에 update()를 호출할 경우 데이터 무결성 문제가 발생할 수있다.
                 
                 물론 현재 코드에선 같은 스레드에서 update마다 새로운 context로 작업하고 있지만, 
                 performAndWait를 사용하면 coredata 수정 작업 전체가 동기적으로(먼저온 순서대로) 실행됨이 보장되기 때문에 데이터 일관성 측면에서 이점이된다.
                 또한 수정 작업중 발생하는 에러도 동기적으로 처리가능해진다.
                 */
                context.performAndWait {
                    do {
                        let result: Result = try operation(context)
                        if context.hasChanges {
                            try context.save()
                        }
                        promise(.success(result))
                    } catch {
                        context.reset()
                        if let e = error as? DataConsistencyError { print(e.errorDescription) }
                        promise(.failure(error))
                    }
                }
            }
        }
        /**
         어떤 퍼블리셔에서 값을 생성하면 그 값은 생성된 스레드와 같은 스레드에서 받게된다.
         
         let subject = PassthroughSubject<Int, Never>()
         let token = subject.sink(receiveValue: { value in
            print(Thread.isMainThread)
         })
         subject.send(1)
         DispatchQueue.global().async {
            subject.send(2)
         }
         // true
         // false
         따라서 bgQueue에서 promise()로 값을 발행하였으므로 다운스트림을 실행하는 스레드 역시 bgQueue가 된다.(사실 bgQueue인지는 모르겠지만, mainThread는 아니다.)
         receive(on:)는 receive(on:) 이후에 실행되는 다운 스트림들이 실행되는 스레드를 인자로 준 스레드에서 실행되도록 보장해준다.
         
         let publisher = ["Zedd"].publisher
         publisher
             .map { _ in print(Thread.isMainThread) } // true
             .receive(on: DispatchQueue.global())
             .map { print(Thread.isMainThread) } // false
             .sink { print(Thread.isMainThread) } // false
         */

        return onStoreIsReady
            .flatMap { update }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    private var onStoreIsReady: AnyPublisher<Void, Error> {
        /**
         만약 update가 실행되었는데 isStoreLoaded가 false라서 onStoreIsReady로부터 값이 내려오지 않는다면?
         
         일단 future는 생성되었으므로 isStoreLoaded가 false여도, sink를 안했어도,  저장이나, 삭제등(coredata 작업)은 제대로 처리 되지만
         fetch() 나 update()가 반환하는 값인 AnyPublisher가 어딘가에서 ,sink(...)되었다면 receiveValue: {} 같은 콜백에서 값을 받아볼 수 없다.
         
         하지만 true로 바뀌는 시점에 콜백이 호출되어 값을 받아볼 수 있다.
         
         이것이 왜 가능하냐면, isStoreLoaded가 false일지라도 fetch() 나 update()에서 퍼블리셔는 반환되고, sink되고 store된다.
         즉, publisher와 subcriber간의 스트림(연결)은 이미 생성되었고 구독을 끊을 때까지 유지된다는 이야기.
         단 받은 값이 없기때문에(내려보낼 값이 없어서) 아무 동작도 하지 않는것.
         
         이후 isStoreLoaded가 true가되는 시점에 보낼 값(true)가 생겨서 다운스트림으로 내려가면서 flatMap에서 future인 update로 바뀌면서 sink까지 도달해서 receiveValue를 호출시키게된다.
         isStoreLoaded가 false일때 만들어 두었던 future인 update가 왜 아직도 존재하냐고 하면 flatMap의 클로저로 전달되어서 캡처되었기 때문 아닐까.
         
         fetch() 나 update()이 반환하는 publisher가 sink가 안되어 있다면? 어차피 update()는 future에서 실행은 되니 sink로 값 받든 못받든 상관없음.
         
         만약 fetch()를 sink해놓고 어떤 엔티티를 추가한후 10초 뒤에 isStoreLoaded를 true로 바꾸면 추가된 엔티티까지 가져올까 아니면 추가안된거를 가져올까?
         추가 안된거 가져옴. 이유는 스트림을 만들 때 flatMap클로저에서 update를 캡처하기 때문 아닐까.
         
         .filter { $0 } : 표현식이 $0이므로 false이면 아무것도 다운스트림으로 내려가지 않을 것이고 true라면 Bool:true가 다운스트림으로 내려감
         .map { _ in } : 내려온 Bool타입의 true는 무시하고 아무것도 반환안함 (자동으로 Void가 됨)
         
         */
        isStoreLoaded
            .filter { $0 }
            .map { _ in }
            .eraseToAnyPublisher()
    }
}

extension NSManagedObjectContext {

    func configureAsReadOnlyContext() {
        automaticallyMergesChangesFromParent = true
        mergePolicy = NSRollbackMergePolicy
        undoManager = nil
        shouldDeleteInaccessibleFaults = true
    }

    func configureAsUpdateContext() {
        mergePolicy = NSOverwriteMergePolicy
        undoManager = nil
    }
}

