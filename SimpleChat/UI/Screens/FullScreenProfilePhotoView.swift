import SwiftUI
import Combine
import SDWebImageSwiftUI

struct FullScreenProfilePhotoView: View {
    @Binding var shouldShowProfileFullScreenView: Bool
    let targetEmail: String

    @EnvironmentObject var appSettingModel: AppSettingModel
    @Environment(\.injected) private var injected: DIContainer

    @State private var photoScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = .zero
    @State private var currentPhotoIndex: Int? = 0
    @State private var selfOffset: CGFloat = .zero

    @State private var subscriptions: Set<AnyCancellable> = []
    @State private var shouldShowRemoveProfileAlert = false

    @State private var userProfileHistory: [UserProfileModel]?

    var body: some View {
        ZStack {
            BackgroundBlurView()
            if let userProfileHistory {
                if userProfileHistory.isEmpty {
                    VStack(alignment: .center, spacing: 15) {
                        Spacer()
                        Image(systemName: "square.3.layers.3d.down.right.slash")
                            .resizable()
                            .foregroundColor(appSettingModel.appTheme ? .black.opacity(0.2) : .white.opacity(0.3))
                            .frame(width: 60, height: 60)
                        Text("Empty Photo Historys")
                            .foregroundColor(appSettingModel.appTheme ? .black.opacity(0.2) : .white.opacity(0.3))
                            .font(.title)
                        Spacer()
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(userProfileHistory.indices, id: \.self) { idx in
                                ScrollView([.vertical, .horizontal], showsIndicators: false) {
                                    WebImage(url: URL(string: "\(serverUrl)/rest/get-prev-profile/\(userProfileHistory[idx].profileType.rawValue)/\(userProfileHistory[idx].imageName)"),
                                        options: [.fromLoaderOnly])
                                        .resizable()
                                        .cornerRadius(10)
                                        .padding(10)
                                        .scaledToFit()
                                        .frame(width: (screenWidth - 20) * photoScale)
                                        .highPriorityGesture(MagnifyGesture(minimumScaleDelta: .zero)
                                            .onChanged { value in
                                            if value.magnification > 1 {
                                                photoScale = min(4.8, (lastScale == .zero ? .zero : lastScale - 1) + value.magnification)
                                            } else {
                                                photoScale = max(0.7, lastScale * value.magnification)
                                            }
                                        }.onEnded { _ in
                                            withAnimation(.spring(duration: 0.3)) {
                                                if photoScale < 1.0 {
                                                    photoScale = 1.0
                                                } else if photoScale > 4 {
                                                    photoScale = 4
                                                }
                                            }
                                            lastScale = photoScale
                                        }.simultaneously(with: TapGesture(count: 2).onEnded {
                                                withAnimation(.spring(duration: 0.2)) {
                                                    photoScale = 1.0
                                                    lastScale = .zero
                                                }
                                            }
                                        )
                                    )
                                }
                                    .scrollDisabled(photoScale == 1.0)
                                    .frame(width: screenWidth, height: screenHeight + 15)
                                    .clipped()
                                    .scrollTransition { content, phase in
                                    content.opacity(phase.isIdentity ? 1.0 : 0.0)
                                        .scaleEffect(x: phase.isIdentity ? 1.0 : 0.3, y: phase.isIdentity ? 1.0 : 0.3)
                                        .offset(y: phase.isIdentity ? 0 : 50)
                                }
                            }
                        }.scrollTargetLayout()
                    }
                        .contentMargins(0, for: .scrollContent)
                        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                        .scrollPosition(id: $currentPhotoIndex)
                        .scrollDisabled(photoScale != 1.0)
                }
            } else {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        LoadingDonutView(width: screenWidth * 0.15)
                        Spacer()
                    }
                    Spacer()
                }.onAppear {
                    injected.interactorContainer.userInteractor.getUserProfileList(email: targetEmail, userProfileList: $userProfileHistory)
                        .store(in: &subscriptions)
                }
            }
            VStack {
                Spacer()
                HStack(alignment: .center, spacing: 8) {
                    Spacer()
                    if let email: String = UserDefaultsKeys.userEmail.value() {
                        if !(userProfileHistory?.isEmpty ?? true) && email == targetEmail {
                            ZStack {
                                Image(systemName: "trash")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20)
                                    .foregroundStyle(.red.opacity(0.6))
                                    .padding()
                            }
                                .background(Circle().foregroundStyle(.white).shadow(radius: 3))
                                .contentShape(Circle())
                                .onTapGesture { shouldShowRemoveProfileAlert = true }
                        }
                        if !(userProfileHistory?.isEmpty ?? true) {
                            if let currentPhotoIndex {
                                VStack(alignment: .leading) {
                                    if 0..<userProfileHistory!.count ~= currentPhotoIndex {
                                        if userProfileHistory![currentPhotoIndex].isCurrentUsing {
                                            switch userProfileHistory![currentPhotoIndex].profileType {
                                            case .profile:
                                                HStack(spacing: 4) {
                                                    Text("current profile")
                                                        .font(.system(size: 13))
                                                        .foregroundStyle(.black)
                                                    Image(systemName: "checkmark.circle")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(height: 13)
                                                        .foregroundStyle(.green)
                                                }
                                            case .background:
                                                HStack(spacing: 4) {
                                                    Text("current background")
                                                        .font(.system(size: 13))
                                                        .foregroundStyle(.black)
                                                    Image(systemName: "checkmark.circle")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(height: 13)
                                                        .foregroundStyle(.green)
                                                }
                                            default:
                                                EmptyView()
                                            }
                                        }
                                        Text("\(userProfileHistory![currentPhotoIndex].timestamp.showableTimestamp()) ago")
                                            .font(.system(size: 13))
                                            .foregroundStyle(.black)
                                    }
                                }
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 8).foregroundStyle(.white).shadow(radius: 3))
                            }
                        }
                    }
                    Spacer()
                }.safeareaBottomPadding()
            }.safeareaBottomPadding()
        }
            .offset(y: selfOffset)
            .ignoresSafeArea(.all)
            .alert(isPresented: $shouldShowRemoveProfileAlert) {
            if let profileList = userProfileHistory, let currentPhotoIndex {
                let no = Alert.Button.cancel(Text("cancel"))
                let yes = Alert.Button.destructive(Text("remove")) {
                    if let me: String = UserDefaultsKeys.userEmail.value() {
                        injected.interactorContainer.userInteractor.removeProfile(
                            email: me, targetPhoto: profileList[currentPhotoIndex]) {
                            if currentPhotoIndex == profileList.count - 1 {
                                userProfileHistory?.remove(at: currentPhotoIndex)
                                self.currentPhotoIndex = currentPhotoIndex - 1
                            } else {
                                userProfileHistory?.remove(at: currentPhotoIndex)
                            }
                        }.store(in: &subscriptions)
                    }
                }
                if profileList[currentPhotoIndex].isCurrentUsing {
                    switch profileList[currentPhotoIndex].profileType {
                    case .background:
                        return Alert(title: Text("Remove Profile"), message: Text("Are you sure you want to remove this photo?\nYour background photo will change to default."), primaryButton: no, secondaryButton: yes)
                    case .profile:
                        return Alert(title: Text("Remove Profile"), message: Text("Are you sure you want to remove this photo?\nYour profile photo will change to default."), primaryButton: no, secondaryButton: yes)
                    default:
                        return Alert(title: Text("sorry"), message: Text("Please try again in a moment."))
                    }
                } else {
                    return Alert(title: Text("Remove Profile"), message: Text("Are you sure you want to remove this photo?"),
                        primaryButton: no, secondaryButton: yes)
                }
            } else {
                return Alert(title: Text("sorry"), message: Text("Please try again in a moment."))
            }
        }.simultaneousGesture(photoScale != 1.0 ? nil:
                DragGesture(minimumDistance: 30, coordinateSpace: .global)
                .onChanged { value in
                if value.translation.height > 0 {
                    selfOffset = value.translation.height - 30
                }
            }.onEnded { v in
                if v.translation.height - 30 > 200 {
                    withAnimation(.linear(duration: 0.3)) {
                        selfOffset += UIScreen.main.bounds.height
                    } completion: { shouldShowProfileFullScreenView = false }
                } else {
                    withAnimation(.spring(duration: 0.3)) {
                        selfOffset = .zero
                    }
                }
            }
        )
    }
}
