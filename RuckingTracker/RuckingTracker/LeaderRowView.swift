//
//  LeaderRowView.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import SwiftUI

struct LeaderRowView: View {
    let row: LeaderRowData

    var body: some View {
        HStack {
            Text("#\(row.rank)")
                .bold()
                .frame(width: 36)
                .foregroundColor(.orange)
            Text(row.name)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.body)
            Text("\(row.score)")
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
        .shadow(color: Color.orange.opacity(0.08), radius: 2, x: 0, y: 1)
    }
}
