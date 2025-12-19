import SwiftUI
import SDWebImageSwiftUI
import Combine

struct CheckButton: View {
    @Binding var isChecked: Bool

    var body: some View {
        if isChecked {
            Circle()
                .frame(width: 20, height: 20)
                .foregroundStyle(.indigo)
        } else {
            Circle()
                .frame(width: 20, height: 20)
                .foregroundStyle(.gray.opacity(0.3))
        }
    }
}

enum ReportReason: Int {
    case selectedNotting = -1
    case reportedReason1 = 0
    case reportReason2 = 1
    case other = 2
}

struct FriendDetailView: View {

    @EnvironmentObject var applicationViewModel: ApplicationViewModel
    @EnvironmentObject var appSettingModel: AppSettingModel
    @EnvironmentObject var flowRouter: FlowRouter

    @Environment(\.injected) private var injected: DIContainer

    let friendEmail: String
    @Binding var isPresented: Bool
    let closeSideMenu: () -> ()

    @State private var subscriptions: Set<AnyCancellable> = []
    @State var pairChatroomid = ""
    @State private var dragOffset = CGSize.zero
    @State var isFriend = true
    @State var chatroomType: ChatroomType = .group
    @State var isCopyEmail = false
    @State private(set) var userRelationState: Loadable<OtherUserSearchResponseModel> = .notRequested
    @State var shouldShowRemoveFriendAlertView = false
    @State var shouldShowReportFriendAlertView = false
    @State var shouldShowCompleteReportAlertView = false
    @State var shouldShowFriendProfileFullScreenView = false
    @State var reportDetail = ""
    @State var activeButtonIndex: ReportReason = .selectedNotting

    let buttonDescList = [
        LocalizationString.reportReason_1,
        LocalizationString.reportReason_2,
        LocalizationString.reportReasonOther
    ]

    @State var buttonActiveList = [false, false, false]

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack {
                    WebImage(url: URL(string: "\(serverUrl)/rest/get-background/\(friendEmail)"), options: [.refreshCached])
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
            }

            VStack(alignment: .center, spacing: 40) {
                HStack {
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
                            .shadow(radius: 3)
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
                            .shadow(radius: 3)
                        ZStack {
                            Rectangle()
                                .foregroundColor(.white)
                                .frame(width: 40, height: 50)
                            WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(friendEmail)"), options: [.refreshCached])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 30, height: 30)
                                .border(.black.opacity(0.8), width: 0.7)
                                .offset(y: -5)
                        }
                            .rotationEffect(.degrees(15))
                            .padding(.horizontal)
                            .padding(.top)
                            .padding(.bottom, 20)
                            .shadow(radius: 3)
                    }.onTapGesture { shouldShowFriendProfileFullScreenView = true }
                }.padding()

                Spacer()

                VStack(alignment: .center, spacing: 0) {
                    WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(friendEmail)"), options: [.refreshCached])
                        .resizable()
                        .scaledToFill()
                        .frame(width: 88, height: 88)
                        .clipped()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(30)
                        .shadow(radius: 5)
                    Text(applicationViewModel.getNickname(friendEmail))
                        .font(.system(size: 24))
                    HStack (alignment: .center) {
                        Text(friendEmail)
                            .font(.system(size: 17))
                        Image(systemName: isCopyEmail ? "checkmark" : "doc.on.doc")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 16)
                            .foregroundStyle(.white)
                            .onTapGesture {
                            UIPasteboard.general.string = friendEmail
                            isCopyEmail = true
                        }
                    }
                }.foregroundStyle(.white)

                HStack(alignment: .center, spacing: 73) {
                    switch chatroomType {
                    case .group:
                        if isFriend {
                            VStack(alignment: .center) {
                                Image(systemName: "message.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 27)
                                Text("Chat").font(.system(size: 14))
                            }.onTapGesture {
                                closeSideMenu()
                                if let email: String = UserDefaultsKeys.userEmail.value() {
                                    injected.interactorContainer.chatroomInteractor.startPairChat(
                                        email, friendEmail, applicationViewModel.getNickname(friendEmail),
                                        $pairChatroomid, $applicationViewModel.userChatroomTitles,
                                        $applicationViewModel.userChatrooms, $subscriptions)
                                }
                            }
                            VStack(alignment: .center) {
                                Image(systemName: "person.badge.minus")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 27)
                                Text("Block").font(.system(size: 14))
                            }.onTapGesture { shouldShowRemoveFriendAlertView = true }

                            VStack(alignment: .center) {
                                Image(systemName: "light.beacon.max")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 27)
                                Text("Report").font(.system(size: 14))
                            }.onTapGesture {
                                withAnimation(.spring(duration: 0.3)) {
                                    shouldShowReportFriendAlertView = true
                                }
                            }
                        } else {
                            userSearchResultContent
                            VStack(alignment: .center) {
                                Image(systemName: "light.beacon.max")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 27)
                                Text("Report").font(.system(size: 14))
                            }.onTapGesture {
                                withAnimation(.spring(duration: 0.3)) {
                                    shouldShowReportFriendAlertView = true
                                }
                            }
                        }
                    case .pair:
                        if isFriend {
                            VStack(alignment: .center) {
                                Image(systemName: "person.badge.minus")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 27)
                                Text("Block").font(.system(size: 14))
                            }.onTapGesture { shouldShowRemoveFriendAlertView = true }
                            VStack(alignment: .center) {
                                Image(systemName: "light.beacon.max")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 27)
                                Text("Report").font(.system(size: 14))
                            }.onTapGesture {
                                withAnimation(.spring(duration: 0.3)) {
                                    shouldShowReportFriendAlertView = true
                                }
                            }
                        } else {
                            userSearchResultContent
                        }
                    }
                }
                    .foregroundStyle(.white)
                    .padding(.bottom)
            }
                .safeareaTopPadding()
                .safeareaBottomPadding()
        }
            .background(BackgroundBlurView())
            .fullScreenCover(isPresented: $shouldShowFriendProfileFullScreenView) {
            ZStack {
                FullScreenProfilePhotoView(shouldShowProfileFullScreenView: $shouldShowFriendProfileFullScreenView, targetEmail: friendEmail)
            }.background(TransparentBackgroundView())
        }.onChange(of: pairChatroomid) { _, nextPairChatroomId in
            isPresented = false
            appSettingModel.selectedTab = .mainmessage
            if !flowRouter.navPath.isEmpty { flowRouter.navigateToRoot() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                flowRouter.navigate(to: .chatlogView(nextPairChatroomId))
            }
        }
            .offset(y: dragOffset.height)
            .ignoresSafeArea(.all)
            .background(.clear)
            .alert(isPresented: $shouldShowRemoveFriendAlertView) {
            let no = Alert.Button.cancel(Text("Cancel"))
            let yes = Alert.Button.destructive(Text("Block")) {
                if let email: String = UserDefaultsKeys.userEmail.value() {
                    injected.interactorContainer.notificationInteractor.removeAndBlockFriend(email, friendEmail, $isPresented, $applicationViewModel.userfriends, $applicationViewModel.userChatrooms)
                        .store(in: &subscriptions)
                }
            }
            return Alert(title: Text("Block User"), message: Text("Removing this friend will delete them from your friend list and ignore their future requests.\n Manage deleted friends in the settings."),
                primaryButton: no, secondaryButton: yes)
        }.gesture(DragGesture().onChanged { value in
                if value.translation.height > 0 {
                    dragOffset = value.translation
                }
            }.onEnded { value in
                if value.translation.height > 200 {
                    withAnimation(.linear(duration: 0.3)) {
                        dragOffset.height += UIScreen.main.bounds.height
                    } completion: { isPresented = false }
                } else {
                    withAnimation(.spring(duration: 0.3)) { dragOffset = .zero }
                }
            }
        ).onAppear {
            NotificationCenter.default.post(name: .updatedFriendProfilePhoto, object: nil, userInfo: ["email": friendEmail])

            isFriend = applicationViewModel.userfriends.first(where: { $0.email == friendEmail }) != nil
            if isFriend {
                injected.interactorContainer.userInteractor.checkIsExistUser(
                    email: friendEmail, isFriend: $isFriend, friendlist: $applicationViewModel.userfriends)
                    .store(in: &subscriptions)
            }
            if let email: String = UserDefaultsKeys.userEmail.value() {
                injected.interactorContainer.notificationInteractor.searchOtherUser(
                    searchResult: $userRelationState,
                    email: email,
                    keyword: friendEmail)
            }
        }
            .overlay(shouldShowReportFriendAlertView ? reportFriendAlertView : nil)
            .overlay(shouldShowCompleteReportAlertView ? completeReportAlertView : nil)
    }

    @ViewBuilder
    private var reportFriendAlertView: some View {
        ZStack {
            Color.black.opacity(0.7)
                .onTapGesture {
                withAnimation(.spring(duration: 0.3)) {
                    shouldShowReportFriendAlertView = false
                }
            }

            VStack(alignment: .center, spacing: 0) {
                HStack(alignment: .center) {
                    Text("Please select a reason for reporting")
                        .bold()
                        .font(.system(size: 18))
                }.padding(.vertical)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(buttonDescList.indices, id: \.self) { idx in
                        HStack(alignment: .center) {
                            CheckButton(isChecked: $buttonActiveList[idx])
                            Text(buttonDescList[idx])
                                .font(.system(size: 16))
                        }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 5)
                            .contentShape(Rectangle())
                            .onTapGesture {
                            buttonActiveList = buttonActiveList.map { _ in false }
                            buttonActiveList[idx] = true
                            activeButtonIndex = .init(rawValue: idx) ?? .selectedNotting
                        }
                    }
                }.onAppear {
                    activeButtonIndex = .selectedNotting
                    buttonActiveList = buttonActiveList.map { _ in false }
                    reportDetail = ""
                }

                if activeButtonIndex == .other {
                    VStack(spacing: 0) {
                        HStack(alignment: .bottom) {
                            Spacer()
                            Text("\(reportDetail.count)/50")
                                .font(.system(size: 13))
                        }.padding(.horizontal)
                        TextEditor(text: $reportDetail)
                            .frame(height: 100)
                            .font(.system(size: 17))
                            .padding(.horizontal)
                            .padding(.vertical, 7)
                            .cornerRadius(10)
                            .shadow(radius: 1)
                            .multilineTextAlignment(.leading)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .limitInputLength(value: $reportDetail, length: 50)
                    }.padding().onAppear { reportDetail = "" }
                }
                HStack(alignment: .bottom) {
                    Spacer()
                    Button {
                        if let email: String = UserDefaultsKeys.userEmail.value() {
                            injected.interactorContainer.userInteractor.reportUser(
                                email: email, audience: friendEmail, reason: activeButtonIndex.rawValue, detail: reportDetail)
                                .sink(receiveCompletion: { _ in },
                                receiveValue: { res in
                                    withAnimation(.spring(duration: 0.3)) {
                                        shouldShowReportFriendAlertView = false
                                        shouldShowCompleteReportAlertView = true
                                    }
                                })
                                .store(in: &subscriptions)
                        }
                    } label: {
                        Rectangle()
                            .foregroundStyle(activeButtonIndex == .selectedNotting ? .gray : .blue)
                            .frame(width: 100, height: 40)
                            .cornerRadius(9)
                            .overlay(
                            Text("Submit")
                                .foregroundStyle(.white)
                                .disabled(activeButtonIndex == .selectedNotting)
                        )
                    }
                    Spacer()
                }
            }
                .frame(width: UIScreen.main.bounds.width * 0.8)
                .padding(.vertical)
                .cornerRadius(10.0)
                .background {
                RoundedRectangle(cornerRadius: 10.0)
                    .fill(Color.white)
            }
        }.ignoresSafeArea(.all)
    }

    @ViewBuilder
    private var completeReportAlertView: some View {
        ZStack {
            Color.black.opacity(0.7)
            VStack(alignment: .center, spacing: 15) {
                HStack(alignment: .center) {
                    Text("Your report has been filed.")
                        .font(.system(size: 17.5))
                        .bold()
                }.padding(.top)

                HStack(alignment: .center) {
                    Text(LocalizationString.completeReportUserMessageText)
                        .font(.system(size: 15))
                }.padding()
                HStack(alignment: .center) {
                    Spacer()
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            shouldShowCompleteReportAlertView = false
                        }
                    } label: {
                        Text("Done")
                            .foregroundStyle(.white)
                            .font(.system(size: 16))
                            .padding(.horizontal)
                            .padding(.vertical, 7)
                            .background {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundStyle(.blue)
                        }.contentShape(Rectangle())
                    }
                    Spacer()
                }

            }
                .frame(width: UIScreen.main.bounds.width * 0.7)
                .padding()
                .cornerRadius(10.0)
                .background {
                RoundedRectangle(cornerRadius: 10.0)
                    .fill(Color.white)
            }
        }.ignoresSafeArea(.all)
    }

    @ViewBuilder
    private var userSearchResultContent: some View {
        switch userRelationState {
        case .notRequested:
            Text("")
        case .isLoading(_, _):
            VStack(alignment: .center) {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(2)
                        .tint(.white)
                    Spacer()
                }
            }
        case let .loaded(relationState):
            switch(relationState.requestState) {
            case .wait:
                VStack(alignment: .center) {
                    Image(systemName: "person.crop.circle.badge.clock")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                    Text("waiting...").font(.system(size: 14))
                }
            case .accept:
                VStack(alignment: .center) {
                    Image(systemName: "bell.badge")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 27)
                    Text("Accept your request").font(.system(size: 14))
                }
            case .`init`:
                VStack(alignment: .center) {
                    Image(systemName: "person.fill.badge.plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 27)
                    Text("Add Friend").font(.system(size: 14))
                }.onTapGesture {
                    if let email: String = UserDefaultsKeys.userEmail.value() {
                        injected.interactorContainer.notificationInteractor
                            .sendFriendRequestToSearchedUser(searchResult: $userRelationState, me: email, audience: friendEmail)
                    }
                }
            case .notFound:
                VStack(alignment: .center) {
                    Image(systemName: "person.crop.circle.fill.badge.questionmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 27)
                    Text("user not found").font(.system(size: 14))
                }
            }
        case let .failed(error):
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(error.localizedDescription)
                        .font(.title2)
                        .foregroundStyle(.white)
                    Spacer()
                }
                Spacer()
            }
        }
    }
}
