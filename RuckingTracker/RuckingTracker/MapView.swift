//
//  MapView.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import SwiftUI
import CoreLocation

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 20) {
            HeaderView(title: "Activity", systemIcon: "flame.fill")
                .padding(.bottom, 4)

            HStack(spacing: 24) {
                MetricCardView(
                    title: "Miles",
                    value: String(format: "%.2f", viewModel.distanceMeters / 1609.34),
                    unit: "mi"
                )
                MetricCardView(
                    title: "Time",
                    value: String(format: "%.0f", viewModel.elapsedTime),
                    unit: "sec"
                )
            }
            .padding(.vertical, 8)

            if let statusMessage = viewModel.statusMessage {
                Label(statusMessage, systemImage: "location.fill")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(12)
            }

            Spacer()

            if viewModel.isTracking {
                Button("Stop & Save") { viewModel.stopSession() }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            } else {
                Button(viewModel.isLocationAuthorized ? "Start Ruck" : viewModel.permissionButtonTitle) {
                    viewModel.startSession()
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(viewModel.isLocationAuthorized ? Color.orange : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            if viewModel.showSaveActivity, let activity = viewModel.currentActivity {
                Text("Saved: \(String(format: "%.2f", activity.distance)) mi in \(Int(activity.duration/60)) min")
                    .foregroundColor(.green)
                    .padding(.top, 12)
            }

            Spacer()

        }
        .padding()
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                viewModel.handleAppMovedToBackground()
            }
        }
    }
}
