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
        VStack(alignment: .leading, spacing: 8) {
            Text("Distance: \(String(format: "%.2f", activity.distance)) mi")
                .fontWeight(.bold)
            Text("Duration: \(Int(activity.duration/60)) min")
            Text("Pace: \(String(format: "%.2f", activity.pace)) min/mi")
        }
        .padding()
        .background(Color(UIColor.systemGray5))
        .cornerRadius(10)
    }
}



