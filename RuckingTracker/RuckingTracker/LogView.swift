//
//  LogView.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import SwiftUI

struct LogView: View {
    @StateObject private var viewModel = LogViewModel()

    var body: some View {
        VStack(spacing: 14) {
            HeaderView(title: "Activity Log", systemIcon: "chart.bar.fill")

            HStack(spacing: 24) {
                MetricCardView(title: "Total Miles", value: String(format: "%.1f", viewModel.totalMiles), unit: "mi")
                MetricCardView(title: "Avg Pace", value: viewModel.avgPaceString, unit: "min/mi")
            }

            HStack(spacing: 24) {
                MetricCardView(title: "Total Time", value: viewModel.totalTimeString, unit: "")
                MetricCardView(title: "Best Ruck", value: viewModel.bestRuckDistanceString, unit: "mi")
            }

            Divider().padding(.vertical, 8)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.activities) { activity in
                        ActivityCardView(activity: activity)
                    }
                }
            }
        }
        .padding()
    }
}
