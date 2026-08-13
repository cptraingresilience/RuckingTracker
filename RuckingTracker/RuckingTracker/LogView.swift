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

                Divider()

                if let errorMessage = viewModel.errorMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Dismiss") {
                            viewModel.clearError()
                        }
                        .font(.footnote.bold())
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.08))
                }
 
                if viewModel.isLoading && viewModel.activities.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        ProgressView()
                        Text("Loading your rucks...")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else if viewModel.activities.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "figure.walk.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.ruxAccent.opacity(0.6))
                        Text("No rucks logged yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Tap + to log your first ruck")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Refresh") {
                            Task { await viewModel.refresh() }
                        }
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
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
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
