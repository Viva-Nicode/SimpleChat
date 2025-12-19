import SwiftUI
import SDWebImageSwiftUI

struct CollapsibleReadUserListView: View {
    @State private var isExpanded: Bool = false
    @EnvironmentObject var applicationViewModel: ApplicationViewModel
    let theme: Bool
    let readusers: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("\(readusers.count) people read it.")
                    .font(.system(size: 11.5))
                    .appThemeForegroundColor(theme)
                Spacer()
            }.padding(.horizontal, 18)
                .padding(.bottom, 9)

            VStack(alignment: .leading) {
                Button {
                    withAnimation(.interactiveSpring(duration: 0.25)) { isExpanded.toggle() }
                } label: {
                    HStack(spacing: 8) {
                        if let firstUser = readusers.first {
                            WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(firstUser)"), options: [.fromCacheOnly])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 30, height: 30)
                                .clipped()
                                .cornerRadius(9)
                                .shadow(radius: 1)
                            Text(applicationViewModel.getNickname(firstUser))
                                .font(.system(size: 14))
                                .appThemeForegroundColor(theme)
                            Spacer()
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .foregroundColor(.blue)
                                .padding(.trailing, 6)
                        } else {
                            Text("Nobody has read it 😅")
                                .font(.system(size: 14))
                                .appThemeForegroundColor(theme)
                            Spacer()
                        }
                    }.padding(9)
                }

                if isExpanded {
                    ForEach(readusers.dropFirst(), id: \.self) { item in
                        HStack(spacing: 8) {
                            WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(item)"), options: [.fromCacheOnly])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 30, height: 30)
                                .clipped()
                                .cornerRadius(9)
                                .shadow(radius: 1)
                            Text(applicationViewModel.getNickname(item))
                                .transition(.slide)
                                .font(.system(size: 14))
                                .appThemeForegroundColor(theme)

                        }.padding(.horizontal, 9)
                            .padding(.bottom, 9)
                    }
                }
            }
                .cornerRadius(8)
                .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme ? .gray.opacity(0.4) : .white, lineWidth: 1)
            )
                .padding(.horizontal)
                .padding(.bottom)
        }
    }
}
