import SwiftUI
import SDWebImageSwiftUI
import Firebase

struct ChatUser: Identifiable {
    var id: String {uid}
    let email, uid, profile :String
    
    init(data : [String : Any]){
        self.uid = data["uid"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.profile = data["profileImagePath"] as? String ?? ""
    }
}

struct RecentMessage: Identifiable{
    
    var id:String { documentId }
    let documentId: String
    let text, fromId, toId: String
    let email, profileImagePath: String
    let timeStamp: Timestamp
    
    init(documentId: String, data: [String:Any]){
        self.documentId = documentId
        self.text = data["text"] as? String ?? ""
        self.fromId = data["fromId"] as? String ?? ""
        self.toId = data["toId"] as? String ?? ""
        self.profileImagePath = data["profileImagePath"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.timeStamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
    }
}

class MainMessageesViewModel : ObservableObject {
    
    @Published var errorMessage = ""
    // init() -> fetchCurrentUser()에 의해 현재 로그인된 유저의 정보가 삽입됨
    @Published var chatUser:ChatUser?
    @Published var isUserCurrentlyLoggedIn = true
    @Published var recentMessages = [RecentMessage]()
    
    init(){
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedIn = FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        fetchCurrentUser()
        fetchRecentMessages()
    }
    
    private func fetchRecentMessages(){
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener{
                querySnapshot, error in
                if let error = error {
                    print(error)
                    return
                }
                querySnapshot?.documentChanges.forEach({
                    change in
                    let docId = change.document.documentID
                    
                    if let index = self.recentMessages.firstIndex(where: {
                        rm in
                        return rm.documentId == docId
                    }) {
                        self.recentMessages.remove(at: index)
                    }
                    self.recentMessages.insert(.init(documentId: docId, data: change.document.data()), at: 0)
                })
            }
    }
    
    func fetchCurrentUser(){
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument{
            snapshot, error in
            if let error = error {
                print(error)
                return
            }
            guard let data = snapshot?.data() else { return }
            self.chatUser = .init(data : data)
        }
    }
    
    func handleSignOut(){
        isUserCurrentlyLoggedIn.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
}

struct MainMessageView: View {
    
    @State var shouldShowLogOutOptions = false
    @State var shouldShowNewMessageScreen = false
    @ObservedObject private var vm = MainMessageesViewModel()
    // 상대방의 userdata
    @State var chatUser:ChatUser?
    @State var shouldNavigateToChatLogView = false
    
    init(){
        UITabBar.appearance().backgroundColor = UIColor(Color.gray.opacity(0.1))
    }
    
    var body: some View {
        TabView{
            NavigationStack{
                VStack{
                    HStack(spacing:16){
                        WebImage(url: URL(string: vm.chatUser?.profile ?? ""))
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipped()
                            .cornerRadius(50)
                            .shadow(radius: 5)
                        
                        VStack(alignment: .leading, spacing: 4){
                            let email = vm.chatUser?.email.replacingOccurrences(of: "@gmail.com", with: "") ?? "loading..."
                            Text(email).font(.system(size: 24, weight: .bold))
                            HStack{
                                Circle()
                                    .foregroundColor(.green)
                                    .frame(width: 14, height: 14)
                                Text("online")
                                    .font(.system(size:12))
                                    .foregroundColor(Color(.lightGray))
                            }
                        }
                        Spacer()
                        Button{
                            shouldShowLogOutOptions.toggle()
                        }label: {
                            Image(systemName: "gear")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.gray)
                        }
                    }.padding().background(.gray.opacity(0.1))
                        .actionSheet(isPresented: $shouldShowLogOutOptions) {
                            .init(title: Text("Settings"), message: Text("What do you want to do?"), buttons: [
                                .destructive(Text("Sign Out"), action: {
                                    print("handle sign out")
                                    vm.handleSignOut()
                                }),
                                .cancel()
                            ])
                        }.fullScreenCover(isPresented: $vm.isUserCurrentlyLoggedIn, onDismiss: nil){
                            LoginView(didCompleteLoginProcess: {
                                self.vm.isUserCurrentlyLoggedIn = false
                                self.vm.fetchCurrentUser()
                            })
                        }
                    
                    ScrollView{
                        ForEach(vm.recentMessages) {
                            recentMessage in
                            VStack{
                                NavigationLink{
                                    ChatLogView(chatUser:ChatUser(data: ["uid" : recentMessage.toId,
                                                        "email" : recentMessage.email,
                                                        "profileImagePath" : recentMessage.profileImagePath]))
                                } label: {
                                    HStack(spacing:16){
                                        WebImage(url: URL(string: recentMessage.profileImagePath))
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 64, height: 64)
                                            .clipped()
                                            .cornerRadius(64)
                                            .overlay(RoundedRectangle(cornerRadius: 64)
                                                .stroke(.black, lineWidth: 1))
                                            .shadow(radius: 5)
                                        VStack(alignment: .leading, spacing: 8){
                                            Text(recentMessage.email).foregroundColor(.black)
                                                .font(.system(size:16, weight: .bold))
                                            Text(recentMessage.text)
                                                .font(.system(size:14))
                                                .foregroundColor(Color(.lightGray))
                                                .multilineTextAlignment(.leading)
                                        }
                                        Spacer()
                                        Text("22d").font(.system(size:14, weight: .semibold)).foregroundColor(.black)
                                    }
                                }
                            }.padding(.horizontal)
                            Divider().padding(.vertical, 8)
                        }
                    }
                    HStack{
                        Spacer()
                        Button(action: {
                            shouldShowNewMessageScreen.toggle()
                        }) {
                            Image(systemName: "plus.message")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        .frame(width: 90, height: 90)
                        .background(Color.blue)
                        .cornerRadius(30)
                        .padding(.top, -135)
                        .padding(.trailing, 25)
                    }.fullScreenCover(isPresented: $shouldShowNewMessageScreen){
                        NewMessageView(didSelectNewUser: {
                            user in
                            self.chatUser = user
                            self.shouldNavigateToChatLogView.toggle()
                        })
                    }
                }.navigationBarHidden(true).navigationDestination(isPresented: $shouldNavigateToChatLogView){
                    ChatLogView(chatUser: self.chatUser)
                }
            }.tabItem{Label("Home",systemImage: "house.fill")}.tag(0)
        }.accentColor(Color.pink)
    }
}

struct MainMessageView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessageView()
    }
}
