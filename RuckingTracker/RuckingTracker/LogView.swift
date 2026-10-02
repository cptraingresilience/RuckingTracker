//
//  LogView.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import SwiftUI

struct LogView: View {
    @StateObject private var viewModel = LogViewModel()
    @State private var showAddActivity = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Stats row
                HStack(spacing: 12) {
                    MetricCardView(
                        title: "Total Miles",
                        value: String(format: "%.1f", viewModel.totalMiles),
                        unit: "mi"
                    )
                    MetricCardView(
                        title: "Avg Pace",
                        value: viewModel.avgPaceString,
                        unit: "min/mi"
                    )
                    MetricCardView(
                        title: "Total Time",
                        value: viewModel.totalTimeString,
                        unit: ""
                    )
                    MetricCardView(
                        title: "Best Ruck",
                        value: viewModel.bestRuckDistanceString,
                        unit: "mi"
                    )
                }
                .padding(.horizontal)
                .padding(.vertical, 12)

                if let errorMessage = viewModel.errorMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.85))
                        Spacer()
                        Button("Dismiss") {
                            viewModel.clearError()
                        }
                        .font(.footnote.bold())
                        .foregroundColor(.orange)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                }

                if viewModel.isLoading && viewModel.activities.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                        Text("Loading your rucks...")
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                    }
                } else if viewModel.activities.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "figure.walk.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.ruxAccent.opacity(0.8))
                        Text("No rucks logged yet")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Tap + to log your first ruck")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        Button("Refresh") {
                            Task { await viewModel.refresh() }
                        }
                        .foregroundColor(.orange)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(viewModel.activities) { activity in
                            NavigationLink {
                                ActivityDetailView(activity: activity)
                            } label: {
                                ActivityCardView(activity: activity)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.deleteActivity(viewModel.activities[index])
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .ruxBackground()
            .navigationTitle("Activity Log")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddActivity = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showAddActivity) {
                AddEditActivityView()
            }
        }
    }
}