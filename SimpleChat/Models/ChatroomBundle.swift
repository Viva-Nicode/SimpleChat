import Foundation

enum CardType: String {
    case chatroom = "chatroom"
    case bundle = "bundle"
}

protocol Cardable {
    var cardType: CardType { get }
}

enum BundlePosition: String {
    case none = "none"
    case mostBottom = "mostBottom"
    case mostTop = "mostTop"
}

struct ChatroomBundle: Hashable, Cardable {
    var cardType: CardType = .bundle

    var bundleID: String
    var bundleName: String
    var bundleProfileURL: String?
    var bundlePosition: BundlePosition
    var bundleChatroomList: [String]


    init(bundleID: String, bundleName: String, bundleURL: String?, bundlePosition: BundlePosition, chatroomList: [String]) {
        self.bundleID = bundleID
        self.bundleName = bundleName
        self.bundleProfileURL = bundleURL
        self.bundlePosition = bundlePosition
        self.bundleChatroomList = chatroomList
    }

    init(bundleID: String, bundleName: String, bundlePosition: BundlePosition, chatroomList: [String]) {
        self.bundleID = bundleID
        self.bundleName = bundleName
        self.bundlePosition = bundlePosition
        self.bundleChatroomList = chatroomList
    }
}
