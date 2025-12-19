import SwiftUI
import SDWebImageSwiftUI
import Combine
import Alamofire
import PhotosUI

extension Notification.Name {
    static let updatedBundleIcon = Notification.Name("updatedBundleIcon")
}

class MainMessageViewModel: ObservableObject {
    @Published var selectedUserList: [String] = []
    @Published var searchKeywordInput: String = ""
    @Published var shouldShowNewChatroomSheet = false
    @Published var currentUserEmail = ""
    @Published var exitChatroomId = ""
    @Published var exitChatAlert = false

    // MARK: - Chatroom Bundle
    @Published var shouldShowCreateNewBundleView = false
    @Published var newChatroomBundlePhoto: PhotosPickerItem?
    @Published var newChatroomBundlePhotoUIImage: UIImage?
    @Published var newChatroomBundleName = ""
    @Published var newChatroomBundleRoomIds: [String] = []
    @Published var shouldShowBundlesChatrooms = false
    @Published var tappedBundleId: String?
    @Published var shouldShowBundlePositionContextMenu = false
    @Published var shouldShowBundleSettingView = false
    @Published var shouldShowAnimationDelayGlassWindow = false

    @Published var editingBundlePhoto: PhotosPickerItem?
    @Published var editingBundlePhotoUIImage: UIImage?
    @Published var editingBundleName: String = ""
    @Published var editingBundleRoomIds: [String] = []
    @Published var updatedBundleIconId = UUID()
}

struct MainMessageView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.injected) private var injected: DIContainer
    @EnvironmentObject var applicationViewModel: ApplicationViewModel
    @EnvironmentObject var flowRouter: FlowRouter
    @StateObject fileprivate var mainMessageViewModel: MainMessageViewModel = MainMessageViewModel()
    @State private var subscriptions: Set<AnyCancellable> = []
    @EnvironmentObject var appSettingModel: AppSettingModel

    @FocusState private var newChatroomViewKeyboardIsFocused: Bool
    @State private var keyboardHeight: CGFloat = .zero
    @Namespace private var bundleDescAnimationNamespace

    let selectedFriendColor: LinearGradient = LinearGradient(
        gradient: Gradient(colors: [Color("Gradation orange end light"), Color("pastel green")]),
        startPoint: .topLeading, endPoint: .bottomTrailing)

    let unselectedFriendColor: LinearGradient = LinearGradient(colors: [.black.opacity(0.05)], startPoint: .top, endPoint: .bottom)

    var body: some View {
        ZStack {
            GeometryReader { geo in
                VStack(alignment: .center) {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(appSettingModel.appTheme ? "Gradation background start" : "Gradation background start dark"),
                            Color(appSettingModel.appTheme ? "Gradation background end" : "Gradation background end dark")]),
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }.ignoresSafeArea(.all)

            GeometryReader { geo in
                VStack(alignment: .center) {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(appSettingModel.appTheme ? "Gradation orange start light" : "Gradation background start dark2"), Color(appSettingModel.appTheme ? "Gradation orange end light" : "Gradation background end dark2")]),
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(width: geo.size.height, height: geo.size.height)
                        .cornerRadius(.infinity)
                        .offset(y: geo.size.height * -0.5)
                    Spacer()
                }
            }.ignoresSafeArea(.all)

            GeometryReader { geo in
                VStack(alignment: .center) {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(appSettingModel.appTheme ? "Gradation start light" : "Gradation background start dark3"),
                            Color(appSettingModel.appTheme ? "Gradation end light" : "Gradation background end dark3")]),
                        startPoint: .topTrailing, endPoint: .bottomLeading)
                        .frame(width: geo.size.height, height: geo.size.height)
                        .cornerRadius(.infinity)
                        .offset(x: geo.size.height * -0.5, y: geo.size.height * 0.5)
                    Spacer()
                }
            }.ignoresSafeArea(.all)

            VStack(alignment: .center, spacing: 10) {
                HStack(alignment: .center) {
                    HStack {
                        if mainMessageViewModel.shouldShowBundlesChatrooms {
                            Image(systemName: "chevron.left")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 20)
                                .appThemeForegroundColor(appSettingModel.appTheme)
                        }
                        Text(mainMessageViewModel.shouldShowBundlesChatrooms ? "Bundle" : "Chatrooms")
                            .font(.title)
                            .frame(alignment: .leading)
                            .appThemeForegroundColor(appSettingModel.appTheme)
                    }
                        .contentShape(Rectangle())
                        .onTapGesture {
                        if mainMessageViewModel.shouldShowBundlesChatrooms {
                            mainMessageViewModel.shouldShowAnimationDelayGlassWindow = true
                            withAnimation(.spring(duration: 0.3)) {
                                mainMessageViewModel.tappedBundleId = nil
                                mainMessageViewModel.shouldShowBundlesChatrooms = false
                            } completion: {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    mainMessageViewModel.shouldShowAnimationDelayGlassWindow = false
                                }
                            }
                        }
                    }
                    Spacer()
                    HStack(alignment: .bottom, spacing: 20) {
                        if mainMessageViewModel.shouldShowBundlesChatrooms {
                            Button {
                                withAnimation(.spring(duration: 0.3)) {
                                    mainMessageViewModel.shouldShowBundleSettingView = true
                                }
                            } label: {
                                Image(systemName: "folder.badge.gear")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 22)
                                    .contentShape(Rectangle())
                                    .appThemeForegroundColor(appSettingModel.appTheme)
                            }

                            Button {
                                withAnimation(.spring(duration: 0.3)) {
                                    mainMessageViewModel.shouldShowBundlePositionContextMenu.toggle()
                                }
                            } label: {
                                Image(systemName: "arrow.up.arrow.down")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 22)
                                    .contentShape(Rectangle())
                                    .appThemeForegroundColor(appSettingModel.appTheme)
                            }.onDisappear { mainMessageViewModel.shouldShowBundlePositionContextMenu = false }
                                .overlay (alignment: .topTrailing) { mainMessageViewModel.shouldShowBundlePositionContextMenu ?
                                VStack(alignment: .leading, spacing: 7) {
                                    HStack(alignment: .center) {
                                        Text("Latest")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.black)
                                        Spacer()
                                        if applicationViewModel.getBundleById(mainMessageViewModel.tappedBundleId!)?.bundlePosition == BundlePosition.none {
                                            Image(systemName: "checkmark.circle")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: 14)
                                                .foregroundStyle(.green)
                                        }
                                    }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                        if let bundleid = mainMessageViewModel.tappedBundleId {
                                            injected.interactorContainer.chatroomInteractor.changeBundlePosition(
                                                bundleId: bundleid, position: .none,
                                                chatroomBundles: $applicationViewModel.userChatroomBundles).store(in: &subscriptions)
                                        }
                                    }
                                    Divider()
                                    HStack(alignment: .center) {
                                        Text("Top")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.black)
                                        Spacer()
                                        if applicationViewModel.getBundleById(mainMessageViewModel.tappedBundleId!)?.bundlePosition == BundlePosition.mostTop {
                                            Image(systemName: "checkmark.circle")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: 14)
                                                .foregroundStyle(.green)
                                        }
                                    }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                        if let bundleid = mainMessageViewModel.tappedBundleId {
                                            injected.interactorContainer.chatroomInteractor.changeBundlePosition(
                                                bundleId: bundleid, position: .mostTop,
                                                chatroomBundles: $applicationViewModel.userChatroomBundles).store(in: &subscriptions)
                                        }
                                    }
                                    Divider()
                                    HStack(alignment: .center) {
                                        Text("Bottom")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.black)
                                        Spacer()
                                        if applicationViewModel.getBundleById(mainMessageViewModel.tappedBundleId!)?.bundlePosition == BundlePosition.mostBottom {
                                            Image(systemName: "checkmark.circle")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: 14)
                                                .foregroundStyle(.green)
                                        }
                                    }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                        if let bundleid = mainMessageViewModel.tappedBundleId {
                                            injected.interactorContainer.chatroomInteractor.changeBundlePosition(
                                                bundleId: bundleid, position: .mostBottom,
                                                chatroomBundles: $applicationViewModel.userChatroomBundles).store(in: &subscriptions)
                                        }
                                    }
                                }
                                    .padding(.horizontal)
                                    .padding(.vertical, 7)
                                    .background(.white)
                                    .cornerRadius(10)
                                    .shadow(radius: 3)
                                    .frame(width: screenWidth * 0.4)
                                    .offset(y: 28): nil
                            }
                        } else {
                            Button {
                                withAnimation(.spring(duration: 0.3)) {
                                    mainMessageViewModel.shouldShowCreateNewBundleView = true
                                }
                            } label: {
                                Image(systemName: "folder.badge.plus")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 22)
                                    .contentShape(Rectangle())
                                    .appThemeForegroundColor(appSettingModel.appTheme)
                            }
                            Button(action: {
                                mainMessageViewModel.shouldShowNewChatroomSheet.toggle()
                            }) {
                                Image(systemName: "plus.message")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25)
                                    .contentShape(Rectangle())
                                    .appThemeForegroundColor(appSettingModel.appTheme)
                                    .offset(y: 1)
                            }
                        }
                    }
                }
                    .frame(height: 30)
                    .padding()
                    .zIndex(9)

                if mainMessageViewModel.shouldShowBundlesChatrooms {
                    if let bundleid = mainMessageViewModel.tappedBundleId {
                        if let bundle = applicationViewModel.getBundleById(bundleid) {
                            VStack {
                                if let bundleURL = bundle.bundleProfileURL {
                                    WebImage(url: URL(string: bundleURL))
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: screenWidth * 0.2, height: screenWidth * 0.2)
                                        .clipped()
                                        .cornerRadius(11)
                                        .shadow(radius: 2)
                                        .id(mainMessageViewModel.updatedBundleIconId)
                                        .matchedGeometryEffect(id: "\(bundleid)/photo", in: bundleDescAnimationNamespace)
                                } else {
                                    ZStack {
                                        Image(systemName: "tray.full")
                                            .resizable()
                                            .foregroundStyle(.blue.opacity(0.8))
                                            .padding()
                                            .background { Color.white.cornerRadius(11).shadow(radius: 2) }
                                            .matchedGeometryEffect(id: "\(bundleid)/photo", in: bundleDescAnimationNamespace)
                                    }
                                        .frame(width: screenWidth * 0.2, height: screenWidth * 0.2)
                                        .padding(.top, 8)
                                }
                                Text(bundle.bundleName)
                                    .appThemeForegroundColor(appSettingModel.appTheme)
                                    .font(.system(size: 16, weight: .bold))
                                    .lineLimit(1)
                                    .padding(.horizontal)
                                    .matchedGeometryEffect(id: "\(bundleid)/name", in: bundleDescAnimationNamespace)
                                    .minimumScaleFactor(0.4)
                            }
                        }
                    }
                }

                GeometryReader { geo in
                    ScrollViewReader { scrollViewProxy in
                        ScrollView(showsIndicators: false) {
                            HStack { Spacer() }.frame(height: 1).id("mostTop")
                            Grid(verticalSpacing: 10) {
                                if mainMessageViewModel.shouldShowBundlesChatrooms {
                                    // MARK: - 번들 내 채팅방 뷰
                                    if let bundleid = mainMessageViewModel.tappedBundleId {
                                        let chatrooms = applicationViewModel.getChatroomsInBundleById(bundleid)
                                        if chatrooms.isEmpty {
                                            GridRow {
                                                HStack {
                                                    Spacer()
                                                    Image(systemName: "plus.square.on.square")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .foregroundStyle(appSettingModel.appTheme ? Color.gray.opacity(0.25) : Color.white.opacity(0.4))
                                                        .frame(height: screenHeight * 0.06)
                                                        .padding()
                                                    Spacer()
                                                }
                                                    .frame(height: screenHeight * 0.3)
                                                    .background(BackgroundBlurView().cornerRadius(15))
                                                    .padding(.horizontal, 8)
                                                    .contentShape(Rectangle())
                                                    .onTapGesture {
                                                    withAnimation(.spring(duration: 0.3)) {
                                                        mainMessageViewModel.shouldShowBundleSettingView = true
                                                    }
                                                }
                                            }
                                        } else {
                                            ForEach(Array(stride(from: 0, to: chatrooms.count, by: 2)), id: \.self) { idx in
                                                GridRow {
                                                    HStack(alignment: .center, spacing: 10) {
                                                        ChatroomCard(geo: geo, chatroom: chatrooms[idx], includedBundleId: bundleid) { chatroomid in
                                                            mainMessageViewModel.exitChatroomId = chatroomid
                                                            mainMessageViewModel.exitChatAlert.toggle()
                                                        }.id(chatrooms[idx].chatroomid)
                                                        if idx + 1 < chatrooms.count {
                                                            ChatroomCard(geo: geo, chatroom: chatrooms[idx + 1], includedBundleId: bundleid) { chatroomid in
                                                                mainMessageViewModel.exitChatroomId = chatroomid
                                                                mainMessageViewModel.exitChatAlert.toggle()
                                                            }.id(chatrooms[idx + 1].chatroomid)
                                                        }
                                                    }.padding(.horizontal, 8)
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    // MARK: - 초기 메인메시지 뷰
                                    let cards = applicationViewModel.getMainMessageCards()
                                    ForEach(Array(stride(from: 0, to: cards.count, by: 2)), id: \.self) { idx in
                                        GridRow {
                                            HStack(alignment: .center, spacing: 10) {
                                                if cards[idx].cardType == .bundle {
                                                    let bundle = cards[idx] as! ChatroomBundle
                                                    BundleCard(bundle: bundle, geo: geo, namespace: bundleDescAnimationNamespace)
                                                        .onTapGesture {
                                                        mainMessageViewModel.shouldShowAnimationDelayGlassWindow = true
                                                        withAnimation(.spring(duration: 0.3)) {
                                                            mainMessageViewModel.tappedBundleId = bundle.bundleID
                                                            mainMessageViewModel.shouldShowBundlesChatrooms = true
                                                        } completion: {
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                                mainMessageViewModel.shouldShowAnimationDelayGlassWindow = false
                                                            }
                                                        }
                                                    }
                                                        .id(bundle.bundleID)
                                                } else {
                                                    let chatroom = cards[idx] as! UserChatroom
                                                    ChatroomCard(geo: geo, chatroom: chatroom) { chatroomid in
                                                        mainMessageViewModel.exitChatroomId = chatroomid
                                                        mainMessageViewModel.exitChatAlert.toggle()
                                                    }.id(chatroom.chatroomid)
                                                }

                                                if idx + 1 < cards.count {
                                                    if cards[idx + 1].cardType == .bundle {
                                                        let bundle = cards[idx + 1] as! ChatroomBundle
                                                        BundleCard(bundle: bundle, geo: geo, namespace: bundleDescAnimationNamespace)
                                                            .onTapGesture {
                                                            mainMessageViewModel.shouldShowAnimationDelayGlassWindow = true
                                                            withAnimation(.spring(duration: 0.3)) {
                                                                mainMessageViewModel.tappedBundleId = bundle.bundleID
                                                                mainMessageViewModel.shouldShowBundlesChatrooms = true
                                                            } completion: {
                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                                    mainMessageViewModel.shouldShowAnimationDelayGlassWindow = false
                                                                }
                                                            }
                                                        }
                                                            .id(bundle.bundleID)
                                                    } else {
                                                        let chatroom = cards[idx + 1] as! UserChatroom
                                                        ChatroomCard(geo: geo, chatroom: chatroom) { chatroomid in
                                                            mainMessageViewModel.exitChatroomId = chatroomid
                                                            mainMessageViewModel.exitChatAlert.toggle()
                                                        }.id(chatroom.chatroomid)
                                                    }
                                                }
                                            }.padding(.horizontal, 8)
                                        }
                                    }
                                }
                            }
                                .navigationDestination(for: FlowRouter.DestinationView.self) { des in flowRouter.nextView(des) }
                                .onChange(of: mainMessageViewModel.shouldShowBundlesChatrooms) {
                                withAnimation(.spring(duration: 0.3)) {
                                    scrollViewProxy.scrollTo("mostTop", anchor: .top)
                                }
                            }
                        }
                            .contentMargins(.vertical, 14, for: .scrollContent)
                            .frame(width: geo.size.width)
                    }
                }
            }.padding()
        }
            .overlay(mainMessageViewModel.shouldShowAnimationDelayGlassWindow ? Color.white.opacity(0.001) : nil)
            .background(appSettingModel.appTheme ? Color.white : Color("pastel gray foreground"))
            .onReceive(NotificationCenter.default.publisher(for: .updatedBundleIcon)) { notification in
            withAnimation(.spring(duration: 0.3)) { mainMessageViewModel.updatedBundleIconId = UUID() }
        }
            .fullScreenCover(isPresented: $mainMessageViewModel.shouldShowNewChatroomSheet) { newChatRoomView }
            .fullScreenCover(isPresented: $mainMessageViewModel.shouldShowCreateNewBundleView) { createRoomBundleView }
            .fullScreenCover(isPresented: $mainMessageViewModel.shouldShowBundleSettingView) { settingRoomBundleView }
            .alert(isPresented: $mainMessageViewModel.exitChatAlert) {
            let yes = Alert.Button.default(Text("Leave")) {
                if let email: String = UserDefaultsKeys.userEmail.value() {
                    injected.interactorContainer.chatroomInteractor.exitChatroom(
                        email, self.mainMessageViewModel.exitChatroomId,
                        $applicationViewModel.userChatrooms,
                        $applicationViewModel.userChatroomTitles).store(in: &subscriptions)
                }
            }
            let no = Alert.Button.cancel(Text("Cancel"))
            return Alert(title: Text("Leave Chatroom"),
                message: Text("If you leave, your chats and chat history will all be deleted."),
                primaryButton: yes, secondaryButton: no)
        }.onTapGesture {
            withAnimation(.spring(duration: 0.3)) {
                mainMessageViewModel.shouldShowBundlePositionContextMenu = false
            }
        }
    }

    @ViewBuilder
    private var newChatRoomView: some View {
        VStack {
            HStack(alignment: .center) {
                Button {
                    mainMessageViewModel.shouldShowNewChatroomSheet = false
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20)
                        .contentShape(Rectangle())
                        .appThemeForegroundColor(appSettingModel.appTheme)
                        .padding()
                }
                Spacer()
                Text("New Chatroom")
                    .font(.title)
                    .appThemeForegroundColor(appSettingModel.appTheme)
                Spacer()
                Button(action: {
                    if let email: String = UserDefaultsKeys.userEmail.value() {
                        injected.interactorContainer.chatroomInteractor.createChatroom(email,
                            mainMessageViewModel.selectedUserList, ChatroomType.group.rawValue,
                            $applicationViewModel.userChatrooms,
                            applicationViewModel.userfriends,
                            $applicationViewModel.userChatroomTitles
                        ).sink(receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                print("createChatroom finished")
                            case .failure(let error):
                                print(error.errorDescription ?? "nil")
                            }
                        }, receiveValue: { newChatroom in
                                mainMessageViewModel.shouldShowNewChatroomSheet = false
                                flowRouter.navigate(to: .chatlogView(newChatroom.chatroomid))
                            }
                        ).store(in: &subscriptions)
                    }
                }) {
                    Image(systemName: "checkmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20)
                        .contentShape(Rectangle())
                        .foregroundStyle(mainMessageViewModel.selectedUserList.isEmpty ? Color.gray.opacity(0.7) : Color("pastel green foreground"))
                        .padding()
                }.disabled(mainMessageViewModel.selectedUserList.isEmpty)
            }.padding()

            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(self.mainMessageViewModel.selectedUserList, id: \.self) { su in
                            VStack(alignment: .center) {
                                WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(su)"))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipped()
                                    .cornerRadius(19)
                                    .shadow(radius: 5)
                                Text(applicationViewModel.getNickname(su))
                                    .font(.system(size: 10))
                                    .appThemeForegroundColor(appSettingModel.appTheme)
                            }
                                .frame(maxWidth: 50)
                                .onTapGesture {
                                withAnimation(.spring(duration: 0.3)) {
                                    if let idx = self.mainMessageViewModel.selectedUserList.firstIndex(of: su) {
                                        self.mainMessageViewModel.selectedUserList.remove(at: idx)
                                    }
                                }
                            }
                        }
                    }.padding()
                }
                TextField(text: $mainMessageViewModel.searchKeywordInput) {
                    Text("email")
                        .foregroundStyle(appSettingModel.appTheme ? .black.opacity(0.2) : .white.opacity(0.3))
                }
                    .textInputAutocapitalization(.never)
                    .multilineTextAlignment(.leading)
                    .autocorrectionDisabled(true)
                    .frame(height: 40)
                    .focused($newChatroomViewKeyboardIsFocused)
                    .padding(.leading, 5)
                    .padding(.bottom, 20)
                    .padding(.trailing, 15)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .textFieldStyle(LineTextfieldClearStyle())
                    .submitLabel(.done)
                    .onSubmit {
                    self.newChatroomViewKeyboardIsFocused = false
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(keywordSearchResult(applicationViewModel.userfriends), id: \.self) { friend in
                            HStack(alignment: .center, spacing: 22) {
                                WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(friend.email)"))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 54, height: 54)
                                    .clipped()
                                    .cornerRadius(19)
                                    .shadow(radius: 5)
                                VStack(alignment: .leading) {
                                    (friend.nickname ?? friend.email)
                                        .highlightingText(mainMessageViewModel.searchKeywordInput, appSettingModel.appTheme)
                                    HStack(alignment: .center) {
                                        friend.email
                                            .highlightingEmailText(mainMessageViewModel.searchKeywordInput, appSettingModel.appTheme)
                                            .foregroundStyle(appSettingModel.appTheme ? Color("pastel blue foreground") : Color("pastel yellow foreground"))
                                    }.padding(0)
                                        .cornerRadius(10)
                                        .if(appSettingModel.appTheme) { view in
                                        view
                                            .background {
                                            RoundedRectangle(cornerRadius: 10)
                                                .foregroundStyle(Color("pastel blue")) }
                                    }.if(!appSettingModel.appTheme) { view in
                                        view.overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color("pastel yellow foreground"), lineWidth: 1)
                                        )
                                    }
                                }
                                Spacer()
                            }
                                .padding(.vertical, 9)
                                .padding(.leading, 12)
                                .background {
                                Rectangle()
                                    .foregroundStyle(mainMessageViewModel.selectedUserList.contains(friend.email) ? selectedFriendColor : unselectedFriendColor)
                                    .cornerRadius(10)
                            }.onTapGesture {
                                withAnimation(.spring(duration: 0.3)) {
                                    if mainMessageViewModel.selectedUserList.contains(friend.email) {
                                        let idx = mainMessageViewModel.selectedUserList.firstIndex(of: friend.email)!
                                        mainMessageViewModel.selectedUserList.remove(at: idx)
                                    } else {
                                        mainMessageViewModel.selectedUserList.append(friend.email)
                                    }
                                }
                            }
                        }
                    }.padding()
                }
            }.onAppear {
                self.mainMessageViewModel.selectedUserList = []
                self.mainMessageViewModel.searchKeywordInput = ""
            }
        }
            .ignoresSafeArea(.keyboard, edges: .all)
            .background {
            if appSettingModel.appTheme {
                BackgroundBlurView().ignoresSafeArea(.all)
            } else {
                BackgroundDarkBlurView().ignoresSafeArea(.all)
            }
        }
    }

    @ViewBuilder
    private var createRoomBundleView: some View {
        VStack {
            HStack(alignment: .center) {
                Button {
                    mainMessageViewModel.shouldShowCreateNewBundleView = false
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20)
                        .contentShape(Rectangle())
                        .appThemeForegroundColor(appSettingModel.appTheme)
                        .padding()
                }
                Spacer()
                Text("Chatroom Bundle")
                    .font(.title)
                    .appThemeForegroundColor(appSettingModel.appTheme)
                Spacer()
                Button(action: {
                    injected.interactorContainer.chatroomInteractor.createChatroomBundle(
                        bundleName: mainMessageViewModel.newChatroomBundleName,
                        bundleProfileImage: mainMessageViewModel.newChatroomBundlePhotoUIImage,
                        chatroomBundles: $applicationViewModel.userChatroomBundles,
                        selectedRoomIdList: mainMessageViewModel.newChatroomBundleRoomIds)
                        .store(in: &subscriptions)
                    mainMessageViewModel.shouldShowCreateNewBundleView = false
                }) {
                    Image(systemName: "checkmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20)
                        .contentShape(Rectangle())
                        .foregroundStyle(mainMessageViewModel.newChatroomBundleName.isEmpty ? .gray.opacity(0.8) : Color("pastel green foreground"))
                        .padding()
                }.disabled(mainMessageViewModel.newChatroomBundleName.isEmpty)
            }.padding()

            VStack {
                HStack(alignment: .center) {
                    Spacer()
                    PhotosPicker(selection: $mainMessageViewModel.newChatroomBundlePhoto, matching: .images) {
                        ZStack (alignment: .center) {
                            if let bundlePhoto = mainMessageViewModel.newChatroomBundlePhotoUIImage {
                                Image(uiImage: bundlePhoto)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: screenWidth * 0.34, height: screenWidth * 0.34)
                                    .cornerRadius(15)
                                    .shadow(radius: 1)
                            } else {
                                Image(systemName: "tray.full")
                                    .resizable()
                                    .padding(screenWidth * 0.1)
                                    .background(Color.white)
                                    .cornerRadius(15)
                                    .shadow(radius: 1)
                            }
                        }.frame(width: screenWidth * 0.34, height: screenWidth * 0.34)
                    }
                    Spacer()
                }
                    .padding(.bottom)
                    .onChange(of: mainMessageViewModel.newChatroomBundlePhoto) { _, newImage in
                    Task(priority: .high) {
                        if let data = try? await newImage?.loadTransferable(type: Data.self) {
                            if let uiImage = UIImage(data: data) {
                                withAnimation(.easeInOut(duration: 0.3)) { mainMessageViewModel.newChatroomBundlePhotoUIImage = uiImage }
                            }
                        }
                    }
                }
                TextField(text: $mainMessageViewModel.newChatroomBundleName) {
                    Text("Bundle Name")
                        .foregroundStyle(appSettingModel.appTheme ? .black.opacity(0.2) : .white.opacity(0.3))
                }
                    .textInputAutocapitalization(.never)
                    .multilineTextAlignment(.leading)
                    .autocorrectionDisabled(true)
                    .frame(height: 40)
                    .padding(.leading, 5)
                    .padding(.bottom, 20)
                    .padding(.trailing, 15)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .textFieldStyle(LineTextfieldClearStyle())
                    .submitLabel(.done)

                ScrollView(showsIndicators: false) {
                    VStack {
                        if let me: String = UserDefaultsKeys.userEmail.value() {
                            ForEach(applicationViewModel.bundleableChatrooms, id: \.self) { chatroom in
                                HStack(alignment: .center, spacing: 18) {
                                    if mainMessageViewModel.newChatroomBundleRoomIds.contains(chatroom.chatroomid) {
                                        Image(systemName: "checkmark.circle")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: screenHeight * 0.1 * 0.25)
                                            .foregroundStyle(.green)
                                    }

                                    if chatroom.audiencelist.count >= 3 {
                                        ZStack {
                                            ZStack {
                                                Color.white
                                                Image(systemName: "person.3")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .padding(5)
                                            }
                                                .cornerRadius(9)
                                                .shadow(radius: 1)
                                            WebImage(url: URL(string: "chatroomPhoto\(chatroom.chatroomid)"), options: [.fromCacheOnly])
                                                .resizable()
                                                .clipped()
                                                .cornerRadius(9)
                                                .shadow(radius: 2)
                                        }.frame(width: screenHeight * 0.1 * 0.5, height: screenHeight * 0.1 * 0.5)
                                    } else if chatroom.audiencelist.count == 2 {
                                        ZStack {
                                            let audienceEmail = chatroom.audiencelist.filter { $0 != me }.first!
                                            WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(audienceEmail)"), options: [.fromCacheOnly])
                                                .resizable()
                                                .frame(width: screenHeight * 0.1 * 0.5, height: screenHeight * 0.1 * 0.5)
                                                .clipped()
                                                .background(Color(UIColor.systemBackground))
                                                .cornerRadius(9)
                                                .shadow(radius: 2)
                                            WebImage(url: URL(string: "chatroomPhoto\(chatroom.chatroomid)"), options: [.fromCacheOnly])
                                                .resizable()
                                                .frame(width: screenHeight * 0.1 * 0.5, height: screenHeight * 0.1 * 0.5)
                                                .clipped()
                                                .cornerRadius(9)
                                                .shadow(radius: 2)
                                        }
                                    } else {
                                        ZStack {
                                            Color.white
                                            Image(systemName: "person.2.slash")
                                                .resizable()
                                                .scaledToFit()
                                                .padding(5)
                                        }
                                            .frame(width: screenHeight * 0.1 * 0.5, height: screenHeight * 0.1 * 0.5)
                                            .cornerRadius(9)
                                            .shadow(radius: 1)
                                    }

                                    VStack(alignment: .leading) {
                                        switch chatroom.roomtype {
                                        case .group:
                                            Text("Group")
                                                .font(.system(size: 11.3))
                                                .foregroundStyle(Color("pastel orange foreground"))
                                                .padding(.vertical, 1)
                                                .padding(.horizontal, 8)
                                                .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color("pastel orange foreground"))
                                            )
                                        case .pair:
                                            Text("Pair")
                                                .font(.system(size: 11.3))
                                                .foregroundStyle(Color("pastel blue foreground"))
                                                .padding(.vertical, 1)
                                                .padding(.horizontal, 8)
                                                .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color("pastel blue foreground"))
                                            )
                                        }
                                        if let chatroomtitle = applicationViewModel.userChatroomTitles[chatroom.chatroomid] {
                                            Text(chatroomtitle)
                                                .appThemeForegroundColor(appSettingModel.appTheme)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.6)
                                        }
                                    }
                                    Spacer()
                                }
                                    .padding(.horizontal)
                                    .padding(.vertical, 7)
                                    .contentShape(Rectangle())
                                    .background {
                                    if mainMessageViewModel.newChatroomBundleRoomIds.contains(chatroom.chatroomid) {
                                        Rectangle()
                                            .foregroundStyle(selectedFriendColor)
                                            .cornerRadius(10)
                                    }
                                }.onTapGesture {
                                    withAnimation(.spring(duration: 0.3)) {
                                        if mainMessageViewModel.newChatroomBundleRoomIds.contains(chatroom.chatroomid) {
                                            if let idx = mainMessageViewModel.newChatroomBundleRoomIds.firstIndex(where: { $0 == chatroom.chatroomid }) {
                                                mainMessageViewModel.newChatroomBundleRoomIds.remove(at: idx)
                                            }
                                        } else {
                                            mainMessageViewModel.newChatroomBundleRoomIds.append(chatroom.chatroomid)
                                        }
                                    }
                                }
                            }
                        }

                    }.padding(.horizontal)
                }
            }
        }.onAppear {
            mainMessageViewModel.newChatroomBundleName = ""
            mainMessageViewModel.newChatroomBundleRoomIds = []
            mainMessageViewModel.newChatroomBundlePhoto = nil
            mainMessageViewModel.newChatroomBundlePhotoUIImage = nil
        }.background {
            if appSettingModel.appTheme {
                BackgroundBlurView().ignoresSafeArea(.all)
            } else {
                BackgroundDarkBlurView().ignoresSafeArea(.all)
            }
        }
    }

    @ViewBuilder
    private var settingRoomBundleView: some View {
        VStack {
            HStack(alignment: .center) {
                Button {
                    mainMessageViewModel.shouldShowBundleSettingView = false
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20)
                        .contentShape(Rectangle())
                        .appThemeForegroundColor(appSettingModel.appTheme)
                        .padding()
                }
                Spacer()
                Text("Bundle Editing")
                    .font(.title)
                    .appThemeForegroundColor(appSettingModel.appTheme)
                Spacer()
                Button(action: {
                    mainMessageViewModel.shouldShowBundleSettingView = false
                    if mainMessageViewModel.shouldShowBundlesChatrooms {
                        if let bundleid = mainMessageViewModel.tappedBundleId {
                            if let bundle = applicationViewModel.getBundleById(bundleid) {
                                injected.interactorContainer.chatroomInteractor.editingBundle(bundleId: bundleid,
                                    newBundleName: mainMessageViewModel.editingBundleName.isEmpty ? bundle.bundleName : mainMessageViewModel.editingBundleName,
                                    bundleIconImage: mainMessageViewModel.editingBundlePhotoUIImage,
                                    chatroomids: mainMessageViewModel.editingBundleRoomIds,
                                    chatroomBundles: $applicationViewModel.userChatroomBundles)
                                    .store(in: &subscriptions)
                            }
                        }
                    }
                }) {
                    Image(systemName: "checkmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20)
                        .contentShape(Rectangle())
                        .padding()
                        .foregroundStyle(mainMessageViewModel.editingBundleRoomIds.isEmpty
                            && mainMessageViewModel.editingBundleName.isEmpty
                            && mainMessageViewModel.editingBundlePhotoUIImage == nil ? .gray : .green)
                }.disabled(mainMessageViewModel.editingBundleRoomIds.isEmpty
                        && mainMessageViewModel.editingBundleName.isEmpty
                        && mainMessageViewModel.editingBundlePhotoUIImage == nil)
            }.padding()

            VStack {
                HStack(alignment: .center) {
                    Spacer()
                    PhotosPicker(selection: $mainMessageViewModel.editingBundlePhoto, matching: .images) {
                        ZStack (alignment: .center) {
                            if let bundleid = mainMessageViewModel.tappedBundleId {
                                if let bundle = applicationViewModel.getBundleById(bundleid) {
                                    if let bundleIconURL = bundle.bundleProfileURL {
                                        WebImage(url: URL(string: bundleIconURL))
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: screenWidth * 0.34, height: screenWidth * 0.34)
                                            .cornerRadius(15)
                                            .shadow(radius: 1)
                                    } else {
                                        Image(systemName: "tray.full")
                                            .resizable()
                                            .padding(screenWidth * 0.1)
                                            .background(Color.white)
                                            .cornerRadius(15)
                                            .shadow(radius: 1)
                                    }
                                }
                            }
                            if let newBundleIcon = mainMessageViewModel.editingBundlePhotoUIImage {
                                Image(uiImage: newBundleIcon)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: screenWidth * 0.34, height: screenWidth * 0.34)
                                    .cornerRadius(15)
                            }
                        }.frame(width: screenWidth * 0.34, height: screenWidth * 0.34)
                    }.onChange(of: mainMessageViewModel.editingBundlePhoto) { _, newImage in
                        Task(priority: .high) {
                            if let data = try? await newImage?.loadTransferable(type: Data.self) {
                                if let uiImage = UIImage(data: data) {
                                    withAnimation(.easeInOut(duration: 0.3)) { mainMessageViewModel.editingBundlePhotoUIImage = uiImage }
                                }
                            }
                        }
                    }
                    Spacer()
                }

                TextField(text: $mainMessageViewModel.editingBundleName) {
                    if let bundleid = mainMessageViewModel.tappedBundleId {
                        if let bundle = applicationViewModel.getBundleById(bundleid) {
                            Text(bundle.bundleName)
                                .foregroundStyle(appSettingModel.appTheme ? .black.opacity(0.2) : .white.opacity(0.3))
                        }
                    }
                }
                    .textInputAutocapitalization(.never)
                    .multilineTextAlignment(.leading)
                    .autocorrectionDisabled(true)
                    .frame(height: 40)
                    .padding(.leading, 5)
                    .padding(.bottom, 20)
                    .padding(.trailing, 15)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .textFieldStyle(LineTextfieldClearStyle())
                    .submitLabel(.done)

                ScrollView(showsIndicators: false) {
                    VStack {
                        if let me: String = UserDefaultsKeys.userEmail.value() {
                            ForEach(applicationViewModel.bundleableChatrooms, id: \.self) { chatroom in
                                HStack(alignment: .center, spacing: 18) {
                                    if mainMessageViewModel.editingBundleRoomIds.contains(chatroom.chatroomid) {
                                        Image(systemName: "checkmark.circle")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: screenHeight * 0.1 * 0.25)
                                            .foregroundStyle(.green)
                                    }
                                    if chatroom.audiencelist.count >= 3 {
                                        ZStack {
                                            ZStack {
                                                Color.white
                                                Image(systemName: "person.3")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .padding(5)
                                            }
                                                .cornerRadius(9)
                                                .shadow(radius: 1)
                                            WebImage(url: URL(string: "chatroomPhoto\(chatroom.chatroomid)"), options: [.fromCacheOnly])
                                                .resizable()
                                                .clipped()
                                                .cornerRadius(9)
                                                .shadow(radius: 2)
                                        }.frame(width: screenHeight * 0.1 * 0.5, height: screenHeight * 0.1 * 0.5)
                                    } else if chatroom.audiencelist.count == 2 {
                                        ZStack {
                                            let audienceEmail = chatroom.audiencelist.filter { $0 != me }.first!
                                            WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(audienceEmail)"), options: [.fromCacheOnly])
                                                .resizable()
                                                .frame(width: screenHeight * 0.1 * 0.5, height: screenHeight * 0.1 * 0.5)
                                                .clipped()
                                                .background(Color(UIColor.systemBackground))
                                                .cornerRadius(9)
                                                .shadow(radius: 2)
                                            WebImage(url: URL(string: "chatroomPhoto\(chatroom.chatroomid)"), options: [.fromCacheOnly])
                                                .resizable()
                                                .frame(width: screenHeight * 0.1 * 0.5, height: screenHeight * 0.1 * 0.5)
                                                .clipped()
                                                .cornerRadius(9)
                                                .shadow(radius: 2)
                                        }
                                    } else {
                                        ZStack {
                                            Color.white
                                            Image(systemName: "person.2.slash")
                                                .resizable()
                                                .scaledToFit()
                                                .padding(5)
                                        }
                                            .frame(width: screenHeight * 0.1 * 0.5, height: screenHeight * 0.1 * 0.5)
                                            .cornerRadius(9)
                                            .shadow(radius: 1)
                                    }

                                    VStack(alignment: .leading) {
                                        switch chatroom.roomtype {
                                        case .group:
                                            Text("Group")
                                                .font(.system(size: 11.3))
                                                .foregroundStyle(Color("pastel orange foreground"))
                                                .padding(.vertical, 1)
                                                .padding(.horizontal, 8)
                                                .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color("pastel orange foreground"))
                                            )
                                        case .pair:
                                            Text("Pair")
                                                .font(.system(size: 11.3))
                                                .foregroundStyle(Color("pastel blue foreground"))
                                                .padding(.vertical, 1)
                                                .padding(.horizontal, 8)
                                                .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color("pastel blue foreground"))
                                            )
                                        }
                                        if let chatroomtitle = applicationViewModel.userChatroomTitles[chatroom.chatroomid] {
                                            Text(chatroomtitle)
                                                .appThemeForegroundColor(appSettingModel.appTheme)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.6)
                                        }
                                    }
                                    Spacer()
                                }
                                    .padding(.horizontal)
                                    .padding(.vertical, 7)
                                    .contentShape(Rectangle())
                                    .background {
                                    if mainMessageViewModel.editingBundleRoomIds.contains(chatroom.chatroomid) {
                                        Rectangle()
                                            .foregroundStyle(selectedFriendColor)
                                            .cornerRadius(10)
                                    }
                                }.onTapGesture {
                                    withAnimation(.spring(duration: 0.3)) {
                                        if mainMessageViewModel.editingBundleRoomIds.contains(chatroom.chatroomid) {
                                            if let idx = mainMessageViewModel.editingBundleRoomIds.firstIndex(where: { $0 == chatroom.chatroomid }) {
                                                mainMessageViewModel.editingBundleRoomIds.remove(at: idx)
                                            }
                                        } else {
                                            mainMessageViewModel.editingBundleRoomIds.append(chatroom.chatroomid)
                                        }
                                    }
                                }
                            }
                        }
                    }.padding(.horizontal)
                }
            }
        }.background {
            if appSettingModel.appTheme {
                BackgroundBlurView().ignoresSafeArea(.all)
            } else {
                BackgroundDarkBlurView().ignoresSafeArea(.all)
            }
        }.onAppear {
            mainMessageViewModel.editingBundleName = ""
            mainMessageViewModel.editingBundleRoomIds = []
            mainMessageViewModel.editingBundlePhoto = nil
            mainMessageViewModel.editingBundlePhotoUIImage = nil
        }
    }

    private func keywordSearchResult(_ friendList: [UserFriend]) -> [UserFriend] {
        if mainMessageViewModel.searchKeywordInput == "" {
            return friendList
        } else {
            return friendList.filter {
                $0.email.contains(mainMessageViewModel.searchKeywordInput) || $0.nickname?.contains(mainMessageViewModel.searchKeywordInput) ?? false
            }
        }
    }
}
