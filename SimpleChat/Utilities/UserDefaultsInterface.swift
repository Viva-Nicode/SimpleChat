import Foundation

enum UserDefaultsKeys: String {
    case userEmail = "loginedEmail"
    case userNickname = "nickname"
    case appTheme = "appTheme"
    case fcmToken = "fcmToken"

    public static let nilValue: String? = nil

    public func value<T: Codable>() -> T? {
        if let data = UserDefaults.standard.data(forKey: self.rawValue),
            let userDefaultValue = try? JSONDecoder().decode(UserDefaultsValue<T>.self, from: data) {
            return userDefaultValue.value()
        } else {
            return nil
        }
    }

    public func setValue<T: Codable>(_ newValue: T?) {
        if newValue == nil {
            let userDefaultValue = UserDefaultsValue<T>.noValue
            if let data = try? JSONEncoder().encode(userDefaultValue) {
                UserDefaults.standard.set(data, forKey: self.rawValue)
            }
        } else {
            let userDefaultValue = UserDefaultsValue.presentValue(newValue!)
            if let data = try? JSONEncoder().encode(userDefaultValue) {
                UserDefaults.standard.set(data, forKey: self.rawValue)
            }
        }
    }

    private enum UserDefaultsValue<T: Codable>: Codable {
        case noValue
        case presentValue(T)

        func value() -> T? {
            switch self {
            case .noValue:
                return nil
            case let .presentValue(value):
                return value
            }
        }
    }
}

