//
//  PixelButton.swift
//  Aira
//
//  Created by Gayathri Gondi on 18/07/25.
//

import SwiftUI

/// A custom pixel-style button with icon and label.
/// Used for stylized UI buttons in the Aira app.
struct PixelButton: View {
    let title: String // 🏷 Button label.
    let iconImageName: String // 🖼 Icon image asset name.
    var background: Color = AppColors.accent
    let width: CGFloat // 📏 Button width.
    let height: CGFloat // 📏 Button height.
    let action: () -> Void // ⚡ Action to perform when button is tapped.

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(iconImageName) // 🖼 Icon on the left.
                    .resizable()
                    .frame(width: 25, height: 25) // 📐 Icon size.
                Text(title) // 🏷 Button text.
                    .font(AppFonts.custom(size: 18)) // 🕹 Pixel-style font.
                    .foregroundColor(.white)
                    .bold()
            }
            .frame(width: width, height: height) // 📏 Button size.
            .padding(10)
            .background(background) // 🎨 Customizable background color.
            .overlay(
                Rectangle() // 🧱 Pixel-style border.
                    .stroke(AppColors.secondaryAccent, lineWidth: 4) // 🎨 Light pink border.
                    .shadow(color: AppColors.secondaryAccent, radius: 0, x: 3, y: 3) // ✨ Shadow for glowing effect.
            )
            .frame(maxWidth: .infinity) // 🔄 Stretch across available horizontal space.
        }
        .padding(.horizontal, 30) // 📏 Outer padding.
        .padding(.vertical, 5)
    }
}
