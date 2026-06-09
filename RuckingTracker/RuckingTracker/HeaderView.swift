//
//  HeaderView.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import SwiftUI

struct HeaderView: View {
    let title: String
    let systemIcon: String
    
    var body: some View {
        HStack {
            Image(systemName: systemIcon)
                .font(.title2)
                .foregroundColor(.orange)
            Text(title)
                .font(.title2)
                .bold()
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 14)
    }
}


