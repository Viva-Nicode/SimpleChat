import SwiftUI
import CoreData
import FirebaseMessaging
import Alamofire
import BackgroundTasks
import Combine
import UserNotifications
import SDWebImageSwiftUI
import WebKit
import Firebase

let serverUrl = Bundle.main.object(forInfoDictionaryKey: "ServerUrl") as! String
let screenWidth = UIScreen.main.bounds.width
let screenHeight = UIScreen.main.bounds.height

var bottomSafeareaHeight: CGFloat {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return 40 }
    return windowScene.keyWindow?.safeAreaInsets.bottom ?? 40
}

class AppSettingModel: ObservableObject {
    @Published var appTheme = UserDefaultsKeys.appTheme.value() ?? true
    @Published var selectedTab = Tab.home
}

class CurrentViewObject: ObservableObject {
    @Published var currentChatroomid: String?
}

@main
struct SimpleChatApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.injected) private var injected: DIContainer
    @State private var isLaunchedData = true
    @State private var observer: NSObjectProtocol?
    @State private var suspendedAlert: Bool = false
    @State private var launchedScreenOffset: CGFloat = .zero
    @StateObject var userApplicationViewModel = ApplicationViewModel()
    @StateObject var appSettingModel = AppSettingModel()
    @StateObject var network: Network = Network()
    @StateObject var flowRouter: FlowRouter = FlowRouter()

    init() {

        let tabviewAppearance = UITabBarAppearance()
        tabviewAppearance.configureWithTransparentBackground()
        tabviewAppearance.backgroundColor = .clear

        tabviewAppearance.stackedLayoutAppearance.selected.iconColor = .orange
        tabviewAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.orange]
        tabviewAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(named: "Gradation background start dark2")
        tabviewAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(named: "Gradation background start dark2")!]

        UITabBar.appearance().standardAppearance = tabviewAppearance
        if #available(iOS 15.0, *) { UITabBar.appearance().scrollEdgeAppearance = tabviewAppearance }

        /* ======================================== NavigationStack Setting ======================================== */

        let navBarAppearance = UINavigationBarAppearance()

        navBarAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        navBarAppearance.shadowColor = .clear

        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance

        SDImageCache.shared.config.maxDiskAge = -1
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                IndexView(isLaunchedData: $isLaunchedData, launchedScreenOffset: $launchedScreenOffset, isSuspended: $suspendedAlert)
                    .environmentObject(userApplicationViewModel)
                    .environmentObject(appSettingModel)
                    .environmentObject(network)
                    .environmentObject(flowRouter)
                    .environmentObject(delegate.currentViewObject)
                    .onChange(of: network.isConnected) { /*loaduserdata()*/ }
                    .onReceive(NotificationCenter.default.publisher(for: .arrivedMessage)) { notification in
                    injected.userEventHandler
                        .handleArrivedMessageNotification(notification: notification, uc: $userApplicationViewModel.userChatrooms,
                        uf: $userApplicationViewModel.userfriends, utt: $userApplicationViewModel.userChatroomTitles) }
                    .onReceive(NotificationCenter.default.publisher(for: .arrivedFriendRequest)) { notification in
                    injected.userEventHandler
                        .handleArrivedFriendRequestNotification(notification: notification, un: $userApplicationViewModel.userNotifications) }
                    .onReceive(NotificationCenter.default.publisher(for: .acceptedFriendRequest)) { notification in
                    injected.userEventHandler
                        .handleArrivedAcceptedFriendRequest(notification: notification, uf: $userApplicationViewModel.userfriends) }
                    .onReceive(NotificationCenter.default.publisher(for: .messageReading)) { notification in
                    injected.userEventHandler
                        .handleReadMessageNotification(notification: notification, uc: $userApplicationViewModel.userChatrooms) }
                    .onReceive(NotificationCenter.default.publisher(for: .arrivedSystemMessage)) { notification in
                    injected.userEventHandler
                        .handleArrivedSystemMessageNotification(notification: notification, uc: $userApplicationViewModel.userChatrooms) }
                    .onReceive(NotificationCenter.default.publisher(for: .removeFriend)) { notification in
                    injected.userEventHandler
                        .handleArrivedFriendRemoveRequest(notification: notification, uf: $userApplicationViewModel.userfriends) }
                    .onReceive(NotificationCenter.default.publisher(for: .openedByRemoteNotificationFromBackground)) { notification in
                    if let roomid = notification.userInfo!["roomid"] as? String ?? notification.userInfo!["chatroomid"] as? String {
                        let isTapedOnForeground = notification.userInfo!["isTapedOnForeground"] as! Bool

                        if isTapedOnForeground {
                            flowRouter.navigateToRoot()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                appSettingModel.selectedTab = .mainmessage
                                flowRouter.navigate(to: .chatlogView(roomid))
                            }
                        } else {
                            observer = NotificationCenter.default.addObserver(forName: .completeDataInit, object: nil, queue: .main) { _ in
                                appSettingModel.selectedTab = .mainmessage
                                flowRouter.navigate(to: .chatlogView(roomid))
                                if let observer = observer { NotificationCenter.default.removeObserver(observer) }
                            }
                        }
                    }
                }
            }
                .overlay { isLaunchedData ? launchScreenView.offset(y: launchedScreenOffset) : nil }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                if let email: String = UserDefaultsKeys.userEmail.value() {
                    switch newPhase {
                    case .background:
                        injected.interactorContainer.userInteractor.changeAppState("background")
                        flowRouter.navigateToRoot()
                    case .inactive:
                        injected.interactorContainer.userInteractor.changeAppState("inactive")
                        flowRouter.navigateToRoot()
                    case .active:
                        injected.interactorContainer.userInteractor.loadUserData(
                            $userApplicationViewModel.userChatrooms,
                            $userApplicationViewModel.userfriends,
                            $userApplicationViewModel.userNotifications,
                            $userApplicationViewModel.userChatroomBundles,
                            $userApplicationViewModel.userChatroomTitles,
                            $userApplicationViewModel.whisperMessageSender,
                            $userApplicationViewModel.cancellableSet,
                            $isLaunchedData, $launchedScreenOffset, $suspendedAlert, email)
                    default: break
                    }
                } else {
                    withAnimation(.spring(duration: 0.3)) {
                        launchedScreenOffset = -UIScreen.main.bounds.height
                    } completion: { isLaunchedData = false }
                }
            }
        }
    }
}

extension SimpleChatApp {
    var launchScreenView: some View {
        ZStack(alignment: .center) {
            Color("Launch Screen Background")
            Image("logo")
                .resizable()
                .frame(width: 125, height: 125)
                .cornerRadius(38)
                .background(Color.clear)
            Text("Simple Chat")
                .offset(y: 80)
                .font(.title)
        }
            .ignoresSafeArea(.all)
            .alert(isPresented: $suspendedAlert) {
            return Alert(title: Text("Restricted Account"),
                message: Text("Service use will be restricted due to inappropriate activity identified in the account."))
        }
    }
}
