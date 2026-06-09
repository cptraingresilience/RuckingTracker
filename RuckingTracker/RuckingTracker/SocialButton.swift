//
//  SocialButton.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import SwiftUI

struct SocialButton: View {
    let text: String
    let color: Color?
    let gradient: Gradient?
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(text)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                Group {
                    if let gradient = gradient {
                        LinearGradient(gradient: gradient, startPoint: .leading, endPoint: .trailing)
                    } else {
                        color ?? Color.gray
                    }
                }
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}
