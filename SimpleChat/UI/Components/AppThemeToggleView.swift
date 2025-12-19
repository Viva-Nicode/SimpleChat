//
//  AppThemeToggleView.swift
//  SimpleChat
//
//  Created by Nicode . on 6/8/24.
//

import SwiftUI

struct AppThemeToggleView: View {
    @State var isOn: Bool = false
    var body: some View {
        Toggle("", isOn: $isOn)
            .toggleStyle(CustomToggleStyle())
    }
}

struct CustomToggleStyle: ToggleStyle {
    @Namespace var namespace

    func makeBody(configuration: Configuration) -> some View {
        let isOn = configuration.isOn

        return Button {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
                configuration.isOn.toggle()
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 40, style: .continuous)
                    .frame(width: 70, height: 35)
                    .overlay(alignment: .leading) { ZStack { isOn ? Color.blue : Color.black.opacity(0.5) } }
                    .overlay(alignment: .leading) {
                    if !isOn {
                        Image("moon")
                            .resizable()
                            .matchedGeometryEffect(id: "Circle", in: namespace)
                            .frame(width: 25, height: 25)
                            .scaledToFit()
                            .offset(x: isOn ? 5 : 43)
                    } else {
                        Image("sun")
                            .resizable()
                            .matchedGeometryEffect(id: "Circle", in: namespace)
                            .frame(width: 25, height: 25)
                            .scaledToFit()
                            .offset(x: isOn ? 5 : 50)
                    }
                }
            }.mask { RoundedRectangle(cornerRadius: 40, style: .continuous).frame(width: 70, height: 35) }
        }
    }
}
