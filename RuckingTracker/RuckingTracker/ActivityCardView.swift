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
                    .lineLimit(1)
                Text(activity.startedAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.2f mi", activity.distance))
                    .font(.subheadline.bold())
                    .foregroundColor(.ruxAccent)
                Text(activity.timeText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}




