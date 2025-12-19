import SwiftUI
import SDWebImageSwiftUI
import Combine

struct SideMenu: View {

    @EnvironmentObject var flowRouter: FlowRouter
    @EnvironmentObject var appSettingModel: AppSettingModel
    @EnvironmentObject var applicationViewModel: ApplicationViewModel
    @Environment(\.injected) private var injected: DIContainer
    @Environment(\.verticalSizeClass) var verticalSizeClass

    @Binding var isShowing: Bool
    @Binding var isPresentSidemenu: Bool
    @Binding var sideMenuOffset: CGFloat
    @Binding var chatlog: [any Logable]
    @Binding var chatroomTitle: String
    @State var shouldShowFullScreenPhoto: Bool = false
    @State private var subscriptions: Set<AnyCancellable> = []
    @State var chatroomTitleTextFeild = ""
    @State var successToLoadChatroomProfilePhoto = true
    @State var refresh = true

    let ChatroomType: ChatroomType
    let chatroomid: String
    var audienceList: Set<String>
    let showFriendDetailView: (String) -> ()

    let showFullScreenChatPhotoView: (String) -> ()

    var body: some View {
        ZStack(alignment: .trailing) {
            if isShowing {
                Color.black.opacity(0.7)
                    .onTapGesture {
                    withAnimation(.spring(duration: 0.3)) {
                        sideMenuOffset = UIScreen.main.bounds.width * 0.9
                        isShowing = false
                    } completion: { isPresentSidemenu = false }
                }.zIndex(-1)
            }
            if isPresentSidemenu {
                HStack(alignment: .center) {
                    Spacer()
                    VStack(alignment: .leading, spacing: 0) {
                        if ChatroomType == .group {
                            HStack(alignment: .center, spacing: 5) {
                                Image(systemName: "bubble.left.and.text.bubble.right.rtl")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 25)
                                    .appThemeForegroundColor(appSettingModel.appTheme)
                                Text("Infomation")
                                    .font(.title2)
                                    .appThemeForegroundColor(appSettingModel.appTheme)
                            }
                                .padding(.vertical, 15)
                                .padding(.horizontal)
                            VStack(alignment: .center, spacing: 10) {
                                ZStack {
                                    Image(systemName: "person.3")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        .clipped()
                                        .background(Color(UIColor.systemBackground))
                                        .cornerRadius(19)
                                        .shadow(radius: 5)
                                        .padding(.top, 8)
                                        .opacity(successToLoadChatroomProfilePhoto ? 1.0 : 0)
                                    if refresh {
                                        WebImage(url: URL(string: "chatroomPhoto\(chatroomid)"), options: [.fromCacheOnly])
                                            .onSuccess { _, _, _ in
                                            successToLoadChatroomProfilePhoto = false }
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipped()
                                            .cornerRadius(19)
                                            .shadow(radius: 5)
                                            .padding(.top, 8)
                                            .onReceive(NotificationCenter.default.publisher(for: .updatedChatroomProfilePhoto)) { notification in
                                            let roomid: String = notification.userInfo!["roomid"] as! String
                                            if chatroomid == roomid {
                                                refresh = false
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { refresh = true }
                                            }
                                        }
                                    }
                                }
                                HStack(alignment: .center, spacing: 3) {
                                    Spacer()
                                    Text(chatroomTitle)
                                        .frame(maxWidth: 250)
                                        .lineLimit(1)
                                        .appThemeForegroundColor(appSettingModel.appTheme)
                                        .font(.system(size: 20))
                                    Spacer()
                                }
                            }.padding(.horizontal)
                        }
                        HStack(alignment: .center, spacing: 5) {
                            Image(systemName: "person.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 25)
                                .appThemeForegroundColor(appSettingModel.appTheme)
                            Text("Participants")
                                .font(.title2)
                                .appThemeForegroundColor(appSettingModel.appTheme)
                            Spacer()
                        }
                            .padding(.vertical, 15)
                            .padding(.horizontal)
                        VStack(alignment: .leading, spacing: 10) {
                            if let me: String = UserDefaultsKeys.userEmail.value() {
                                HStack(spacing: 6.5) {
                                    WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(me)"), options: [.fromCacheOnly])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 30, height: 30)
                                        .clipped()
                                        .cornerRadius(9)
                                        .shadow(radius: 1)
                                        .modifier(RefreshableWebImageProfileModifier(me, true))
                                    Rectangle()
                                        .fill(.gray)
                                        .cornerRadius(6)
                                        .frame(width: 25, height: 18)
                                        .overlay(
                                        Text("me")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.white)
                                    )
                                    if let nickname: String = UserDefaultsKeys.userNickname.value() {
                                        Text(nickname).appThemeForegroundColor(appSettingModel.appTheme)
                                    } else {
                                        Text(me)
                                    }
                                    Spacer()
                                }
                                ForEach(audienceList.filter { $0 != me }, id: \.self) { email in
                                    HStack {
                                        WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(email)"), options: [.fromCacheOnly])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 30, height: 30)
                                            .clipped()
                                            .cornerRadius(9)
                                            .shadow(radius: 1)
                                            .modifier(RefreshableWebImageProfileModifier(email, false))
                                        Text(applicationViewModel.userfriends.first { $0.email == email }?.nickname ?? email)
                                            .appThemeForegroundColor(appSettingModel.appTheme)
                                        Spacer()
                                    }.onTapGesture { showFriendDetailView(email) }
                                }
                            }
                        }.padding(.horizontal)

                        HStack(alignment: .center, spacing: 5) {
                            Image(systemName: "photo")
                                .resizable()
                                .frame(width: 25, height: 23)
                                .appThemeForegroundColor(appSettingModel.appTheme)
                            Text("Photos")
                                .font(.title2)
                                .appThemeForegroundColor(appSettingModel.appTheme)
                            Spacer()
                        }.padding(.top, 15).padding(.horizontal)

                        if photos.isEmpty {
                            HStack(alignment: .center) {
                                Spacer()
                                Image(systemName: "photo.on.rectangle.angled")
                                    .resizable()
                                    .frame(width: 120, height: 120)
                                    .foregroundStyle(appSettingModel.appTheme ? .black.opacity(0.2) : .white.opacity(0.2))
                                Spacer()
                            }.padding()
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack (spacing: 10) {
                                    ForEach(photos, id: \.self.id) { item in
                                        WebImage(url: URL(string: "\(serverUrl)/chat/get-chatphoto/\(item.id)"))
                                            .resizable()
                                            .cornerRadius(10)
                                            .scaledToFit()
                                            .containerRelativeFrame(.horizontal, count: verticalSizeClass == .regular ? 2 : 4, spacing: 16)
                                            .containerRelativeFrame(.vertical, count: 1, spacing: 0)
                                            .scrollTransition { content, phase in
                                            content.opacity(phase.isIdentity ? 1.0 : 0.0)
                                                .scaleEffect(x: phase.isIdentity ? 1.0 : 0.3, y: phase.isIdentity ? 1.0 : 0.3)
                                                .offset(y: phase.isIdentity ? 0 : 50)
                                        }
                                            .clipped()
                                            .onTapGesture { showFullScreenChatPhotoView(item.id) }
                                    }
                                }
                                    .scrollTargetLayout()
                                    .frame(height: 140)
                            }
                                .contentMargins(16, for: .scrollContent)
                                .scrollTargetBehavior(.viewAligned)
                                .highPriorityGesture(DragGesture().onEnded { _ in })
                        }
                        Spacer()
                    }
                        .frame(width: screenWidth * 0.85, alignment: .leading)
                        .background(appSettingModel.appTheme ? Color("Sidemenu background light") : Color("Sidemenu background dark"))
                        .offset(x: sideMenuOffset)
                        .clipped()
                        .padding(0)
                        .gesture(DragGesture(minimumDistance: .zero, coordinateSpace: .global).onChanged { value in
                            if value.translation.width > 0 {
                                sideMenuOffset = value.translation.width
                            }
                        }.onEnded { value in
                            if value.translation.width > screenWidth * 0.35 {
                                withAnimation(.spring(duration: 0.3)) {
                                    sideMenuOffset = screenWidth * 0.9
                                    isShowing = false
                                } completion: { isPresentSidemenu = false }
                            } else {
                                withAnimation(.spring(duration: 0.3)) { sideMenuOffset = .zero }
                            }
                        }
                    )
                }
            }
        }
            .ignoresSafeArea(.container, edges: .bottom)
            .zIndex(999)
            .frame(alignment: .trailing)
    }

    private var photos: [any Logable] {
        chatlog.filter { $0.logType == .photo }.sorted(by: { $0.timestamp > $1.timestamp })
    }
}
