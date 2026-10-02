//
//  ActivityCardView.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import SwiftUI

struct ActivityCardView: View {
    let activity: TrackedActivity

    var body: some View {
        HStack(spacing: 14) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.ruxAccent)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title.isEmpty ? "Untitled Ruck" : activity.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(activity.startedAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.2f mi", activity.distance))
                    .font(.subheadline.bold())
                    .foregroundColor(.ruxAccent)
                Text(activity.timeText)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.black.opacity(0.20))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 4)
    }
}




