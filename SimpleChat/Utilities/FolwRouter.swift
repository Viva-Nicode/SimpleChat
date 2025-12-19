import Foundation
import PhotosUI
import SwiftUI

final class FlowRouter: ObservableObject {

    @Published public var navPath = NavigationPath()

    public enum DestinationView: Hashable, Codable {
        case chatlogView(String)
    }

    @ViewBuilder
    public func nextView(_ des: DestinationView) -> some View {
        switch des {
        case let .chatlogView(roomid):
            ChatLogView(currentChatroomid: roomid)
        }
    }

    public func navigate(to destination: DestinationView) { navPath.append(destination) }

    public func navigateBack() { navPath.removeLast() }

    public func navigateToRoot() { navPath = NavigationPath() }

    static var stub: Self { .init() }
}
