//
//  NewMessageView.swift
//  SimpleChat
//
//  Created by Nicode . on 2023/07/18.
//

import SwiftUI
import SDWebImageSwiftUI

class NewMessageViewModel: ObservableObject{
    
    @Published var users = [ChatUser]()
    @Published var errorMessage = ""
    init(){
        fetchAllUsers()
    }
    
    private func fetchAllUsers(){
        FirebaseManager.shared.firestore.collection("users").getDocuments{
            documentssnapshot, error in
            if let error = error {
                self.errorMessage = "fail fetch user : \(error)"
                return
            }
            documentssnapshot?.documents.forEach{
                snapshot in
                let data = snapshot.data()
                let user = ChatUser(data : data)
                if user.uid != FirebaseManager.shared.auth.currentUser?.uid {
                    self.users.append(.init(data : data))
                }
            }
            self.errorMessage = "user fetch Successfully"
        }
    }
}

struct NewMessageView: View {
    
    let didSelectNewUser: (ChatUser) -> ()
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var vm = NewMessageViewModel()
    
    var body: some View {
        NavigationView{
            ScrollView{
                ForEach(vm.users) {
                    user in
                    Button{
                        presentationMode.wrappedValue.dismiss()
                        didSelectNewUser(user)
                    }label: {
                        HStack(spacing:16){
                            WebImage(url: URL(string: user.profile))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipped()
                                .cornerRadius(50)
                                .shadow(radius: 5)
                            Text(user.email).foregroundColor(Color(.label))
                            Spacer()
                        }.padding(.horizontal)
                    }
                    Divider().padding(.vertical,8)
                }.navigationTitle("New Message")
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarLeading){
                            Button{
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                Image(systemName: "chevron.backward").font(.system(size: 22))
                            }
                        }
                    }
            }
        }
    }
}

struct NewMessageView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessageView()
    }
}
