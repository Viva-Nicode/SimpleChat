//
//  ChatLogView.swift
//  SimpleChat
//
//  Created by Nicode . on 2023/07/19.
//

import SwiftUI
import Firebase
import Alamofire
import FirebaseMessaging
import OAuth2

struct ChatMessage: Identifiable{
    var id: String{documentId}
    
    let fromId, toId, text: String
    let documentId: String
    
    init(documentId:String, data:[String : Any]){
        self.documentId = documentId
        self.fromId = data["fromId"] as? String ?? ""
        self.toId = data["toId"] as? String ?? ""
        self.text = data["text"] as? String ?? ""
    }
}

class ChatLogViewModel: ObservableObject{
    
    @Published var chatText = ""
    @Published var chatMessages = [ChatMessage]()
    @Published var count = 0
    //나랑 대화할 유저 정보
    let chatUser:ChatUser?
    
    init(chatUser:ChatUser?){
        self.chatUser = chatUser
        fetchMessages()
    }

    func sendNotification() {
        
        let body = [
            "message": [
                "token": "fapiTZveCEhMotirSdceRr:APA91bFvj6VaRoH8ytU2rnxg7Ad-lgp-pK4JG73Jk4N89-INt36MOnj4bFVSyD6cCSAZQsEldiknVi-2d7jnwTwHOeOJ4s-kq-t6jV32AWsuedaDLy9LqONEVrEGZPTvy1TL4M68loZe",
                "notification": [
                    "title": "Portugal vs. Denmark",
                    "body": "great match!"
                ]
            ]
        ]
        
        AF.request("https://fcm.googleapis.com/v1/simplechat-acfbb/messages:send",
                   method: .post,
                   parameters: body,
                   headers: ["Content-Type":"application/json"])
            .responseDecodable(of: [String].self) {
                response in
            switch response.result {
            case .success:
                print(response.result)
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    private func persistRecentMessage(){
        guard let chatUser = chatUser else { return }
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = self.chatUser?.uid else { return }
        
        let document = FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .document(toId)
        
        let data = ["timestamp" : Timestamp(),
                    "text" : self.chatText,
                    "fromId" : uid,
                    "toId" : toId,
                    "profileImagePath" : chatUser.profile,
                    "email" : chatUser.email
        ] as [String:Any]
        
        document.setData(data){
            error in
            if let error = error{
                print(error)
            }
            
            FirebaseManager.shared.firestore.collection("users").document(uid).getDocument{
                snapshot, error in
                if let error = error {
                    print(error)
                    return
                }
                let cuserData = snapshot?.data()
                var otherData = data
                otherData["fromId"] = data["toId"]
                otherData["toId"] = data["fromId"]
                
                otherData["email"] = cuserData?["email"] as? String ?? ""
                otherData["profileImagePath"] = cuserData?["profileImagePath"] as? String ?? ""
                
                FirebaseManager.shared.firestore
                    .collection("recent_messages")
                    .document(toId)
                    .collection("messages")
                    .document(uid).setData(otherData, merge: true)
            }
        }
    }
    
    private func fetchMessages(){
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        
        FirebaseManager.shared.firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .order(by: "timeStamp")
            .addSnapshotListener{
                querySnapshot, error in
                if let error = error {
                    print(error)
                    return
                }
                querySnapshot?.documentChanges.forEach({
                    change in
                    if change.type == .added {
                        let data = change.document.data()
                        self.chatMessages.append(.init(documentId: change.document.documentID, data: data))
                    }
                })
                DispatchQueue.main.async {
                    self.count += 1
                }
            }
    }
    
    func sendMessage(){
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        
        let document = FirebaseManager.shared.firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .document()
        
        let messageData = ["fromId" : fromId, "toId" : toId, "text" : self.chatText, "timeStamp" : Timestamp()] as [String : Any]
        
        document.setData(messageData){
            error in
            if let error = error {
                print(error)
            }
            self.chatText = ""
            self.count += 1
        }
        
        let recipientMessageDocument = FirebaseManager.shared.firestore.collection("messages")
            .document(toId)
            .collection(fromId)
            .document()
        
        recipientMessageDocument.setData(messageData){
            error in
            if let error = error {
                print(error)
            }
        }
        persistRecentMessage()
        sendNotification()
    }
}

struct ChatLogView: View{
    
    // 나랑 대화할 대상유저의 정보가 들어간다.
    let chatUser:ChatUser?
    @ObservedObject var vm: ChatLogViewModel
    
    init(chatUser:ChatUser?){
        self.chatUser = chatUser
        self.vm = .init(chatUser:chatUser)
    }
    
    var body : some View{
        VStack{
            messageView
            chatBottomBar
        }
        .navigationTitle(self.chatUser?.email ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var messageView: some View{
        ScrollView{
            ScrollViewReader{ scrollViewProxy in
                VStack{
                    ForEach(vm.chatMessages){
                        message in
                        MessageView(message: message)
                    }
                    HStack{Spacer()}.id("Empty")
                }.onReceive(vm.$count) { _ in
                    withAnimation(.easeOut(duration: 0.5)){
                        scrollViewProxy.scrollTo("Empty", anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var chatBottomBar: some View{
        HStack(spacing:16){
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 24))
            TextField("message", text:$vm.chatText, axis: .vertical)
                .multilineTextAlignment(.leading)
            Button{
                vm.sendMessage()
            }label: {
                Text("Send").foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.blue)
            .cornerRadius(8)
        }
        .padding(.horizontal)
        .padding(.vertical,8)
    }
}

struct MessageView: View{
    let message: ChatMessage
    var body: some View{
        VStack{
            if message.fromId == FirebaseManager.shared.auth.currentUser?.uid{
                HStack{
                    Spacer()
                    HStack{
                        Text(message.text).foregroundColor(.white)
                    }.padding()
                        .background(.blue)
                        .cornerRadius(8)
                    
                }
            }else{
                HStack{
                    
                    HStack{
                        Text(message.text).foregroundColor(.black)
                    }.padding()
                        .background(.white)
                        .cornerRadius(8)
                    Spacer()
                }
            }
        }.padding(.horizontal)
            .padding(.top, 8)
    }
}
