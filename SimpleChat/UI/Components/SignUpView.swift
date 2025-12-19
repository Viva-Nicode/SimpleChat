import SwiftUI
import Alamofire
import PhotosUI
import Combine

protocol UserInteractionFeedback {
    func setErrorMessage(_ message: LocalizedStringKey)
    func clearTextField()

    var getEmail: String { get }
    var getPassword: String { get }
    var getProfileData: Data? { get }
}

class SignUpViewModel: ObservableObject, UserInteractionFeedback {

    @Published fileprivate var email = ""
    @Published fileprivate var password = ""
    @Published fileprivate var messageToggle = false
    @Published fileprivate var failReason:LocalizedStringKey = ""
    @Published fileprivate var isButtonDisable = false
    @Published fileprivate var profileJpegData: Data?

    public func setErrorMessage(_ message: LocalizedStringKey) {
        failReason = message
        messageToggle = true
    }

    public func clearTextField() {
        email = ""
        password = ""
    }

    var getEmail: String { email }
    var getPassword: String { password }
    var getProfileData: Data? { profileJpegData }
}

struct SignUpView: View {
    @StateObject var svm: SignUpViewModel = SignUpViewModel()
    @Environment(\.injected) private var injected: DIContainer
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var userSelectedImage: Image?
    @State private var userSelectUIImage: UIImage?
    @State private var subscriptions: Set<AnyCancellable> = []

    var body: some View {
        VStack {
            Text("Create Account").font(.system(size: 40)).frame(maxWidth: 200, alignment: .leading).padding(.trailing, 120)
            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                if let img = userSelectedImage {
                    img.resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .overlay {
                        Circle().stroke(.gray, lineWidth: 4) }
                        .frame(width: 150, height: 150)
                } else {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .shadow(radius: 5)
                        .frame(width: 150, height: 150)
                        .foregroundColor(.gray)
                }
            }.onChange(of: photosPickerItem) { _, nv in
                svm.isButtonDisable = true
                Task(priority: .high) {
                    if let data = try? await nv?.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            userSelectUIImage = uiImage
                            if let jpegData = uiImage.jpegData(compressionQuality: 1.0) {
                                svm.profileJpegData = jpegData
                                userSelectedImage = Image(uiImage: uiImage)
                                svm.isButtonDisable = false
                                return
                            } else {
                                svm.setErrorMessage("An error occurred while converting the image. Try a different image.")
                                photosPickerItem = nil
                                svm.isButtonDisable = false
                            }
                        } else {
                            svm.setErrorMessage("An error occurred while converting the image. Try a different image.")
                            photosPickerItem = nil
                            svm.isButtonDisable = false
                        }
                    } else {
                        svm.setErrorMessage("An error occurred while converting the image. Try a different image.")
                        photosPickerItem = nil
                        svm.isButtonDisable = false
                    }
                }
            }
            TextField("", text: $svm.email, prompt: Text("Email")
                    .font(.system(size: 20))
                    .foregroundColor(.blue.opacity(0.3)))
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(CommonTextfieldStyle())
                .padding(.leading, 30)
                .padding(.trailing, 30)
                .font(.system(size: 10))
            Spacer().frame(height: 10)
            SecureField("", text: $svm.password, prompt: Text("Password")
                    .font(.system(size: 20))
                    .foregroundColor(.blue.opacity(0.3)))
                .textFieldStyle(CommonTextfieldStyle())
                .padding(.leading, 30)
                .padding(.trailing, 30)
                .font(.system(size: 22))
            Spacer().frame(height: 30)
            Button(action: createNewAccount) {
                Text("submit")
            }.buttonStyle(CommonButtonStyle(scaledAmount: 0.9))
                .disabled(svm.isButtonDisable)
        }.alert(isPresented: $svm.messageToggle) {
            Alert(title: Text(""), message: Text(svm.failReason))
        }
    }

    private func createNewAccount() {
        do {
            try injected.interactorContainer.userInteractor.signup(svm, $subscriptions, photosPickerItem)
        } catch (let error) {
            print(error)
        }
    }
}
