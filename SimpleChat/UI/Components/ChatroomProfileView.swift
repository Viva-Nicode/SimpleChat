import SwiftUI
import SDWebImageSwiftUI


struct ChatroomProfileView: View {
    var audienceSet: Set<String>
    let chatroomid: String
    let profilePhotoSize: CGFloat
    @State var successToLoadChatroomProfilePhoto = false
    @State var refresh = true

    var body: some View {
        if let me: String = UserDefaultsKeys.userEmail.value() {
            if audienceSet.count >= 3 {
                ZStack {
                    ZStack {
                        Color.white
                        Image(systemName: "person.3")
                            .resizable()
                            .scaledToFit()
                            .padding(.horizontal, 5)
                            .opacity(successToLoadChatroomProfilePhoto ? 0 : 1.0)
                    }
                    if refresh {
                        WebImage(url: URL(string: "chatroomPhoto\(chatroomid)"), options: [.fromCacheOnly])
                            .onSuccess { _, _, _ in
                            NotificationCenter.default.addObserver(forName: .updatedChatroomProfilePhoto, object: nil, queue: .main) { notification in
                                let roomid: String = notification.userInfo!["roomid"] as! String
                                if chatroomid == roomid {
                                    refresh = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { refresh = true }
                                }
                            }
                            successToLoadChatroomProfilePhoto = true }
                            .resizable()
                            .scaledToFill()
                            .frame(width: profilePhotoSize, height: profilePhotoSize)
                            .clipped()
                    }
                }
                    .frame(width: profilePhotoSize, height: profilePhotoSize)
                    .cornerRadius(19)
                    .shadow(radius: 2)
                    .padding(.top, 8)
            } else if audienceSet.count == 2 {
                ZStack {
                    let audienceEmail = audienceSet.filter { $0 != me }.first!
                    WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(audienceEmail)"), options: [.fromCacheOnly])
                        .resizable()
                        .scaledToFill()
                        .frame(width: profilePhotoSize, height: profilePhotoSize)
                        .clipped()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(19)
                        .shadow(radius: 2)
                        .padding(.top, 8)
                        .modifier(RefreshableWebImageProfileModifier(audienceEmail, false))
                        .if(successToLoadChatroomProfilePhoto) { view in
                        view.hidden()
                    }
                    if refresh {
                        WebImage(url: URL(string: "chatroomPhoto\(chatroomid)"), options: [.fromCacheOnly])
                            .onSuccess { _, _, _ in
                            NotificationCenter.default.addObserver(forName: .updatedChatroomProfilePhoto, object: nil, queue: .main) { notification in
                                let roomid: String = notification.userInfo!["roomid"] as! String
                                if chatroomid == roomid {
                                    refresh = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { refresh = true }
                                }
                            }
                            successToLoadChatroomProfilePhoto = true }
                            .resizable()
                            .scaledToFill()
                            .frame(width: profilePhotoSize, height: profilePhotoSize)
                            .clipped()
                            .cornerRadius(19)
                            .shadow(radius: 2)
                            .padding(.top, 8)
                    }
                }
            } else {
                Image(systemName: "person.2.slash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: profilePhotoSize, height: profilePhotoSize)
                    .clipped()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(19)
                    .shadow(radius: 1)
                    .padding(.top, 8)
            }
        }
    }
}
