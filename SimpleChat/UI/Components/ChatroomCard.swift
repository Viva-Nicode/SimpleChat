import SwiftUI
import Combine

struct ChatroomCard: View {
    var geo: GeometryProxy
    var chatroom: UserChatroom
    var includedBundleId: String?
    @State private var isFlipped = false
    @State private var filpBackground = false
    @State private var subscriptions: Set<AnyCancellable> = []
    @Environment(\.injected) private var injected: DIContainer
    @EnvironmentObject var applicationViewModel: ApplicationViewModel
    @EnvironmentObject var appSettingModel: AppSettingModel
    @EnvironmentObject var flowRouter: FlowRouter
    let shouldShowExitChatroomAlert: (String) -> ()

    var body: some View {
        VStack (alignment: .center, spacing: 0) {
            ZStack {
                VStack {
                    HStack(alignment: .center) {
                        switch chatroom.roomtype {
                        case .group:
                            Text("Group")
                                .font(.system(size: 11.3))
                                .foregroundStyle(Color("pastel orange foreground"))
                                .padding(.vertical, 3)
                                .padding(.horizontal, 8)
                                .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color("pastel orange foreground"))
                            )
                        case .pair:
                            Text("Pair")
                                .font(.system(size: 11.3))
                                .foregroundStyle(Color("pastel blue foreground"))
                                .padding(.vertical, 3)
                                .padding(.horizontal, 8)
                                .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color("pastel blue foreground"))
                            )
                        }
                        if chatroom.notificationMuteState {
                            HStack(alignment: .center) {
                                Image(systemName: "bell.slash")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundStyle(chatroom.roomtype == .pair ? Color("pastel blue foreground") : Color("pastel orange foreground"))
                                    .frame(width: geo.size.width * 0.5 * 0.1)
                            }.frame(height: geo.size.width * 0.5 * 0.1)
                        }
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                isFlipped = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    filpBackground = true
                                }
                            }
                        } label: {
                            ZStack {
                                Color.clear
                                Image(systemName: "ellipsis")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(Color(chatroom.roomtype == .group ? "pastel orange foreground" : "pastel blue foreground"))
                            }
                                .frame(width: geo.size.width * 0.5 * 0.15)
                                .padding(.horizontal, 5)
                                .contentShape(Rectangle())
                        }
                    }
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 7)
                        .padding(.horizontal, 8)

                    ZStack (alignment: .topTrailing) {
                        ChatroomProfileView(
                            audienceSet: chatroom.audiencelist,
                            chatroomid: chatroom.chatroomid,
                            profilePhotoSize: geo.size.width * 0.5 * 0.5)
                        if let me: String = UserDefaultsKeys.userEmail.value() {
                            let unreadCount = chatroom.unreadCount(me)
                            if unreadCount > 0 {
                                Text(String(unreadCount))
                                    .foregroundStyle(Color("pastel blue foreground"))
                                    .padding(.horizontal, 5)
                                    .font(.system(size: 16, weight: .semibold))
                                    .background {
                                    RoundedRectangle(cornerRadius: .infinity)
                                        .foregroundStyle(Color("pastel blue"))
                                }
                            }
                        }
                    }.frame(width: geo.size.width * 0.5)

                    if let chatroomtitle = applicationViewModel.userChatroomTitles[chatroom.chatroomid] {
                        Text(chatroomtitle)
                            .appThemeForegroundColor(appSettingModel.appTheme)
                            .font(.system(size: 16, weight: .bold))
                            .lineLimit(1)
                            .padding(.horizontal)
                    }
                    VStack(alignment: .center) {
                        Spacer()
                        Text(verbatim: chatroom.recentLogDetail { applicationViewModel.getNickname($0) })
                            .font(.system(size: 13))
                            .appThemeForegroundColor(appSettingModel.appTheme)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }.padding(9)

                    HStack(alignment: .center) {
                        if let timestamp = chatroom.log.last?.showableTimestamp {
                            Text("\(timestamp) ago")
                                .font(.system(size: 14, weight: .semibold))
                                .appThemeForegroundColor(appSettingModel.appTheme)
                        }
                        Spacer()
                    }
                        .padding(.leading)
                        .padding(.bottom)
                }
                    .opacity(filpBackground ? 0.0001 : 1)
                    .onTapGesture {
                    if !isFlipped {
                        flowRouter.navigate(to: .chatlogView(chatroom.chatroomid))
                    }
                }

                VStack {
                    HStack(alignment: .center) {
                        if let includedBundleId {
                            Button {
                                injected.interactorContainer.chatroomInteractor.removeChatroomFromBundle(
                                    bundleId: includedBundleId, chatroomid: chatroom.chatroomid,
                                    chatroomBundles: $applicationViewModel.userChatroomBundles)
                                    .store(in: &subscriptions)
                            } label: {
                                Image(systemName: "folder.badge.minus")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 19)
                                    .padding(.horizontal, 3)
                                    .foregroundStyle(chatroom.roomtype == .pair ? .blue : .orange)
                                    .contentShape(Rectangle())
                            }
                        }
                        Text("Pair")
                            .font(.system(size: 11.3))
                            .foregroundStyle(Color("pastel blue foreground"))
                            .padding(.vertical, 3)
                            .padding(.horizontal, 8)
                            .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color("pastel blue foreground"))
                        ).hidden()
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                isFlipped = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    filpBackground = false
                                }
                            }
                        } label: {
                            ZStack {
                                Color.clear
                                Image(systemName: "ellipsis")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(Color(chatroom.roomtype == .group ? "pastel orange foreground" : "pastel blue foreground"))
                            }
                                .frame(width: geo.size.width * 0.5 * 0.15)
                                .padding(.horizontal, 5)
                                .contentShape(Rectangle())
                        }
                    }
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 7)
                        .padding(.horizontal, 8)
                    VStack(alignment: .center) {
                        Button {
                            if let me: String = UserDefaultsKeys.userEmail.value() {
                                if let idx = applicationViewModel.userChatrooms[chatroom.chatroomid] {
                                    injected.interactorContainer.chatroomInteractor.setChatroomNotification(
                                        email: me,
                                        chatroomid: chatroom.chatroomid,
                                        notiStata: $applicationViewModel.userChatrooms[idx].notificationMuteState,
                                        isFlipped: $isFlipped, filpBackground: $filpBackground)
                                        .store(in: &subscriptions)
                                }
                            }
                        } label: {
                            HStack(alignment: .center) {
                                Image(systemName: chatroom.notificationMuteState ? "bell.badge" : "bell.slash")
                                    .resizable()
                                    .foregroundStyle(.white)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 15.5)
                                Text(chatroom.notificationMuteState ? "Chirp" : "Silent")
                                    .font(.system(size: 15.5))
                                    .foregroundStyle(.white)
                            }
                                .padding(.horizontal)
                                .padding(.vertical, 5)
                                .background {
                                RoundedRectangle(cornerRadius: .infinity)
                                    .foregroundStyle(Color("pastel yellow foreground"))
                            }
                        }

                        Button {
                            shouldShowExitChatroomAlert(chatroom.chatroomid)
                        } label: {
                            HStack(alignment: .center) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .resizable()
                                    .foregroundStyle(.white)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 15.5)
                                Text("Leave")
                                    .font(.system(size: 15.5))
                                    .foregroundStyle(.white)
                            }
                                .padding(.horizontal)
                                .padding(.vertical, 5)
                                .background {
                                RoundedRectangle(cornerRadius: .infinity)
                                    .foregroundStyle(Color("pastel red foreground"))
                            }
                        }
                        Spacer()
                    }
                }
                    .opacity(filpBackground ? 1 : 0.0001)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }.background {
            if appSettingModel.appTheme {
                if filpBackground {
                    Color("pastel yellow").cornerRadius(10)
                } else {
                    BackgroundBlurView().cornerRadius(10)
                }
            } else {
                if filpBackground {
                    Color("pastel yellow").cornerRadius(10)
                } else {
                    BackgroundDarkBlurView().cornerRadius(10)
                }
            }
        }
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .gesture(
            DragGesture()
                .onEnded({ value in
                if isFlipped {
                    if value.translation.width < geo.size.width * 0.5 * -0.2 {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            isFlipped = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                filpBackground = false
                            }
                        }
                    }
                } else {
                    if value.translation.width > geo.size.width * 0.5 * 0.2 {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            isFlipped = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                filpBackground = true
                            }
                        }
                    }
                }
            })
        )
    }
}
