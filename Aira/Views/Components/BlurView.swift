//
//  BlurView.swift
//  Aira
//
//  Created by Gayathri Gondi on 25/07/25.
//



//  BlurView.swift
//  Aira
//
//  Created by Gayathri Gondi on 24/07/25.
//


import SwiftUI

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        // No updates needed for static blur
    }
}
