//
//  CustomViewStyles.swift
//  Capstone_2
//
//  Created by Nicode . on 12/31/23.
//

import Foundation
import SwiftUI

struct CommonTextfieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color.gray.opacity(0.25))
                .cornerRadius(30)
                .frame(height: 46)
            configuration
                .font(.system(size: 20))
                .padding()
        }
    }
}

struct GeneralTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        ZStack {
            Rectangle()
                .foregroundStyle(.white)
                .frame(height: 45)
                .padding()
            configuration
                .font(.system(size: 20))
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(20)
                .multilineTextAlignment(.center)
        }
    }
}

struct CommonButtonStyle: ButtonStyle {
    let scaledAmount: CGFloat

    init(scaledAmount: CGFloat = 0.9) {
        self.scaledAmount = scaledAmount
    }

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Rectangle().foregroundColor(Color.blue.opacity(0.9))
                .frame(width: UIScreen.main.bounds.width * 0.85)
                .cornerRadius(30)
                .frame(height: 46)
            configuration
                .label
                .font(.system(size: 23))
                .foregroundColor(.white)
        }
            .scaleEffect(configuration.isPressed ? scaledAmount : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

struct GeneralToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Rectangle()
                .fill(configuration.isOn ? Color.green : Color.white)
                .frame(width: 74, height: 37)
                .cornerRadius(40)
                .overlay(
                Circle()
                    .fill(Color.orange)
                    .frame(width: 30, height: 30)
                    .offset(x: configuration.isOn ? 15 : -15)
                    .animation(Animation.linear(duration: 0.2), value: configuration.isOn)
                    .onTapGesture { withAnimation { configuration.isOn.toggle() } }
            )
                .background(Color.black)
                .cornerRadius(40)
        }
    }
}

struct LineTextfieldStyle: TextFieldStyle {

    @EnvironmentObject var appSettingModel: AppSettingModel

    func _body(configuration: TextField<Self._Label>) -> some View {
        ZStack {
            Rectangle()
                .frame(height: 1)
                .offset(y: 16)
                .padding(.leading, 16)
                .padding(.trailing, 16)
                .appThemeForegroundColor(appSettingModel.appTheme)
            configuration
                .font(.system(size: 20))
                .padding()
                .appThemeForegroundColor(appSettingModel.appTheme)
        }.appThemeBackgroundColor(appSettingModel.appTheme)
    }
}

struct LineTextfieldClearStyle: TextFieldStyle {

    @EnvironmentObject var appSettingModel: AppSettingModel

    func _body(configuration: TextField<Self._Label>) -> some View {
        ZStack {
            Rectangle()
                .frame(height: 1)
                .offset(y: 16)
                .padding(.leading, 16)
                .padding(.trailing, 16)
                .appThemeForegroundColor(appSettingModel.appTheme)
            configuration
                .font(.system(size: 20))
                .padding()
                .appThemeForegroundColor(appSettingModel.appTheme)
        }.background(.clear)
    }
}

struct WhiteLineTextfieldStyle: TextFieldStyle {

    func _body(configuration: TextField<Self._Label>) -> some View {
        VStack(spacing: 2) {
            configuration
                .font(.system(size: 20))
                .foregroundStyle(.white)
                .padding(.horizontal)
            Rectangle()
                .frame(height: 1)
                .padding(.horizontal, 16)
                .foregroundStyle(.white)
        }.background(.clear)
    }
}


struct LinearGradientButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label.background {
            if configuration.isPressed {
                Rectangle()
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.red, Color.blue]),
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(6)
                    .scaleEffect(0.9)
                    .opacity(0.9)
            } else {
                Rectangle()
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.yellow, Color.green]),
                    startPoint: .topTrailing, endPoint: .bottomLeading))
                    .cornerRadius(6)
                    .scaleEffect(1.0)
                    .opacity(1.0)
            }
        }
    }
}

struct SendButtonStyle: ButtonStyle {
    @Binding var textFieldString: String

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14.5, weight: .semibold, design: .rounded))
            .padding(.vertical, 7)
            .padding(.horizontal, 14)
            .foregroundStyle(textFieldString.isEmpty ? .red : .blue)
            .background {
            ZStack {
                Capsule()
                    .fill(textFieldString.isEmpty ? .red : .blue)
                    .stroke(.black, lineWidth: 3)
                    .offset(y: configuration.isPressed ? 0 : 7)
                Capsule()
                    .fill(.white)
                    .stroke(.black, lineWidth: 3)
            }
        }
            .offset(y: configuration.isPressed ? 7 : 0)
    }
}
