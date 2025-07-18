//
//  AppStyle.swift
//  Aira
//
//  Created by Gayathri Gondi on 18/07/25.
//

// AppStyle.swift
import SwiftUI

enum AppColors {
    static let background = Color(red: 20/255, green: 16/255, blue: 36/255)
    static let accent = Color(red: 255/255, green: 133/255, blue: 178/255)
    static let secondaryAccent = Color(red: 255/255, green: 200/255, blue: 230/255)
    static let text = Color.white
    static let grayText = Color.gray
}

enum AppFonts {
    static func custom(size: CGFloat) -> Font {
        .custom("Pixelify Sans", size: size)
    }
}
