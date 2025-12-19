//
//  AccountWebRepository.swift
//  SimpleChat
//
//  Created by Nicode . on 5/5/24.
//

import Foundation
import Alamofire
import Combine

protocol AccountWebRepository: WebRepository {
    func signUp(email: String, password: String, fcmtoken: String) -> AnyPublisher<APIResponse, AFError>
    func signin(email: String, password: String, fcmtoken: String) -> AnyPublisher<APIResponse, AFError>
    func loadUserData(email: String) -> AnyPublisher<ApplicationViewModel, AFError>
    func getUserProfileList(email: String) -> AnyPublisher<[UserProfileModel], AFError>
    func deleteAccount(email: String, password: String) -> AnyPublisher<APIResponse, AFError>
    func removeProfile(email: String, targetImage: String) -> AnyPublisher<APIResponse, AFError>
    func signout(email: String) -> AnyPublisher<APIResponse, AFError>
    func checkIsExistuser(email: String) -> AnyPublisher<APIResponse, AFError>
    func reportUser(email: String, audience: String, reason: Int, detail: String) -> AnyPublisher<APIResponse, AFError>
    func accessSecret(authKey: String) -> AnyPublisher<APIResponse, AFError>
    @discardableResult func changeAppState(email: String, state: String) -> AnyPublisher<APIResponse, AFError>
    @discardableResult func changeNickname(email: String, nickname: String) -> AnyPublisher<APIResponse, AFError>
}

struct RealAccountWebRepository: AccountWebRepository {

    let session: Session

    init(session: Session) { self.session = session }

    func signUp(email: String, password: String, fcmtoken: String) -> AnyPublisher<APIResponse, AFError> {
        let reqeustBody = UserAuthenticationReqeustBody(email: email, password: password, fcmtoken: fcmtoken)
        return call(.signup(reqeustBody), APIResponse.self)
    }

    func signin(email: String, password: String, fcmtoken: String) -> AnyPublisher<APIResponse, AFError> {
        let reqeustBody = UserAuthenticationReqeustBody(email: email, password: password, fcmtoken: fcmtoken)
        return call(.signin(reqeustBody), APIResponse.self)
    }

    func loadUserData(email: String) -> AnyPublisher<ApplicationViewModel, AFError> {
        return call(.loadUserData(email), UserDataFetchResponseModel.self).map { data in
            ApplicationViewModel(data) { setting in
                UserDefaultsKeys.userNickname.setValue(setting.nickname)
            }
        }.eraseToAnyPublisher()
    }

    func signout(email: String) -> AnyPublisher<APIResponse, Alamofire.AFError> {
        return call(.signout(email), APIResponse.self)
    }

    func getUserProfileList(email: String) -> AnyPublisher<[UserProfileModel], AFError> {
        return call(.getProfilesList(email), [UserProfileResponseModel].self)
            .realFlattenMap { index, value in
            UserProfileModel(value)
        }.eraseToAnyPublisher()
    }

    func removeProfile(email: String, targetImage: String) -> AnyPublisher<APIResponse, AFError> {
        return call(.removeProfile(email, targetImage), APIResponse.self)
    }

    func checkIsExistuser(email: String) -> AnyPublisher<APIResponse, AFError> {
        return call(.checkExistUser(email), APIResponse.self)
    }

    func reportUser(email: String, audience: String, reason: Int, detail: String) -> AnyPublisher<APIResponse, AFError> {
        return call(.reportUser(email, audience, reason, detail), APIResponse.self)
    }

    @discardableResult
    func changeAppState(email: String, state: String) -> AnyPublisher<APIResponse, AFError> {
        return call(.changeAppState(email, state), APIResponse.self)
    }

    @discardableResult func changeNickname(email: String, nickname: String) -> AnyPublisher<APIResponse, AFError> {
        return call(.changeNickname(email, nickname), APIResponse.self)
    }

    func deleteAccount(email: String, password: String) -> AnyPublisher<APIResponse, AFError> {
        return call(.deleteAccount(email, password), APIResponse.self)
    }

    func accessSecret(authKey: String) -> AnyPublisher<APIResponse, AFError> {
        call(.secretAuth(authKey), APIResponse.self)
    }
}
