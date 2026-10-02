//
//  RuxBackground.swift
//  Rux
//
//  Shared branded background — same treatment as the Home feed.
//  Usage:  AnyView() .ruxBackground()
//

import SwiftUI

struct RuxBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            GeometryReader { geo in
                Image("Background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .opacity(0.85)
                    .saturation(1.15)
            }
            .ignoresSafeArea()

            content
        }
    }
}

extension View {
    /// Applies the shared Rux branded background behind this view.
    func ruxBackground() -> some View {
        modifier(RuxBackgroundModifier())
    }
}
