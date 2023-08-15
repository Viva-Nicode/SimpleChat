
import SwiftUI
import FirebaseStorage

struct LoginView: View {
    
    let didCompleteLoginProcess: () -> ()
    
    @State private var isLoginMode = false
    @State private var signupResult = false
    @State private var email = ""
    @State private var password = ""
    @State private var shouldShowImagePicker = false
    @State private var image: UIImage?
    
    var body: some View {
        NavigationView{
            ScrollView{
                VStack(spacing : 20){
                    Picker(selection:$isLoginMode, label: Text("picker here")){
                        Text("log in").tag(true)
                        Text("sign up").tag(false)
                    }.pickerStyle(SegmentedPickerStyle()).padding()
                    
                    if !isLoginMode{
                        Button(action : {
                            shouldShowImagePicker.toggle()
                        }){
                            VStack{
                                if let image = self.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .frame(width: 128, height: 128)
                                        .scaledToFill()
                                        .cornerRadius(64)
                                }else{
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 67))
                                        .padding()
                                    Text("Add Profile Image")
                                        .fontDesign(.rounded)
                                        .font(.system(size:23))
                                }
                            }
                        }
                    }
                    
                    Group{
                        TextField("Email", text : $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .textFieldStyle(.roundedBorder)
                            .padding(.leading, 30)
                            .padding(.trailing, 30)
                            .font(.system(size:22))
                        
                        SecureField("Password", text : $password)
                            .textFieldStyle(.roundedBorder)
                            .padding(.leading, 30)
                            .padding(.trailing, 30)
                            .font(.system(size:22))
                    }
                    
                    Button(action : actionHandler){
                        HStack{
                            Spacer()
                            Text(isLoginMode ? "Log In" : "create Account")
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .font(.system(size:23, weight: .semibold))
                            Spacer()
                        }
                    }.padding()
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: Double(Int("f6", radix: 16)!)/255, green: Double(Int("d3", radix: 16)!)/255, blue: Double(Int("65", radix: 16)!)/255))
                        .alert(isPresented: $signupResult){
                            Alert(title: Text("Successfully Sign Up"), message: nil, dismissButton: .default(Text("ok")))
                        }
                }
            }.navigationTitle(isLoginMode ? "Log in" : "Create Account")
        }.navigationViewStyle(StackNavigationViewStyle())
            .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil){
                ImagePicker(image: $image)
            }
    }
    
    private func actionHandler(){
        if isLoginMode {
            signIn()
        } else{
            createNewAccount()
        }
    }
    
    private func signIn(){
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password){
            result, err in
            if let err = err {
                print(err)
                return
            }
        }
        self.didCompleteLoginProcess()
        print("in signIn : \(FirebaseManager.shared.auth.currentUser?.uid ?? "")")
        
    }
    
    private func createNewAccount(){
        FirebaseManager.shared.auth.createUser(withEmail:email, password:password){
            result, err in
            if let err = err{
                print("fail : ", err)
                return
            }
            print("successfully create user : \(result?.user.uid ?? "")")
            
            self.persistImageToStorage()
        }
    }
    
    private func persistImageToStorage(){
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else { return }
        
        let ref = FirebaseManager.shared.storage.reference().child("Profiles/\(uid).jpeg")
        
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpeg"
        
        ref.putData(imageData, metadata: metaData){
            metadata, error in
            ref.downloadURL{
                url, error in
                if let error = error {
                    print("in downloadURL : \(error)")
                    return
                }
                FirebaseManager.shared.firestore.collection("users").document(uid).setData(
                    ["uid" : uid, "profileImagePath" : url?.absoluteString ?? "", "email" : email])
            }
        }
        signupResult.toggle()
    }
}
