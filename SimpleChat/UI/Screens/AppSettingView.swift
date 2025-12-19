import SwiftUI
import SDWebImageSwiftUI
import PhotosUI
import Combine

enum ActiveSettingViewAlert {
    case signoutAlert
    case accountDeleteFailAlert
    case accountDeleteAlert
}

class AppSettingViewModel: ObservableObject {
    @Published var userNickname = UserDefaultsKeys.userNickname.value() ?? "none"
    @Published var modifyNicknameText = UserDefaultsKeys.userNickname.value() ?? ""
    @Published var userEmail = UserDefaultsKeys.userEmail.value() ?? "..."
    @Published var shouldShowModifyNicknameView = false
    @Published var shouldShowBlackListView = false
    @Published var shouldShowUnblockAlert = false
    @Published var shouldShowPermissionList = false
    @Published var unblockButtonDisabledClosure = { }
    @Published var userToBeUnblocked = ""
    @Published var shouldShowAlert = false
    @Published var passwordTextFieldForDeleteAccount = ""
    @Published var activeAlert: ActiveSettingViewAlert = .signoutAlert
    @Published var shouldShowEnterPWAlert = false
    @Published var locationPermission: PermissionState = .undefined
    @Published var microphonePermission: PermissionState = .undefined
    @Published var photosPermission: PermissionState = .undefined
    @Published var cameraPermission: PermissionState = .undefined

    func refreshAppSettingViewModel() {
        userEmail = UserDefaultsKeys.userEmail.value() ?? "..."
        userNickname = UserDefaultsKeys.userNickname.value() ?? "none"
        modifyNicknameText = UserDefaultsKeys.userNickname.value() ?? ""
        shouldShowModifyNicknameView = false
    }
}

struct AppSettingView: View {

    @State private var subscriptions: Set<AnyCancellable> = []
    @State private(set) var userBlacklist: Loadable<[UserFriend]> = .notRequested
    @EnvironmentObject var appSettingModel: AppSettingModel
    @StateObject var appSettingViewModel = AppSettingViewModel()
    @Environment(\.injected) private var injected: DIContainer

    @State private var records: [String] = []
    @State private var audioPlayer: AVAudioPlayer?

    var body: some View {
        ZStack {
            GeometryReader { geo in
                VStack(alignment: .center) {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(
                            appSettingModel.appTheme ? "Gradation background start" : "Gradation background start dark"),
                            Color(appSettingModel.appTheme ? "Gradation background end" : "Gradation background end dark")]),
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }.ignoresSafeArea(.all)

            GeometryReader { geo in
                VStack(alignment: .center) {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(appSettingModel.appTheme ? "Gradation orange start light" : "Gradation background start dark2"),
                            Color(appSettingModel.appTheme ? "Gradation orange end light" : "Gradation background end dark2")]),
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
                    Text("Settings")
                        .font(.title)
                        .frame(alignment: .leading)
                        .appThemeForegroundColor(appSettingModel.appTheme)
                    Spacer()
                }.frame(height: 30).padding()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        HStack(alignment: .center) {
                            Text("nickname")
                                .appThemeForegroundColor(appSettingModel.appTheme)
                            Spacer()
                            HStack (alignment: .center, spacing: 2) {
                                Text(appSettingViewModel.userNickname)
                                    .font(.system(size: 20))
                                    .foregroundStyle(appSettingModel.appTheme ? .blue : .orange)
                                Image(systemName: "pencil.circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(appSettingModel.appTheme ? .blue : .orange)
                            }.onTapGesture {
                                withAnimation(.spring(duration: 0.3)) {
                                    appSettingViewModel.shouldShowModifyNicknameView = true
                                }
                            }
                        }.padding()

                        Divider().background(appSettingModel.appTheme ? Color.gray.opacity(0.3) : Color.white.opacity(0.4))

                        HStack(alignment: .center) {
                            Text("theme")
                                .appThemeForegroundColor(appSettingModel.appTheme)
                            Spacer()
                            Toggle("", isOn: $appSettingModel.appTheme)
                                .toggleStyle(CustomToggleStyle())
                                .onChange(of: appSettingModel.appTheme) { _, nv in
                                UserDefaultsKeys.appTheme.setValue(nv)
                            }
                        }.padding()

                        Divider().background(appSettingModel.appTheme ? Color.gray.opacity(0.3) : Color.white.opacity(0.4))

                        Button(action: {
                            appSettingViewModel.shouldShowBlackListView = true
                        }) {
                            HStack(alignment: .center) {
                                Text("blocked user manage")
                                    .foregroundStyle(appSettingModel.appTheme ? .blue : .orange)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(appSettingModel.appTheme ? .blue : .orange)
                            }.padding()
                        }

                        Divider().background(appSettingModel.appTheme ? Color.gray.opacity(0.3) : Color.white.opacity(0.4))

                        Button {
                            withAnimation(.interactiveSpring(duration: 0.3)) {
                                appSettingViewModel.cameraPermission = Permissions.checkCameraAuthorizationStatus()
                                appSettingViewModel.microphonePermission = Permissions.checkAudioAuthorizationStatus()
                                appSettingViewModel.locationPermission = Permissions.checkLocationAuthorizationStatus()
                                appSettingViewModel.photosPermission = Permissions.checkPhotosAuthorizationStatus()
                                appSettingViewModel.shouldShowPermissionList.toggle()
                            }
                        } label: {
                            HStack(alignment: .center) {
                                Text("permission")
                                    .foregroundStyle(appSettingModel.appTheme ? .blue : .orange)
                                Spacer()
                                Image(systemName: appSettingViewModel.shouldShowPermissionList ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(appSettingModel.appTheme ? .blue : .orange)
                            }.padding()
                        }

                        if appSettingViewModel.shouldShowPermissionList {
                            VStack(spacing: 6) {
                                Button {
                                    if appSettingViewModel.cameraPermission == .denied {
                                        if let url = URL(string: UIApplication.openSettingsURLString) {
                                            if #available(iOS 10.0, *) {
                                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                            } else {
                                                UIApplication.shared.openURL(url)
                                            }
                                        }
                                    } else {
                                        Permissions.requestCameraPermission() {
                                            appSettingViewModel.cameraPermission = Permissions.checkCameraAuthorizationStatus()
                                        }
                                    }
                                } label: {
                                    HStack(alignment: .center) {
                                        Image(systemName: "camera.circle")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 25)
                                            .foregroundStyle(appSettingViewModel.cameraPermission == .allowed ? .green : .red)
                                        Text("camera")
                                            .foregroundStyle(appSettingViewModel.cameraPermission == .allowed ? .green : .red)
                                        Spacer()
                                        ZStack {
                                            switch appSettingViewModel.cameraPermission {
                                            case .allowed:
                                                Image(systemName: "checkmark")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: 15)
                                                    .foregroundStyle(.green)
                                            case .denied, .notDetermined:
                                                Image(systemName: "xmark")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: 15)
                                                    .foregroundStyle(.red)
                                            case .undefined:
                                                Image(systemName: "questionmark.app")
                                            }
                                        }
                                    }.padding()
                                }.disabled(appSettingViewModel.cameraPermission == .allowed)

                                Button {
                                    if appSettingViewModel.microphonePermission == .denied {
                                        if let url = URL(string: UIApplication.openSettingsURLString) {
                                            if #available(iOS 10.0, *) {
                                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                            } else {
                                                UIApplication.shared.openURL(url)
                                            }
                                        }
                                    } else {
                                        Permissions.requestMicrophonePermission() {
                                            appSettingViewModel.microphonePermission = Permissions.checkAudioAuthorizationStatus()
                                        }
                                    }
                                } label: {
                                    HStack(alignment: .center) {
                                        Image(systemName: "mic.circle")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 25)
                                            .foregroundStyle(appSettingViewModel.microphonePermission == .allowed ? .green : .red)
                                        Text("microphone")
                                            .foregroundStyle(appSettingViewModel.microphonePermission == .allowed ? .green : .red)
                                        Spacer()
                                        ZStack {
                                            switch appSettingViewModel.microphonePermission {
                                            case .allowed:
                                                Image(systemName: "checkmark")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: 15)
                                                    .foregroundStyle(.green)
                                            case .denied, .notDetermined:
                                                Image(systemName: "xmark")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: 15)
                                                    .foregroundStyle(.red)
                                            case .undefined:
                                                Image(systemName: "questionmark.app")
                                            }
                                        }
                                    }.padding()
                                }.disabled(appSettingViewModel.microphonePermission == .allowed)

                                Button {
                                    if appSettingViewModel.photosPermission == .denied {
                                        if let url = URL(string: UIApplication.openSettingsURLString) {
                                            if #available(iOS 10.0, *) {
                                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                            } else {
                                                UIApplication.shared.openURL(url)
                                            }
                                        }
                                    } else {
                                        Permissions.requestPHPhotoLibraryAuthorization {
                                            appSettingViewModel.photosPermission = Permissions.checkPhotosAuthorizationStatus()
                                        }
                                    }
                                } label: {
                                    HStack(alignment: .center) {
                                        Image(systemName: "photo.artframe.circle")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 25)
                                            .foregroundStyle(appSettingViewModel.photosPermission == .allowed ? .green : .red)
                                        Text("photo")
                                            .foregroundStyle(appSettingViewModel.photosPermission == .allowed ? .green : .red)
                                        Spacer()
                                        ZStack {
                                            switch appSettingViewModel.photosPermission {
                                            case .allowed:
                                                Image(systemName: "checkmark")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: 15)
                                                    .foregroundStyle(.green)
                                            case .denied, .notDetermined:
                                                Image(systemName: "xmark")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: 15)
                                                    .foregroundStyle(.red)
                                            case .undefined:
                                                Image(systemName: "questionmark.app")
                                            }
                                        }
                                    }.padding()
                                }.disabled(appSettingViewModel.photosPermission == .allowed)
                            }
                        }

                        Divider().background(appSettingModel.appTheme ? Color.gray.opacity(0.3) : Color.white.opacity(0.4))

                        Button {
                            appSettingViewModel.activeAlert = .signoutAlert
                            appSettingViewModel.shouldShowAlert = true
                        } label: {
                            HStack(alignment: .center) {
                                Text("sign out")
                                    .foregroundStyle(appSettingModel.appTheme ? .blue : .orange)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(appSettingModel.appTheme ? .blue : .orange)
                            }.padding()
                        }

                        Divider().background(appSettingModel.appTheme ? Color.gray.opacity(0.3) : Color.white.opacity(0.4))

                        Button {
                            appSettingViewModel.activeAlert = .accountDeleteAlert
                            appSettingViewModel.shouldShowAlert = true
                        } label: {
                            HStack(alignment: .center) {
                                Text("delete account")
                                    .foregroundStyle(.red)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.red)
                            }.padding()
                        }
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
                Spacer()
            }
                .padding()
                .onAppear { appSettingViewModel.refreshAppSettingViewModel() }
        }
            .toolbar(appSettingViewModel.shouldShowModifyNicknameView ? .hidden : .visible, for: .tabBar)
            .overlay { appSettingViewModel.shouldShowModifyNicknameView ? modifyNickname : nil }
            .background(appSettingModel.appTheme ? Color.white : Color("pastel gray foreground"))
            .fullScreenCover(isPresented: $appSettingViewModel.shouldShowBlackListView) { blacklistView }
            .alert(isPresented: $appSettingViewModel.shouldShowAlert) {
            switch appSettingViewModel.activeAlert {
            case .signoutAlert:
                let yes = Alert.Button.destructive(Text("sign out")) {
                    if let email: String = UserDefaultsKeys.userEmail.value() {
                        injected.interactorContainer.userInteractor.signout(email: email, tab: $appSettingModel.selectedTab)
                            .store(in: &subscriptions)
                    }
                }
                let no = Alert.Button.cancel(Text("cancel"))
                return Alert(title: Text("Sign Out"), message: Text("Are you sure you want to sign out to this device?"),
                    primaryButton: no, secondaryButton: yes)

            case .accountDeleteAlert:
                let yes = Alert.Button.destructive(Text("delete")) {
                    appSettingViewModel.passwordTextFieldForDeleteAccount = ""
                    appSettingViewModel.shouldShowEnterPWAlert = true
                }
                let no = Alert.Button.cancel(Text("cancel"))
                return Alert(title: Text("Account Delete"),
                    message: Text("Are you sure you want to delete this account?\nAll data from the user will be deleted, and the account will no longer be available.\nThis action cannot be undone."),
                    primaryButton: no, secondaryButton: yes)

            case .accountDeleteFailAlert:
                return Alert(title: Text("delete account fail"), message: Text("passwrod mismatch"))

            }
        }.alert("Enter your Password", isPresented: $appSettingViewModel.shouldShowEnterPWAlert) {
            SecureField("password", text: $appSettingViewModel.passwordTextFieldForDeleteAccount)
            HStack {
                Button("cancel", action: { appSettingViewModel.shouldShowEnterPWAlert = false })
                Button("OK", action: deleteAccount)
            }
        }
    }

    @ViewBuilder
    private var modifyNickname: some View {
        ZStack {
            Color.black.opacity(0.7)
                .onTapGesture {
                withAnimation(.spring(duration: 0.3)) {
                    appSettingViewModel.shouldShowModifyNicknameView = false
                }
            }
            VStack(alignment: .center, spacing: 30) {
                HStack(alignment: .center) {
                    Text("Change nickname")
                        .font(.system(size: 17.5))
                        .bold()
                    Spacer()
                }
                VStack(spacing: 2) {
                    HStack {
                        Spacer()
                        Text("\(appSettingViewModel.modifyNicknameText.count)/16").font(.system(size: 13))
                    }
                    TextField(appSettingViewModel.userNickname, text: $appSettingViewModel.modifyNicknameText)
                        .font(.system(size: 20))
                        .padding(.horizontal)
                        .padding(.vertical, 7)
                        .cornerRadius(10)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .lineLimit(1)
                        .limitInputLength(value: $appSettingViewModel.modifyNicknameText, length: 16)
                        .onAppear { appSettingViewModel.modifyNicknameText = appSettingViewModel.userNickname }
                        .background {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(.white)
                            .shadow(radius: 1)
                    }
                }.padding(0)
                Button(action: {
                    if let email: String = UserDefaultsKeys.userEmail.value() {
                        injected.interactorContainer.userInteractor.changeNickname(
                            email: email, nickname: appSettingViewModel.modifyNicknameText.trimmingCharacters(in: .whitespacesAndNewlines),
                            viewModelNickname: $appSettingViewModel.userNickname,
                            shouldShowModifyNicknameView: $appSettingViewModel.shouldShowModifyNicknameView)
                            .store(in: &subscriptions)
                    }
                }) {
                    Text("change")
                        .foregroundStyle(.white)
                        .font(.system(size: 15))
                        .padding(.horizontal)
                        .padding(.vertical, 5)
                        .background { Rectangle().cornerRadius(7) }
                }.disabled(appSettingViewModel.modifyNicknameText == appSettingViewModel.userNickname ||
                        appSettingViewModel.modifyNicknameText == "" ||
                        !validateNickname(appSettingViewModel.modifyNicknameText))
            }
                .frame(width: UIScreen.main.bounds.width * 0.6)
                .padding()
                .cornerRadius(10.0)
                .background {
                RoundedRectangle(cornerRadius: 10.0)
                    .fill(Color.white)
            }
        }.ignoresSafeArea(.all)

    }

    @ViewBuilder
    private var blacklistView: some View {
        VStack {
            HStack(alignment: .center) {
                Button(action: {
                    appSettingViewModel.shouldShowBlackListView = false
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
                Text("Blacklist")
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
            userBlacklistContent
        }.onAppear {
            if let email: String = UserDefaultsKeys.userEmail.value() {
                injected.interactorContainer.notificationInteractor.getBlackList(email, $userBlacklist)
            }
        }.background {
            if appSettingModel.appTheme {
                BackgroundBlurView().ignoresSafeArea(.all)
            } else {
                BackgroundDarkBlurView().ignoresSafeArea(.all)
            }
        }.alert(isPresented: $appSettingViewModel.shouldShowUnblockAlert) {
            let yes = Alert.Button.default(Text("Unblock")) {
                if let email: String = UserDefaultsKeys.userEmail.value() {
                    injected.interactorContainer.notificationInteractor.unblockFriend(email, appSettingViewModel.userToBeUnblocked, appSettingViewModel.unblockButtonDisabledClosure)
                        .store(in: &subscriptions)
                }
            }
            let no = Alert.Button.cancel(Text("Cancel"))
            return Alert(title: Text("Unblock Friend"), message: Text("Are you sure you want to unblock this friend?"),
                primaryButton: no, secondaryButton: yes)
        }
    }

    private func playAudioFile(named fileName: String) {
        let voiceRecordsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("VoiceRecords")
        let fileURL = voiceRecordsDirectory.appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("파일이 존재하지 않습니다: \(fileURL.path)")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            print("재생 시작: \(fileName)")
        } catch {
            print("오디오 재생 중 오류 발생: \(error.localizedDescription)")
        }
    }

    private func deleteAccount() {
        if let email: String = UserDefaultsKeys.userEmail.value() {
            injected.interactorContainer.userInteractor.deleteAccount(email: email,
                password: appSettingViewModel.passwordTextFieldForDeleteAccount)
                .sink(receiveCompletion: { _ in },
                receiveValue: { res in
                    if res.code == .success {
                        UserDefaultsKeys.userEmail.setValue(UserDefaultsKeys.nilValue)
                        UserDefaultsKeys.userNickname.setValue(UserDefaultsKeys.nilValue)
                        appSettingModel.selectedTab = .home
                    } else {
                        appSettingViewModel.activeAlert = .accountDeleteFailAlert
                        appSettingViewModel.shouldShowAlert = true
                    }
                }).store(in: &subscriptions)
        }
    }

    private var statusBarHeight: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return 0 }
        return windowScene.statusBarManager?.statusBarFrame.height ?? 0
    }

    private func validateNickname(_ input: String) -> Bool {
        let pattern = "^[0-9a-zA-Z가-힣]*$"
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: input.utf16.count)
        let match = regex.firstMatch(in: input, options: [], range: range)
        return match != nil
    }

    @ViewBuilder
    private var userBlacklistContent: some View {
        switch userBlacklist {
        case .notRequested:
            Text("")
        case .isLoading(_, _):
            VStack(alignment: .center) {
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
        case let .loaded(blacklist):
            if blacklist.isEmpty {
                VStack(alignment: .center) {
                    Spacer()
                    Image(systemName: "book.pages")
                        .resizable()
                        .foregroundColor(appSettingModel.appTheme ? .black.opacity(0.2) : .white.opacity(0.3))
                        .frame(width: 60, height: 60)
                    Text("Empty BlackList")
                        .foregroundColor(appSettingModel.appTheme ? .black.opacity(0.2) : .white.opacity(0.3))
                        .font(.title)
                    Spacer()
                }
            } else {
                VStack {
                    ScrollView {
                        ForEach(blacklist, id: \.self) { friend in
                            BlockedUserRow(shouldShowUnblockAlert: $appSettingViewModel.shouldShowUnblockAlert,
                                unblockButtonDisabledClosure: $appSettingViewModel.unblockButtonDisabledClosure,
                                userToBeUnblocked: $appSettingViewModel.userToBeUnblocked, friend: friend)
                        }
                    }.padding(10)
                    Spacer()
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

struct BlockedUserRow: View {
    @State var isUnblocked = false
    @Binding var shouldShowUnblockAlert: Bool
    @Binding var unblockButtonDisabledClosure: () -> ()
    @Binding var userToBeUnblocked: String
    @EnvironmentObject var appSettingModel: AppSettingModel
    let friend: UserFriend

    var body: some View {
        HStack(alignment: .center) {
            WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(friend.email)"))
                .resizable()
                .scaledToFill()
                .frame(width: 37, height: 37)
                .clipped()
                .cornerRadius(9)
            Text(friend.email)
                .appThemeForegroundColor(appSettingModel.appTheme)
                .font(.system(size: 15))
            Spacer()
            Button(action: {
                shouldShowUnblockAlert = true
                userToBeUnblocked = friend.email
                unblockButtonDisabledClosure = { isUnblocked = true }
            }) {
                Text(isUnblocked ? "unblocked" : "unblock")
                    .foregroundStyle(.white)
            }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .disabled(isUnblocked)
        }.padding(.vertical)
    }
}
