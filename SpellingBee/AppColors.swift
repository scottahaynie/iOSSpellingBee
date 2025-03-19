//
//  AppColors.swift
//  SpellingBee
//
//  Created by Scott Haynie on 3/19/25.
//
import SwiftUI

// allows specifying colors by hex. eg. Color(hex: 0x44AAFF)
extension Color {
    init(hex: Int, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: opacity
        )
    }
}

struct AppColors {
    static let colorTitle = Color(hex: 0x9988DD)
    static let colorMain = Color.blue
    static let hexagon = Color.blue
    static let centerHexagon = Color.indigo
}
