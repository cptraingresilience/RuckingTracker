//
//  MetricCardView.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import SwiftUI

struct MetricCardView: View {
    let title: String
    let value: String
    let unit: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white.opacity(0.85))
            Text(value)
                .bold()
                .font(.title2)
                .foregroundColor(.white)
            if let unit = unit {
                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(width: 110, height: 60)
        .padding(.vertical, 6)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.20))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
    }
}


