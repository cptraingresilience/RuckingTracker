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
            VStack(alignment: .leading, spacing: 2) {
                Text(row.name)
                    .font(.body)
                if !row.subtitle.isEmpty {
                    Text(row.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
