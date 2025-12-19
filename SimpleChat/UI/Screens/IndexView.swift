import SwiftUI
import UIKit
import PhotosUI
import SDWebImageSwiftUI
import Foundation
import Alamofire
import CoreData
import Combine
import AVFoundation

struct RefreshableWebImageProfileModifier: ViewModifier {
    let email: String
    let isme: Bool
    @State var viewidForRefresh = UUID()

    init(_ email: String, _ isme: Bool) {
        self.email = email
        self.isme = isme
    }

    func body(content: Content) -> some View {
        content
            .id(viewidForRefresh)
            .onReceive(NotificationCenter.default.publisher(for: isme ? .updatedMyProfilePhoto : .updatedFriendProfilePhoto)) { notification in
            viewidForRefresh = UUID()
            if let updatedAudience = notification.userInfo?["email"] as? String {
                if email == updatedAudience {
                    viewidForRefresh = UUID()
                }
            } else {
                viewidForRefresh = UUID()
            }
        }
    }
}

enum Tab {
    case home, mainmessage, teddy, gear
}

class IndexViewModel: ObservableObject {
    @Published var shouldShowAddNewFriendView = false
    @Published var shouldShowNotificationView = false
    @Published var shouldShowFriendDetailView = false
    @Published var shouldShowMyProfileView = false
    @Published var shouldShowSearchTextField = false
    @Published var newFriendTextInput = ""
    @Published var friendSearchKeyword = ""
    @Published var isLogin = false
    @Published var FriendDetailViewTarget = ""

    @Published var shouldShowFriendListSheet = true
    @Published var friendListSheetOffset: CGFloat = .zero
    @Published var lastFriendListSheetOffset: CGFloat = .zero
    @Published var shouldShowProfileFullScreenView = false

    @Published var photosPickerItem: PhotosPickerItem?
    @Published var photosUIImage: UIImage?

    @Published var backgroundPhotosPickerItem: PhotosPickerItem?
    @Published var backgroundPhotosUIImage: UIImage?
    @Published var shouldShowProfileModifyView = false
}

struct IndexView: View {
    @Environment(\.injected) private var injected: DIContainer
    @EnvironmentObject var applicationViewModel: ApplicationViewModel
    @EnvironmentObject var network: Network
    @EnvironmentObject var flowRouter: FlowRouter
    @EnvironmentObject var appSettingModel: AppSettingModel
    @StateObject fileprivate var indexViewModel: IndexViewModel = IndexViewModel()
    @ObservedObject private var sc: SecretCommandModel = SecretCommandModel()
    @Namespace private var profileBoxAnimationNamespace
    @State private var subscriptions: Set<AnyCancellable> = []
    @State private(set) var userSearchResult: Loadable<OtherUserSearchResponseModel> = .notRequested
    @Binding var isLaunchedData: Bool
    @Binding var launchedScreenOffset: CGFloat
    @Binding var isSuspended: Bool
    @FocusState private var newFriendSearchViewKeyboardIsFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    @State var showMyProfileView = false
    @State private var isRefreshMyBackground = true

    @State private var pairChatroomId: String = ""
    @State private var voiceChatroomId: String = ""
    @State private var voiceChatAudienceEmail: String = ""

    @State private var shouldShowVoiceChatroomView: Bool = false
    @State private var showPermissionRequireAlert = false

    var body: some View {
        NavigationStack(path: $flowRouter.navPath) {
            TabView(selection: $appSettingModel.selectedTab) {
                mainView
                    .toolbar(showMyProfileView ? .hidden : .visible, for: .tabBar)
                    .tabItem {
                    Label("Home", systemImage: "house")
                }.tag(Tab.home)
                MainMessageView()
                    .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.text.bubble.right.rtl")
                }.tag(Tab.mainmessage).badge(applicationViewModel.unreadCount)
                AppSettingView()
                    .tabItem {
                    Label("Setting", systemImage: "gearshape")
                }.tag(Tab.gear)
            }.onOpenURL { url in
                guard url.scheme == "simplechat", url.host == "chatroom" else { return }

                let urlString = url.absoluteString
                guard urlString.contains("roomid") else { return }

                let components = URLComponents(string: url.absoluteString)
                let urlQueryItems = components?.queryItems ?? []

                var dictionaryData = [String: String]()
                urlQueryItems.forEach { dictionaryData[$0.name] = $0.value }

                guard let roomid = dictionaryData["roomid"] else { return }

                appSettingModel.selectedTab = .mainmessage
                flowRouter.navigate(to: .chatlogView(roomid))
            }.safeAreaInset(edge: .top, alignment: .center, spacing: 0) {
                if !network.isConnected {
                    Text("Check your network connection")
                        .font(.system(size: 11.3))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .background(.gray)
                        .padding(0)
                }
            }
        }
    }

    @ViewBuilder
    var mainView: some View {
        ZStack {
            if let newBackground = indexViewModel.backgroundPhotosUIImage {
                GeometryReader { newBackgroundGeo in
                    VStack(alignment: .center) {
                        Image(uiImage: newBackground)
                            .resizable()
                            .scaledToFill()
                            .frame(width: newBackgroundGeo.size.width, height: newBackgroundGeo.size.height)
                            .clipped()
                    }
                }.ignoresSafeArea(.all)
            } else {
                GeometryReader { backgroundGeo in
                    if let email: String = UserDefaultsKeys.userEmail.value() {
                        if isRefreshMyBackground {
                            WebImage(url: URL(string: "\(serverUrl)/rest/get-background/\(email)"), options: [.refreshCached])
                                .resizable()
                                .scaledToFill()
                                .frame(width: backgroundGeo.size.width, height: backgroundGeo.size.height)
                                .opacity(indexViewModel.friendListSheetOffset / screenHeight)
                                .onReceive(NotificationCenter.default.publisher(for: .updateMyBackgroundPhoto)) { notification in
                                withAnimation(.easeInOut(duration: 0.4)) { isRefreshMyBackground = false }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    withAnimation(.easeInOut(duration: 0.4)) { isRefreshMyBackground = true }
                                }
                            }
                        }
                    }

                    LinearGradient(
                        gradient: Gradient(colors: [Color(appSettingModel.appTheme ? "Gradation background start" : "Gradation background start dark"),
                            Color(appSettingModel.appTheme ? "Gradation background end" : "Gradation background end dark")]),
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                        .opacity(1.0 - indexViewModel.friendListSheetOffset / screenHeight)
                        .frame(width: backgroundGeo.size.width, height: backgroundGeo.size.height)

                    LinearGradient(
                        gradient: Gradient(colors: [Color(appSettingModel.appTheme ? "Gradation orange start light" : "Gradation background start dark2"),
                            Color(appSettingModel.appTheme ? "Gradation orange end light" : "Gradation background end dark2")]),
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                        .cornerRadius(.infinity)
                        .opacity(1.0 - indexViewModel.friendListSheetOffset / screenHeight)
                        .frame(width: backgroundGeo.size.width, height: backgroundGeo.size.width)
                        .offset(x: -backgroundGeo.size.width * 0.4)

                    LinearGradient(
                        gradient: Gradient(colors: [Color(appSettingModel.appTheme ? "Gradation start light" : "Gradation background start dark3"),
                            Color(appSettingModel.appTheme ? "Gradation end light" : "Gradation background end dark3")]),
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                        .cornerRadius(.infinity)
                        .opacity(1.0 - indexViewModel.friendListSheetOffset / screenHeight)
                        .frame(width: backgroundGeo.size.width + 250, height: backgroundGeo.size.width + 250)
                        .offset(x: backgroundGeo.size.width * 0.3, y: backgroundGeo.size.height * 0.5)
                }.ignoresSafeArea(.all)
            }

            if indexViewModel.shouldShowProfileModifyView {
                PhotosPicker(selection: $indexViewModel.backgroundPhotosPickerItem, matching: .images) {
                    Color.clear.ignoresSafeArea(.all)
                }.onChange(of: indexViewModel.backgroundPhotosPickerItem) { _, newBackgroundImage in
                    Task(priority: .high) {
                        if let data = try? await newBackgroundImage?.loadTransferable(type: Data.self) {
                            if let uiImage = UIImage(data: data) {
                                withAnimation { indexViewModel.backgroundPhotosUIImage = uiImage.fixedOrientation().clippingImage() }
                            }
                        }
                    }
                }
            }

            VStack(alignment: .center, spacing: 10) {
                HStack(alignment: .center) {
                    Text(showMyProfileView ? "" : "Friends")
                        .font(.title)
                        .frame(alignment: .leading)
                        .appThemeForegroundColor(appSettingModel.appTheme)

                    if indexViewModel.shouldShowProfileModifyView {
                        Button {
                            withAnimation {
                                indexViewModel.shouldShowProfileModifyView = false
                                indexViewModel.photosPickerItem = nil
                                indexViewModel.photosUIImage = nil

                                indexViewModel.backgroundPhotosPickerItem = nil
                                indexViewModel.backgroundPhotosUIImage = nil
                            }
                        } label: {
                            HStack(alignment: .center) {
                                Text("Cancel")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color("pastel gray"))
                            }.padding(7)
                        }
                    }
                    Spacer()
                    HStack(alignment: .bottom, spacing: 20) {
                        if showMyProfileView {
                            if !indexViewModel.shouldShowProfileModifyView {
                                Button(action: {
                                    withAnimation(.spring(duration: 0.3)) {
                                        indexViewModel.shouldShowProfileModifyView = true
                                    }
                                }) {
                                    Image(systemName: "person.and.background.striped.horizontal")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 25)
                                        .contentShape(Rectangle())
                                        .appThemeForegroundColor(appSettingModel.appTheme)
                                }
                            }
                        } else {
                            Button(action: {
                                indexViewModel.friendSearchKeyword = ""
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.spring(duration: 0.3)) {
                                        indexViewModel.shouldShowSearchTextField.toggle()
                                    }
                                }
                            }) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 25)
                                    .contentShape(Rectangle())
                                    .appThemeForegroundColor(appSettingModel.appTheme)
                                    .offset(y: 1.5)
                            }

                            Button(action: {
                                indexViewModel.shouldShowNotificationView.toggle()
                            }) {
                                Image(systemName: "bell.badge")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 25)
                                    .contentShape(Rectangle())
                                    .appThemeForegroundColor(appSettingModel.appTheme)
                            }

                            Button(action: {
                                indexViewModel.shouldShowAddNewFriendView.toggle()
                            }) {
                                Image(systemName: "person.badge.plus")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 25)
                                    .contentShape(Rectangle())
                                    .appThemeForegroundColor(appSettingModel.appTheme)
                                    .offset(y: 1.5)
                            }
                        }
                    }
                    if indexViewModel.shouldShowProfileModifyView {
                        Button {
                            if let uiimage = indexViewModel.photosUIImage {
                                injected.interactorContainer.userInteractor.storeUserProfilePhoto(
                                    newProfilePhoto: uiimage)
                                    .store(in: &subscriptions)
                                indexViewModel.photosPickerItem = nil
                                indexViewModel.photosUIImage = nil
                            }
                            if let backgroundUIimage = indexViewModel.backgroundPhotosUIImage {
                                injected.interactorContainer.userInteractor.storeUserBackgroundPhoto(
                                    newProfilePhoto: backgroundUIimage)
                                    .store(in: &subscriptions)
                                indexViewModel.backgroundPhotosPickerItem = nil
                                indexViewModel.backgroundPhotosUIImage = nil
                            }
                            indexViewModel.shouldShowProfileModifyView = false
                        } label: {
                            HStack(alignment: .center) {
                                Text("Save")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color("pastel gray"))
                            }.padding(7)
                        }
                    }
                }.frame(height: 30).padding()

                // MARK: - profile Box
                HStack(alignment: .center, spacing: 8) {
                    if let email: String = UserDefaultsKeys.userEmail.value() {
                        if showMyProfileView {
                            // MARK: - 내렸을 때 나의 프로필 상자
                            VStack(alignment: .center, spacing: 4) {
                                ZStack {
                                    WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(email)"), options: [.refreshCached])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 70, height: 70)
                                        .clipped()
                                        .cornerRadius(70)
                                        .opacity(indexViewModel.photosUIImage == nil ? 1.0 : .zero)
                                        .modifier(RefreshableWebImageProfileModifier(email, true))
                                        .matchedGeometryEffect(id: "profilePhoto", in: profileBoxAnimationNamespace)

                                    if let newProfile = indexViewModel.photosUIImage {
                                        Image(uiImage: newProfile)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 70, height: 70)
                                            .clipped()
                                            .cornerRadius(70)
                                    }

                                    if indexViewModel.shouldShowProfileModifyView {
                                        PhotosPicker(selection: $indexViewModel.photosPickerItem, matching: .images) {
                                            Color.clear.frame(width: 70, height: 70)
                                        }.onChange(of: indexViewModel.photosPickerItem) { _, newImage in
                                            Task(priority: .high) {
                                                if let data = try? await newImage?.loadTransferable(type: Data.self) {
                                                    if let uiImage = UIImage(data: data) {
                                                        withAnimation { indexViewModel.photosUIImage = uiImage.fixedOrientation().clippingImage() }
                                                    }
                                                }
                                            }
                                        }.overlay(alignment: .topTrailing) {
                                            Image(systemName: "pencil.circle.fill").font(.system(size: 30))
                                                .foregroundStyle(.gray)
                                        }
                                    }
                                }
                                Text(UserDefaultsKeys.userNickname.value() ?? email)
                                    .font(.system(size: 22, weight: .bold))
                                    .frame(alignment: .leading)
                                    .appThemeForegroundColor(appSettingModel.appTheme)
                                    .lineLimit(1)
                                    .matchedGeometryEffect(id: "profileNickname", in: profileBoxAnimationNamespace)
                                Text(email)
                                    .font(.system(size: 16))
                                    .appThemeForegroundColor(appSettingModel.appTheme)
                                    .lineLimit(1)
                                    .matchedGeometryEffect(id: "profileEmail", in: profileBoxAnimationNamespace)
                            }
                        } else {
                            // MARK: - 초기 상태 나의 프로필 상자
                            WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(email)"), options: [.refreshCached])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 70, height: 70)
                                .clipped()
                                .cornerRadius(70)
                                .modifier(RefreshableWebImageProfileModifier(email, true))
                                .matchedGeometryEffect(id: "profilePhoto", in: profileBoxAnimationNamespace)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(UserDefaultsKeys.userNickname.value() ?? email)
                                    .font(.system(size: 22, weight: .bold))
                                    .frame(alignment: .leading)
                                    .appThemeForegroundColor(appSettingModel.appTheme)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                    .matchedGeometryEffect(id: "profileNickname", in: profileBoxAnimationNamespace)
                                Text(email)
                                    .font(.system(size: 16))
                                    .appThemeForegroundColor(appSettingModel.appTheme)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                    .matchedGeometryEffect(id: "profileEmail", in: profileBoxAnimationNamespace)
                            }
                        }
                    }
                    // MARK: - profile photos button
                    if !showMyProfileView {
                        Spacer()
                        ZStack {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 50)
                                Image(systemName: "applelogo")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 30, height: 30)
                                    .border(.black.opacity(0.8), width: 0.7)
                                    .offset(y: -5)
                            }
                                .rotationEffect(.degrees(-15))
                                .padding(.horizontal)
                                .padding(.top)
                                .padding(.bottom, 20)
                                .shadow(radius: 1)
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 50)
                                Image(systemName: "applelogo")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 30, height: 30)
                                    .border(.black.opacity(0.8), width: 0.7)
                                    .offset(y: -5)
                            }
                                .padding(.horizontal)
                                .padding(.top)
                                .padding(.bottom, 20)
                                .shadow(radius: 1)
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 50)
                                if let email: String = UserDefaultsKeys.userEmail.value() {
                                    WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(email)"), options: [.fromCacheOnly])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 30, height: 30)
                                        .clipped()
                                        .border(.gray.opacity(0.5), width: 0.7)
                                        .offset(y: -5)
                                }
                            }
                                .rotationEffect(.degrees(15))
                                .padding(.horizontal)
                                .padding(.top)
                                .padding(.bottom, 20)
                                .shadow(radius: 1)
                        }
                            .onTapGesture { indexViewModel.shouldShowProfileFullScreenView = true }
                            .padding(0)
                            .opacity(1.0 - (indexViewModel.friendListSheetOffset / screenHeight))
                    }
                }
                    .padding(10)
                    .cornerRadius(15)
                    .background {
                    if appSettingModel.appTheme {
                        BackgroundBlurView().cornerRadius(15)
                    } else {
                        BackgroundDarkBlurView().cornerRadius(15)
                    }
                }
                    .contentShape(Rectangle())
                    .offset(y: indexViewModel.friendListSheetOffset * 0.55)
                    .gesture(showMyProfileView ? DragGesture().onChanged { value in
                        if value.translation.height < 0 {
                            indexViewModel.friendListSheetOffset = max(indexViewModel.lastFriendListSheetOffset + value.translation.height, .zero)
                        }
                    }.onEnded { value in
                        if value.translation.height < screenHeight * -0.15 {
                            withAnimation(.spring(duration: 0.3)) {
                                indexViewModel.friendListSheetOffset = .zero
                                indexViewModel.lastFriendListSheetOffset = .zero
                                showMyProfileView = false
                            }
                        } else {
                            withAnimation(.spring(duration: 0.3)) { indexViewModel.friendListSheetOffset = screenHeight }
                        }
                    }: DragGesture().onChanged {
                        indexViewModel.friendListSheetOffset = max($0.translation.height, 0)
                    }.onEnded {
                        if $0.translation.height > UIScreen.main.bounds.height * 0.15 {
                            withAnimation(.spring(duration: 0.3)) {
                                indexViewModel.friendListSheetOffset = screenHeight
                                indexViewModel.shouldShowSearchTextField = false
                                showMyProfileView = true
                            }
                            indexViewModel.lastFriendListSheetOffset = indexViewModel.friendListSheetOffset
                        } else {
                            withAnimation(.spring(duration: 0.3)) { indexViewModel.friendListSheetOffset = .zero }
                        }
                    })

                // MARK: - Friend ScrollView
                VStack(alignment: .center) {
                    if indexViewModel.shouldShowSearchTextField {
                        HStack(alignment: .center) {
                            ZStack {
                                TextField(text: $indexViewModel.friendSearchKeyword) { }
                                    .textCase(.lowercase)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .foregroundStyle(.black)
                                    .padding(.horizontal)
                                HStack(alignment: .center) {
                                    Spacer()
                                    Image(systemName: "xmark.circle")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(8)
                                        .contentShape(Circle())
                                        .onTapGesture { indexViewModel.friendSearchKeyword = "" }
                                }.padding(.trailing, 6)
                            }
                        }
                            .frame(height: 35)
                            .background {
                            Rectangle()
                                .cornerRadius(8)
                                .shadow(radius: 1)
                                .foregroundStyle(.white)
                        }.padding()
                    }

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .center, spacing: 7) {
                            ForEach(keywordSearchResult(applicationViewModel.userfriends), id: \.self) { friend in
                                HStack(alignment: .center, spacing: 22) {
                                    WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(friend.email)"), options: [.refreshCached])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 45, height: 45)
                                        .clipped()
                                        .cornerRadius(14)
                                        .modifier(RefreshableWebImageProfileModifier(friend.email, false))
                                    VStack(alignment: .leading, spacing: 5) {
                                        (friend.nickname ?? friend.email)
                                            .highlightingText(indexViewModel.friendSearchKeyword, appSettingModel.appTheme)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.6)
                                        HStack(alignment: .center) {
                                            friend.email
                                                .highlightingEmailText(indexViewModel.friendSearchKeyword, appSettingModel.appTheme)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.6)
                                                .foregroundStyle(appSettingModel.appTheme ? Color("pastel blue foreground") : Color("pastel yellow foreground"))
                                        }
                                            .cornerRadius(10)
                                            .if(appSettingModel.appTheme) { view in
                                            view.background {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .foregroundStyle(Color("pastel blue"))
                                            }
                                        }.if(!appSettingModel.appTheme) { view in
                                            view.overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color("pastel yellow foreground"), lineWidth: 1)
                                            )
                                        }
                                    }
                                    Spacer()
                                    HStack(alignment: .center, spacing: 12) {
                                        Image(systemName: "phone.circle")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 30)
                                            .foregroundStyle(.blue.opacity(0.6))
                                            .contentShape(Circle())
                                            .onTapGesture {
                                            if Permissions.checkAudioAuthorizationStatus() != .allowed || Permissions.checkCameraAuthorizationStatus() != .allowed {
                                                showPermissionRequireAlert = true
                                            } else {
                                                if let email: String = UserDefaultsKeys.userEmail.value() {
                                                    voiceChatAudienceEmail = friend.email
                                                    injected.interactorContainer.chatroomInteractor.startPairChat(
                                                        email, friend.email, applicationViewModel.getNickname(friend.email),
                                                        $voiceChatroomId, $applicationViewModel.userChatroomTitles,
                                                        $applicationViewModel.userChatrooms, $subscriptions)
                                                }
                                            }
                                        }
                                        Image(systemName: "bubble.right.circle")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 30)
                                            .foregroundStyle(.green.opacity(0.6))
                                            .contentShape(Circle())
                                            .onTapGesture {
                                            if let email: String = UserDefaultsKeys.userEmail.value() {
                                                injected.interactorContainer.chatroomInteractor.startPairChat(
                                                    email, friend.email, applicationViewModel.getNickname(friend.email),
                                                    $pairChatroomId, $applicationViewModel.userChatroomTitles,
                                                    $applicationViewModel.userChatrooms, $subscriptions)
                                            }
                                        }
                                    }
                                }
                                    .padding(.vertical, 5)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                    indexViewModel.FriendDetailViewTarget = friend.email
                                    indexViewModel.shouldShowFriendDetailView = true
                                }
                            }
                        }
                            .padding(.horizontal)
                            .onChange(of: pairChatroomId) { _, nv in
                            if !nv.isEmpty {
                                appSettingModel.selectedTab = .mainmessage
                                flowRouter.navigate(to: .chatlogView(nv))
                            }
                        }.onChange(of: voiceChatroomId) { _, nv in
                            if !nv.isEmpty {
                                shouldShowVoiceChatroomView = true
                            }
                        }.onDisappear { pairChatroomId = "" }
                    }
                        .contentMargins(.vertical, 14, for: .scrollContent)
                        .clipped()
                }
                    .background {
                    if showMyProfileView {
                        TransparentBackgroundView()
                    } else {
                        if appSettingModel.appTheme {
                            BackgroundBlurView().cornerRadius(15)
                        } else {
                            BackgroundDarkBlurView().cornerRadius(15)
                        }
                    }
                }
                    .cornerRadius(15)
                    .offset(y: indexViewModel.friendListSheetOffset)
                    .opacity(1.0 - (indexViewModel.friendListSheetOffset / screenHeight))
            }.padding()
        }
            .onAppear {
            let email: String? = UserDefaultsKeys.userEmail.value()
            indexViewModel.isLogin = email == nil

            UNUserNotificationCenter.current().getDeliveredNotifications { remoteNotifications in
                for remoteNotification in remoteNotifications {
                    if remoteNotification.request.content.userInfo["notitype"] as! String == "knellVoicechat" {
                        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [remoteNotification.request.identifier])
                    }
                }
            }
        }.alert(isPresented: $showPermissionRequireAlert) {
            Alert(title: Text("Permission required"), message: Text("Please allow microphone and camera permissions in in-app settings"))
        }.onChange(of: indexViewModel.isLogin) { oldValue, newValue in
            if !newValue {
                if let email: String = UserDefaultsKeys.userEmail.value() {
                    injected.interactorContainer.userInteractor.loadUserData(
                        $applicationViewModel.userChatrooms,
                        $applicationViewModel.userfriends,
                        $applicationViewModel.userNotifications,
                        $applicationViewModel.userChatroomBundles,
                        $applicationViewModel.userChatroomTitles,
                        $applicationViewModel.whisperMessageSender,
                        $subscriptions, $isLaunchedData, $launchedScreenOffset, $isSuspended, email)
                }
            }
        }.fullScreenCover(isPresented: $shouldShowVoiceChatroomView) {
            VoiceChatroomView(shouldShowVoiceChatroomView: $shouldShowVoiceChatroomView, roomid: voiceChatroomId, audience: voiceChatAudienceEmail)
                .onDisappear { voiceChatroomId = "" }
        }.fullScreenCover(isPresented: $indexViewModel.shouldShowFriendDetailView) {
            ZStack {
                FriendDetailView(friendEmail: indexViewModel.FriendDetailViewTarget,
                    isPresented: $indexViewModel.shouldShowFriendDetailView, closeSideMenu: { })
            }.background(TransparentBackgroundView())
        }.fullScreenCover(isPresented: $indexViewModel.isLogin) {
            AccountView(isLogined: $indexViewModel.isLogin)
        }.fullScreenCover(isPresented: $indexViewModel.shouldShowProfileFullScreenView) {
            if let me: String = UserDefaultsKeys.userEmail.value() {
                ZStack {
                    FullScreenProfilePhotoView(shouldShowProfileFullScreenView: $indexViewModel.shouldShowProfileFullScreenView, targetEmail: me)
                }.background(TransparentBackgroundView())
            }
        }.fullScreenCover(isPresented: $indexViewModel.shouldShowAddNewFriendView) {
            newFriendAddView.onTapGesture { newFriendSearchViewKeyboardIsFocused = false }
        }.fullScreenCover(isPresented: $indexViewModel.shouldShowNotificationView) { notificationCenterView }
    }

    @ViewBuilder
    func userSearchResultView<Content: View>(_ searchResult: OtherUserSearchResponseModel, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .center) {
            HStack(alignment: .center) {
                ZStack {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 70)
                        .clipped()
                        .cornerRadius(19)
                        .shadow(radius: 5)
                    WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(searchResult.result)"), options: [.refreshCached])
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 70)
                        .clipped()
                        .cornerRadius(19)
                        .shadow(radius: 5)
                }
            }.padding(.top, 20)
            HStack(alignment: .center) {
                Text(verbatim: searchResult.result)
                    .appThemeForegroundColor(appSettingModel.appTheme)
            }
            HStack(alignment: .center, spacing: 16) {
                Spacer()
                Button(action: {
                    if let email: String = UserDefaultsKeys.userEmail.value() {
                        injected.interactorContainer.notificationInteractor.sendFriendRequestToSearchedUser(
                            searchResult: $userSearchResult, me: email, audience: searchResult.result)
                    }
                }) {
                    content()
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .foregroundStyle(.black)
                        .background {
                        Rectangle()
                            .foregroundColor(searchResult.requestState == .`init` ? Color.yellow : Color.gray.opacity(0.6))
                            .cornerRadius(6)
                    }
                }.disabled(searchResult.requestState == .`init` ? false : true)
                Spacer()
            }.padding(.bottom, 20)
        }.background {
            Rectangle()
                .foregroundColor(appSettingModel.appTheme ? .black.opacity(0.15) : .white.opacity(0.15))
                .cornerRadius(10)
                .allowsTightening(false)
        }
            .padding(.horizontal, 10)
    }

    @ViewBuilder
    private var userSearchResultContent: some View {
        switch userSearchResult {
        case .notRequested:
            Text("")
        case .isLoading(_, _):
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(2)
                        .tint(appSettingModel.appTheme ? .gray : .white)
                    Spacer()
                }
                Spacer()
            }
        case .loaded(let t):
            switch(t.requestState) {
            case .wait:
                userSearchResultView(t) { Text("waiting...") }
            case .accept:
                userSearchResultView(t) { Text("Accept your request") }
            case .`init`:
                userSearchResultView(t) { Text("Reuqest") }
            case .notFound:
                VStack {
                    HStack {
                        Spacer()
                        Text("No Results found.")
                            .font(.title2)
                            .appThemeForegroundColor(appSettingModel.appTheme)
                        Spacer()
                    }
                    Spacer()
                }
            }
        case .failed(let error):
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(error.localizedDescription).font(.title2)
                    Spacer()
                }
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var newFriendAddView: some View {
        GeometryReader { geo in
            VStack {
                HStack(alignment: .center) {
                    Button(action: {
                        indexViewModel.shouldShowAddNewFriendView = false
                    }) {
                        Image(systemName: "xmark")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 21)
                            .contentShape(Rectangle())
                            .appThemeForegroundColor(appSettingModel.appTheme)
                            .padding()
                    }
                    Spacer()
                    Text("Search by Email")
                        .font(.title)
                        .appThemeForegroundColor(appSettingModel.appTheme)
                    Spacer()
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 21)
                        .padding()
                        .hidden()
                }.padding()

                VStack(alignment: .leading, spacing: 15) {
                    TextField(text: $indexViewModel.newFriendTextInput) {
                        Text("email")
                            .foregroundStyle(appSettingModel.appTheme ? .black.opacity(0.2) : .white.opacity(0.3))
                    }
                        .textInputAutocapitalization(.never)
                        .multilineTextAlignment(.leading)
                        .autocorrectionDisabled(true)
                        .frame(height: 40)
                        .focused($newFriendSearchViewKeyboardIsFocused)
                        .padding(.leading, 5)
                        .padding(.bottom, 20)
                        .padding(.trailing, 15)
                        .textFieldStyle(LineTextfieldClearStyle())
                        .submitLabel(.search)
                        .onSubmit {
                        if let _ = UserDefaults.standard.string(forKey: "activeSecretMode") {
                            let _ = sc.isSecretCommand(command: indexViewModel.newFriendTextInput)
                        } else {
                            let splited = indexViewModel.newFriendTextInput.components(separatedBy: "?")

                            if splited.count == 2 && splited[0] == "secret-cmd:auth" {
                                injected.interactorContainer.userInteractor.accessSecret(authKey: splited[1])
                                    .sink(receiveCompletion: { _ in }, receiveValue: { res in
                                        if res.code == .success {
                                            UserDefaults.standard.set("active", forKey: "activeSecretMode")
                                        } else {
                                            print("fail")
                                        }
                                    }).store(in: &subscriptions)
                            }
                        }

                        if let email: String = UserDefaultsKeys.userEmail.value() {
                            injected.interactorContainer.notificationInteractor.searchOtherUser(
                                searchResult: $userSearchResult, email: email,
                                keyword: indexViewModel.newFriendTextInput)
                        }
                    }
                    userSearchResultContent
                        .onAppear {
                        self.userSearchResult = .notRequested
                        self.indexViewModel.newFriendTextInput = ""
                    }
                    Spacer()
                }
            }
        }
            .background {
            if appSettingModel.appTheme {
                BackgroundBlurView().ignoresSafeArea(.all)
            } else {
                BackgroundDarkBlurView().ignoresSafeArea(.all)
            }
        }
    }

    @ViewBuilder
    private var notificationCenterView: some View {
        GeometryReader { geo in
            VStack {
                HStack(alignment: .center) {
                    Button(action: {
                        indexViewModel.shouldShowNotificationView = false
                    }) {
                        Image(systemName: "xmark")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 21)
                            .contentShape(Rectangle())
                            .appThemeForegroundColor(appSettingModel.appTheme)
                            .padding()
                    }
                    Spacer()
                    Text("Notifications")
                        .font(.title)
                        .appThemeForegroundColor(appSettingModel.appTheme)
                    Spacer()
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 21)
                        .padding()
                        .hidden()
                }.padding()

                VStack(alignment: .leading, spacing: 12) {
                    if applicationViewModel.userNotifications.isEmpty {
                        VStack(alignment: .center) {
                            Spacer()
                            Image(systemName: "bell.slash.fill")
                                .resizable()
                                .foregroundColor(appSettingModel.appTheme ? .black.opacity(0.2) : .white.opacity(0.3))
                                .frame(width: 60, height: 60)
                            Text("no new notifications")
                                .foregroundColor(appSettingModel.appTheme ? .black.opacity(0.2) : .white.opacity(0.3))
                                .font(.title)
                            Spacer()
                        }.frame(height: geo.size.height * 0.7)
                    } else {
                        ScrollView {
                            ForEach(applicationViewModel.userNotifications, id: \.self) { notification in
                                switch notification.notificationType {
                                case .friendRequest:
                                    VStack {
                                        HStack(alignment: .center, spacing: 5) {
                                            ZStack {
                                                WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(notification.fromEmail)"),
                                                    options: [.refreshCached])
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 54, height: 54)
                                                    .clipped()
                                                    .cornerRadius(19)
                                                    .shadow(radius: 1)
                                                    .padding(.top, 13)
                                            }.padding(.trailing, 10)
                                            VStack(alignment: .leading) {
                                                Text("friend request has arrived from")
                                                    .foregroundStyle(.purple)
                                                Text(notification.fromEmail)
                                                    .appThemeForegroundColor(appSettingModel.appTheme)
                                                Text(notification.showableTimestamp)
                                                    .font(.system(size: 12))
                                                    .appThemeForegroundColor(appSettingModel.appTheme)
                                            }
                                            Spacer()
                                        }
                                        HStack {
                                            Spacer()
                                            Button(action: {
                                                if let email: String = UserDefaultsKeys.userEmail.value() {
                                                    injected.interactorContainer.notificationInteractor.refuseFriendRequest(email,
                                                        $applicationViewModel.userNotifications, $subscriptions, notification)
                                                }
                                            }) {
                                                Text("refuse")
                                                    .padding(.vertical, 5)
                                                    .padding(.horizontal, 10)
                                                    .foregroundColor(.white)
                                                    .background {
                                                    Rectangle()
                                                        .foregroundColor(Color.gray.opacity(0.7))
                                                        .cornerRadius(6)
                                                }
                                            }
                                            Button(action: {
                                                if let email: String = UserDefaultsKeys.userEmail.value() {
                                                    injected.interactorContainer.notificationInteractor.acceptFriendRequest(email, $applicationViewModel.userNotifications, $applicationViewModel.userfriends,
                                                        $subscriptions, notification)
                                                }
                                            }) {
                                                Text("accept")
                                                    .padding(.vertical, 5)
                                                    .padding(.horizontal, 10)
                                                    .foregroundColor(.white)
                                                    .background {
                                                    Rectangle()
                                                        .foregroundColor(Color.blue.opacity(0.7))
                                                        .cornerRadius(6)
                                                }
                                            }
                                        } }
                                        .padding()
                                        .background {
                                        Rectangle()
                                            .foregroundColor(appSettingModel.appTheme ? .black.opacity(0.1) : .white.opacity(0.15))
                                            .cornerRadius(13)
                                    }
                                default:
                                    Text("bug")
                                }
                            }
                        }.padding().frame(height: geo.size.height * 0.7)
                    }
                }
            }
        }.onAppear {
            UNUserNotificationCenter.current().getDeliveredNotifications { remoteNotifications in
                for remoteNotification in remoteNotifications {
                    if remoteNotification.request.content.userInfo["notitype"] as! String == "friendAddNoti" {
                        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [remoteNotification.request.identifier])
                    }
                }
            }
        }
            .background {
            if appSettingModel.appTheme {
                BackgroundBlurView().ignoresSafeArea(.all)
            } else {
                BackgroundDarkBlurView().ignoresSafeArea(.all)
            }
        }
    }

    private func keywordSearchResult(_ friendList: [UserFriend]) -> [UserFriend] {
        if indexViewModel.friendSearchKeyword == "" {
            return friendList
        } else {
            return friendList.filter {
                $0.email.contains(indexViewModel.friendSearchKeyword) || $0.nickname?.contains(indexViewModel.friendSearchKeyword) ?? false
            }
        }
    }

    private var statusBarHeight: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return 0 }
        return windowScene.statusBarManager?.statusBarFrame.height ?? 0
    }

    private var keyboardHeightPublisher: AnyPublisher<CGFloat, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue }
                .map { $0.cgRectValue.height },
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in CGFloat(0) }
        ).eraseToAnyPublisher()
    }
}

struct TransparentBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) { }
}

struct BackgroundBlurView: UIViewRepresentable {

    func makeUIView(context: Context) -> UIView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) { }
}

struct BackgroundDarkBlurView: UIViewRepresentable {

    func makeUIView(context: Context) -> UIView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) { }
}


