import SwiftUI

struct AccountView: View {
    @State private var anyView = true
    @State var shouldShowEULAagreePopUpView = false
    @State var signinSuccessedEmail = ""
    @Binding var isLogined: Bool

    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            if anyView {
                LoginView(loginSuccessedEmail: $signinSuccessedEmail,
                    isLogined: $isLogined,
                    shouldShowEULAagreePopUpView: $shouldShowEULAagreePopUpView)
            } else {
                SignUpView()
            }
            VStack {
                Button(action: { anyView.toggle() }) {
                    if anyView {
                        Text("not a member?")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 30)
                    } else {
                        Text("already member").frame(alignment: .trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 30)
                    }
                }.padding(.top, 5)
            }
            Spacer()
        }.fullScreenCover(isPresented: $shouldShowEULAagreePopUpView) {
            VStack(alignment: .center) {
                Text("Software License Agreement")
                    .bold()
                    .font(.system(size: 21))
                Spacer()
                Text("The following actions should not be taken when using the service.")
                    .font(.system(size: 15))
                Spacer()
                Divider()
                VStack(alignment: .center, spacing: 12) {
                    HStack(alignment: .center) {
                        Text("Actions that damage the reputation or cause disadvantages to others.")
                            .font(.system(size: 16))
                        Spacer()
                    }
                    HStack(alignment: .center) {
                        Text("Posting obscene materials or linking to pornographic sites on bulletin boards, etc.")
                            .font(.system(size: 16))
                        Spacer()
                    }
                    HStack(alignment: .center) {
                        Text("Actions that infringe on the copyrights or other rights of the company or third parties.")
                            .font(.system(size: 16))
                        Spacer()
                    }
                    HStack(alignment: .center) {
                        Text("Distributing information, sentences, images, or sounds to others that violate public order and good morals.")
                            .font(.system(size: 16))
                        Spacer()
                    }
                    HStack(alignment: .center) {
                        Text("Circulating false information with the intent to give financial benefits to oneself or others, or to cause harm to others.")
                            .font(.system(size: 16))
                        Spacer()
                    }
                    HStack(alignment: .center) {
                        Text("Distributing information that facilitates or mediates prostitution.")
                            .font(.system(size: 16))
                        Spacer()
                    }
                    HStack(alignment: .center) {
                        Text("Continuously sending words, sounds, texts, or images that cause shame, disgust, or fear, thereby disturbing the recipient's daily life.").font(.system(size: 16))
                        Spacer()
                    }
                }
                Divider()
                Spacer()
                Text("If the above behavior is detected, the use of the service may be restricted without warning.")
                    .font(.system(size: 15))
                Spacer()
                HStack(alignment: .center) {
                    Spacer()
                    Button {
                        UserDefaultsKeys.userEmail.setValue(signinSuccessedEmail)
                        UserDefaultsKeys.appTheme.setValue(true)
                        isLogined = false
                    } label: {
                        Text("I agree")
                    }
                    Spacer()
                }
            }.padding()
        }
    }
}
