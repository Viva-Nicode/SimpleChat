//
//  UserInteractor.swift
//  SimpleChat
//
//  Created by Nicode . on 3/24/24.
//

import Combine
import Foundation
import SwiftUI
import Alamofire
import CoreData
import PhotosUI
import SDWebImageSwiftUI

enum DataConsistencyError: Error {
    case ServerDataShortageThanLocalData(String) // 서버에서 온 데이터가 코어데이터 보다 더 적음
    case NotFoundLogFromServerData(String, String)
    case CanNotConvertingToUserChatLog(String)
    case DuplicateChatLogId(String)
    case cannotFoundChatroomFromCoreData(String)

    var errorDescription: String {
        switch self {
        case let .ServerDataShortageThanLocalData(roomid):
            return "The data length of the core data is longer than the length of the server data. roomid : \(roomid)"
        case let .NotFoundLogFromServerData(roomid, logid):
            return "chatlog of the core data could not be found in the server data. \(roomid), \(logid)"
        case let .CanNotConvertingToUserChatLog(logid):
            return "Unable to cast as UserChatLog. id : \(logid)"
        case let .DuplicateChatLogId(id):
            return "tried to insert a log into the core data, but a log with the same id already exists. id : \(id)"
        case let .cannotFoundChatroomFromCoreData(roomid):
            return "tried to insert the log into the core data, but the chat room to be inserted does not exist. roomid : \(roomid)"
        }
    }
}

typealias PasswordLengthLimit = Range<Int>
extension PasswordLengthLimit { static let passwordLegnthRange = 8...20 }

protocol UserInteractor {

    func signup(_ svm: UserInteractionFeedback, _ cancelBag: Binding<Set<AnyCancellable>>, _ profile: PhotosPickerItem?) throws

    func signin(_ lvm: UserInteractionFeedback, _ shouldShowsoftwareLicenseAgreementPopupView: Binding<Bool>,
        _ signinSuccessedEmail: Binding<String>, _ cancelBag: Binding<Set<AnyCancellable>>)

    func signout(email: String, tab: Binding<Tab>) -> AnyCancellable

    func loadUserData(_ ucr: Binding<[UserChatroom]>, _ uf: Binding<[UserFriend]>, _ un: Binding<[UserNotification]>,
        _ ucb: Binding<[ChatroomBundle]>, _ utt: Binding<[String:String]>, _ wm: Binding<[String:String]>,
        _ cb: Binding<Set<AnyCancellable>>, _ isLaunchedData: Binding<Bool>, _ launchedScreenOffset: Binding<CGFloat>,
        _ isSuspended: Binding<Bool>, _ email: String)

    func changeAppState(_ state: String)

    func reportUser(email: String, audience: String, reason: Int, detail: String) -> AnyPublisher<APIResponse, AFError>

    func checkIsExistUser(email: String, isFriend: Binding<Bool>, friendlist: Binding<[UserFriend]>) -> AnyCancellable

    func removeProfile(email: String, targetPhoto: UserProfileModel, completion: @escaping () -> ()) -> AnyCancellable

    func changeNickname(email: String, nickname: String, viewModelNickname: Binding<String>,
        shouldShowModifyNicknameView: Binding <Bool>) -> AnyCancellable

    func storeUserProfilePhoto(newProfilePhoto: UIImage) -> AnyCancellable

    func storeUserBackgroundPhoto(newProfilePhoto: UIImage) -> AnyCancellable

    func getUserProfileList(email: String, userProfileList: Binding<[UserProfileModel]?>) -> AnyCancellable

    func deleteAccount(email: String, password: String) -> AnyPublisher<APIResponse, AFError>

    func accessSecret(authKey: String) -> AnyPublisher<APIResponse, AFError>
}


struct RealUserInteractor: UserInteractor {

    let webRepository: AccountWebRepository
    let dbRepository: DBOperationsContainer

    func signup(_ svm: UserInteractionFeedback, _ cancelBag: Binding<Set<AnyCancellable>>, _ profile: PhotosPickerItem?) throws {
        if !isValidEmail(svm.getEmail) {
            svm.setErrorMessage(LocalizationString.accountFailReason_emailFormat)
        } else if !isValidPassword(svm.getPassword) {
            svm.setErrorMessage(LocalizationString.accountFailReason_passwordLength)
        } else {
            let fcmtoken: String = UserDefaultsKeys.fcmToken.value()!
            cancelBag.wrappedValue.removeAll()

            webRepository.signUp(email: svm.getEmail, password: svm.getPassword, fcmtoken: fcmtoken).sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("signup finished")
                    case .failure(let error):
                        print((error).errorDescription ?? "")
                    }
                },
                receiveValue: { value in
                    switch value.code {
                    case .success:
                        if let unwrapedProfileData = svm.getProfileData {
                            if let emailData = svm.getEmail.stringToData() {
                                let profileInfo = UserProfileStoreRequestBody(email: emailData, profile: unwrapedProfileData)
                                webRepository.call(APIs.storeProfile(profileInfo), APIResponse.self)
                                    .sink(
                                    receiveCompletion: { completion in
                                        switch completion {
                                        case .finished:
                                            print("storeProfile finished")
                                        case .failure(let error):
                                            print((error).errorDescription ?? "")
                                        }
                                    },
                                    receiveValue: { [svm] result in
                                        if result.code == .success {
                                            svm.setErrorMessage("Sign up success. Please log in with the account.")
                                        } else {
                                            svm.setErrorMessage("Failed to save profile picture.")
                                        }
                                        svm.clearTextField()
                                    }
                                ).store(in: &cancelBag.wrappedValue)
                            }
                        } else {
                            svm.setErrorMessage("Sign up success. Please log in with the account.")
                            svm.clearTextField()
                        }
                    default:
                        svm.setErrorMessage(value.code.description)
                    }
                }).store(in: &cancelBag.wrappedValue)
        }
    }


    func signin(_ lvm: UserInteractionFeedback, _ shouldShowsoftwareLicenseAgreementPopupView: Binding<Bool>,
        _ signinSuccessedEmail: Binding<String>, _ cancelBag: Binding<Set<AnyCancellable>>) {
        if !isValidEmail(lvm.getEmail) {
            lvm.setErrorMessage(LocalizationString.accountFailReason_emailFormat)
        } else if !isValidPassword(lvm.getPassword) {
            lvm.setErrorMessage(LocalizationString.accountFailReason_passwordLength)
        } else {
            let fcmtoken: String = UserDefaultsKeys.fcmToken.value()!
            cancelBag.wrappedValue.removeAll()

            webRepository.signin(email: lvm.getEmail, password: lvm.getPassword, fcmtoken: fcmtoken)
                .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("login finished")
                    case .failure(let error):
                        print(error.errorDescription ?? "")
                    }
                },
                receiveValue: { value in
                    switch value.code {
                    case .success:
                        signinSuccessedEmail.wrappedValue = lvm.getEmail
                        let cacheKey = "\(serverUrl)/rest/get-thumbnail/\(lvm.getEmail)"
                        SDWebImageDownloader.shared.downloadImage(with: URL(string: cacheKey),
                            options: .highPriority, progress: nil) { (image, data, error, finished) in
                            if let profilePhoto = image {
                                SDImageCache.shared.removeImage(forKey: cacheKey, withCompletion: {
                                    SDImageCache.shared.store(profilePhoto, forKey: cacheKey, completion: {
                                        shouldShowsoftwareLicenseAgreementPopupView.wrappedValue = true
                                        NotificationCenter.default.post(name: .updatedMyProfilePhoto, object: nil, userInfo: nil)
                                    })
                                })
                            } else {
                                print("can not download profile photo")
                                shouldShowsoftwareLicenseAgreementPopupView.wrappedValue = true
                            }
                        }

                        let backgroundCacheKey = "\(serverUrl)/rest/get-background/\(lvm.getEmail)"
                        SDWebImageDownloader.shared.downloadImage(with: URL(string: backgroundCacheKey),
                            options: .highPriority, progress: nil) { (image, data, error, finished) in
                            if let profilePhoto = image {
                                SDImageCache.shared.removeImage(forKey: backgroundCacheKey, withCompletion: {
                                    SDImageCache.shared.store(profilePhoto, forKey: backgroundCacheKey, completion: {
                                        NotificationCenter.default.post(name: .updateMyBackgroundPhoto, object: nil, userInfo: nil)
                                    })
                                })
                            }
                        }
                    default:
                        lvm.setErrorMessage(value.code.description)
                    }
                }).store(in: &cancelBag.wrappedValue)
        }
    }

    func signout(email: String, tab: Binding<Tab>) -> AnyCancellable {
        return webRepository.signout(email: email).sink(receiveCompletion: { _ in },
            receiveValue: { value in
                if value.code == .success {
                    UserDefaultsKeys.userEmail.setValue(UserDefaultsKeys.nilValue)
                    UserDefaultsKeys.userNickname.setValue(UserDefaultsKeys.nilValue)
                    tab.wrappedValue = .home
                }
            })
    }

    func loadUserData(_ ucr: Binding<[UserChatroom]>, _ uf: Binding<[UserFriend]>, _ un: Binding<[UserNotification]>,
        _ ucb: Binding<[ChatroomBundle]>, _ utt: Binding<[String:String]>, _ wm: Binding<[String:String]>,
        _ cb: Binding<Set<AnyCancellable>>, _ isLaunchedData: Binding<Bool>, _ launchedScreenOffset: Binding<CGFloat>,
        _ isSuspended: Binding<Bool>, _ email: String) {

        cb.wrappedValue.removeAll()

        webRepository.loadUserData(email: email)
            .sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("active loadUserData finished")
                case .failure(let error):
                    print("loadUserData failure error desc : ")
                    print(error.errorDescription ?? "")
                    Just<Void>
                        .withErrorType(Error.self)
                        .flatMap { dbRepository.friendPersistentOperations.readAllFriend() }
                        .map { uf.wrappedValue = $0 }
                        .flatMap { dbRepository.chatroomPersistentOperations.readAllChatroom() }
                        .map { ucr.wrappedValue = $0 }
                        .flatMap { dbRepository.chatroomBundlePersistentOperations.readChatroomBundles() }
                        .map { ucb.wrappedValue = $0 }
                        .flatMap { dbRepository.chatroomPersistentOperations.readChatroomTitles() }
                        .map {
                        for (roomid, titleFromCoredata) in $0 {
                            if let firstChatroom = ucr.wrappedValue.first(where: { $0.chatroomid == roomid }) {
                                let defaultChatroomTitle = firstChatroom.audiencelist.filter { $0 != email }
                                    .map { audienceEmail in
                                    uf.wrappedValue.first(where: { $0.email == audienceEmail })?.nickname ?? audienceEmail }.joined(separator: ",")
                                utt.wrappedValue[roomid] = titleFromCoredata ?? defaultChatroomTitle
                            }
                        }
                    }.sink(receiveCompletion: { _ in }, receiveValue: { _ in
                            withAnimation(.spring(duration: 0.3)) {
                                launchedScreenOffset.wrappedValue = -UIScreen.main.bounds.height
                            } completion: { isLaunchedData.wrappedValue = false }
                        }
                    ).store(in: &cb.wrappedValue)
                }
            },
            receiveValue: { data in
                if data.isSuspended {
                    isLaunchedData.wrappedValue = true
                    isSuspended.wrappedValue = true
                } else {
                    ucr.wrappedValue = data.userChatrooms
                    uf.wrappedValue = data.userfriends
                    un.wrappedValue = data.userNotifications
                    wm.wrappedValue = data.whisperMessageSender

                    dbRepository.chatroomPersistentOperations.readChatroomTitles()
                        .sink(receiveCompletion: { _ in },
                        receiveValue: { table in
                            for (roomid, titleFromCoredata) in table {
                                if let firstChatroom = ucr.wrappedValue.first(where: { $0.chatroomid == roomid }) {
                                    let defaultChatroomTitle = firstChatroom.audiencelist
                                        .filter { $0 != email }
                                        .map { audienceEmail in
                                        uf.wrappedValue.first(where: { $0.email == audienceEmail })?.nickname ?? audienceEmail }
                                        .sorted()
                                        .joined(separator: ",")
                                    utt.wrappedValue[roomid] = titleFromCoredata ?? defaultChatroomTitle
                                }
                            }

                            let roomidSet: Set<String> = Set(table.map { $0.key })
                            for cr in ucr.wrappedValue {
                                if !roomidSet.contains(cr.chatroomid) {
                                    let defaultChatroomTitle = cr.audiencelist.filter { $0 != email }
                                        .map { audienceEmail in
                                        uf.wrappedValue.first(where: { $0.email == audienceEmail })?.nickname ?? audienceEmail }
                                        .sorted()
                                        .joined(separator: ",")
                                    utt.wrappedValue[cr.chatroomid] = defaultChatroomTitle
                                }
                            }
                        }).store(in: &cb.wrappedValue)

                    dbRepository.chatroomBundlePersistentOperations.readChatroomBundles()
                        .sink(receiveCompletion: { _ in }, receiveValue: {
                            ucb.wrappedValue = $0
                        }).store(in: &cb.wrappedValue)

                    saveUserDataToCoreData(uf: uf.wrappedValue, ucr: ucr.wrappedValue, cb: cb)
                    NotificationCenter.default.post(name: .completeDataInit, object: nil, userInfo: nil)

                    withAnimation(.spring(duration: 0.3)) {
                        launchedScreenOffset.wrappedValue = -screenHeight
                    } completion: { isLaunchedData.wrappedValue = false }
                }
            }
        ).store(in: &cb.wrappedValue)
    }

    func changeAppState(_ state: String) {
        if let email: String = UserDefaultsKeys.userEmail.value() {
            webRepository.changeAppState(email: email, state: state)
        }
    }

    func checkIsExistUser(email: String, isFriend: Binding<Bool>, friendlist: Binding<[UserFriend]>) -> AnyCancellable {
        webRepository.checkIsExistuser(email: email).sink(receiveCompletion: { _ in },
            receiveValue: { res in
                if res.code == .success {
                    isFriend.wrappedValue = false
                    if let idx = friendlist.wrappedValue.firstIndex(where: { $0.email == email }) {
                        friendlist.wrappedValue.remove(at: idx)
                    }
                    dbRepository.friendPersistentOperations.remove(friend: UserFriend(email: email))
                }
            }
        )
    }

    func removeProfile(email: String, targetPhoto: UserProfileModel, completion: @escaping () -> ()) -> AnyCancellable {

        webRepository.removeProfile(email: email, targetImage: targetPhoto.imageName)
            .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                print("remove Profile finished")
            case .failure(let error):
                print("remove Profile fail : \(error.errorDescription ?? "")")
            }
        }, receiveValue: { value in
                if targetPhoto.isCurrentUsing {
                    switch targetPhoto.profileType {

                    case .profile:
                        SDImageCache.shared.removeImage(forKey: "\(serverUrl)/rest/get-thumbnail/\(email)") {
                            NotificationCenter.default.post(name: .updatedMyProfilePhoto, object: nil, userInfo: nil)
                        }

                    case .background:
                        SDImageCache.shared.removeImage(forKey: "\(serverUrl)/rest/get-background/\(email)") {
                            NotificationCenter.default.post(name: .updateMyBackgroundPhoto, object: nil, userInfo: nil)
                        }

                    case .undefined:
                        break
                    }
                }
                completion()
            }
        )
    }

    func changeNickname(email: String, nickname: String, viewModelNickname: Binding<String>,
        shouldShowModifyNicknameView: Binding<Bool>) -> AnyCancellable {
        webRepository.changeNickname(email: email, nickname: nickname)
            .sink(receiveCompletion: { comp in }, receiveValue: {
                value in
                viewModelNickname.wrappedValue = nickname
                shouldShowModifyNicknameView.wrappedValue = false
                UserDefaultsKeys.userNickname.setValue(nickname)
            })
    }

    func reportUser(email: String, audience: String, reason: Int, detail: String) -> AnyPublisher<APIResponse, AFError> {
        webRepository.reportUser(email: email, audience: audience, reason: reason, detail: detail)
    }

    func storeUserProfilePhoto(newProfilePhoto: UIImage) -> AnyCancellable {
        if let me: String = UserDefaultsKeys.userEmail.value(), let data = newProfilePhoto.jpegData(compressionQuality: 0.8) {
            let profileInfo = UserProfileStoreRequestBody(email: me.stringToData(), profile: data)
            return webRepository.call(APIs.storeProfile(profileInfo), APIResponse.self).sink(receiveCompletion: { _ in },
                receiveValue: { _ in
                    let cacheKey = "\(serverUrl)/rest/get-thumbnail/\(me)"
                    SDImageCache.shared.removeImage(forKey: cacheKey, withCompletion: {
                        SDImageCache.shared.store(newProfilePhoto, forKey: cacheKey, completion: {
                            print("profile store complete")
                            NotificationCenter.default.post(name: .updatedMyProfilePhoto, object: nil, userInfo: nil)
                        })
                    })
                })
        } else {
            return Just<Void>.withErrorType(AFError.self).sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        }
    }

    func storeUserBackgroundPhoto(newProfilePhoto: UIImage) -> AnyCancellable {
        if let me: String = UserDefaultsKeys.userEmail.value(), let data = newProfilePhoto.jpegData(compressionQuality: 0.8) {
            let profileInfo = UserProfileStoreRequestBody(email: me.stringToData(), profile: data)
            return webRepository.call(.storeBackgroundProfile(profileInfo), APIResponse.self).sink(receiveCompletion: { _ in },
                receiveValue: { _ in
                    let cacheKey = "\(serverUrl)/rest/get-background/\(me)"
                    SDImageCache.shared.removeImage(forKey: cacheKey, withCompletion: {
                        SDImageCache.shared.store(newProfilePhoto, forKey: cacheKey, completion: {
                            NotificationCenter.default.post(name: .updateMyBackgroundPhoto, object: nil, userInfo: nil)
                        })
                    })
                })
        } else {
            return Just<Void>.withErrorType(AFError.self).sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        }
    }

    func getUserProfileList(email: String, userProfileList: Binding<[UserProfileModel]?>) -> AnyCancellable {
        webRepository.getUserProfileList(email: email)
            .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                print("getProfileList finished")
            case .failure(let error):
                print("getProfileList fail : \(error.errorDescription ?? "")")
            }
        }, receiveValue: { value in
                userProfileList.wrappedValue = value.sorted(by: { $0.timestamp > $1.timestamp })
            }
        )
    }

    func deleteAccount(email: String, password: String) -> AnyPublisher<APIResponse, AFError> {
        return webRepository.deleteAccount(email: email, password: password)
    }

    func accessSecret(authKey: String) -> AnyPublisher<APIResponse, AFError> {
        webRepository.accessSecret(authKey: authKey)
    }

    private func saveUserDataToCoreData(uf: [UserFriend], ucr: [UserChatroom], cb: Binding<Set<AnyCancellable>>) {

        dbRepository.friendPersistentOperations.readAllFriend()
            .map { friends in
            let coredataFriendsSet = Set(friends.map { $0.email })
            let serverFriendsSet = Set(uf.map { $0.email })

            dbRepository.friendPersistentOperations.createFriends(
                friends: serverFriendsSet.subtracting(coredataFriendsSet).map { friend in uf.first(where: { $0.email == friend })! })

            dbRepository.friendPersistentOperations.synchronizeFriends(
                friends: serverFriendsSet.intersection(coredataFriendsSet).map { friend in uf.first(where: { $0.email == friend })! })
        }.sink(receiveCompletion: { comp in }, receiveValue: { value in }).store(in: &cb.wrappedValue)

        dbRepository.chatroomPersistentOperations.isDifferent(ucr: ucr)
            .filter {
            print("ucr dif : \($0)")
            return $0
        }
            .flatMap { [dbRepository] _ in dbRepository.chatroomPersistentOperations.readAllChatroom() }
            .map { [ucr] chatrooms -> (Set<String>, Set<String>, [UserChatroom]) in

            let coredataChatroomsSet = Set(chatrooms.map { $0.chatroomid })
            let serverChatroomsSet = Set(ucr.map { $0.chatroomid })

            return (coredataChatroomsSet, serverChatroomsSet, chatrooms)
        }
            .map { [ucr, dbRepository] (coredataSet, serverSet, chatrooms) -> (Set<String>, Set<String>, [UserChatroom]) in
            dbRepository.chatroomPersistentOperations.synchronizeChatrooms(
                des: serverSet.intersection(coredataSet).map { id in ucr.first(where: { room in room.chatroomid == id })! })
            return (coredataSet, serverSet, chatrooms) }
            .map { [ucr, dbRepository] (coredataSet, serverSet, chatrooms) -> (Set<String>, Set<String>, [UserChatroom]) in
            dbRepository.chatroomPersistentOperations.createChatrooms(chatrooms:
                    serverSet.subtracting(coredataSet).map { id in ucr.first(where: { room in room.chatroomid == id })! })
            return (coredataSet, serverSet, chatrooms) }
            .map { [dbRepository] (coredataSet, serverSet, chatrooms) -> Void in
            dbRepository.chatroomPersistentOperations.removeChatrooms(chatrooms:
                    coredataSet.subtracting(serverSet).map { id in chatrooms.first(where: { room in room.chatroomid == id })! })
        }.sink(receiveCompletion: { _ in }, receiveValue: { _ in }).store(in: &cb.wrappedValue)
    }

    private func isValidEmail(_ target: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: target)
    }

    private func isValidPassword(_ target: String) -> Bool {
        return PasswordLengthLimit.passwordLegnthRange ~= target.count
    }

    private func printChatroomsForTestCase(chatrooms: [UserChatroom]) {
        chatrooms.forEach { chatroom in
            print("chatroomid : \(chatroom.chatroomid)")
            print("chatroom audienceList : \(chatroom.audiencelist.joined(separator: " "))")
            print("chatroomType : \(chatroom.roomtype.rawValue)")
            chatroom.log.forEach { log in
                if let systemlog = log as? SystemLog {
                    print("SystemLog(id:\"\(systemlog.id)\",logType: \"\(systemlog.logType.rawValue)\", timestamp: \"\(systemlog.timestamp.dateToString())\", detail: \"\(systemlog.detail)\"),")
                } else if let chatlog = log as? UserChatLog {
                    print("UserChatLog(id: \"\(chatlog.id)\", logType: \"\(chatlog.logType.rawValue)\", writer: \"\(chatlog.writer)\", timestamp: \"\(chatlog.timestamp.dateToString())\",  detail: \"\(chatlog.detail)\", isSetReadNotification: \(chatlog.isSetReadNotification), readusers: \"\(chatlog.readusers.joined(separator: " "))\"),")
                }
            }
            print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
        }
    }
}
