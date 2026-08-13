//
//  ActivityDetailView.swift
//  RuckingTracker
//

import SwiftUI

struct ActivityDetailView: View {
    @ObservedObject var activity: TrackedActivity
    @Environment(\.dismiss) private var dismiss

    @State private var showEditSheet = false
    @State private var showDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title.isEmpty ? "Untitled Ruck" : activity.title)
                        .font(.title2.bold())
                    Text(activity.startedAt, style: .date)
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .padding(.horizontal)
                .padding(.top, 6)

                // Metrics grid
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 14
                ) {
                    MetricDetailCard(
                        icon: "figure.walk",
                        label: "Distance",
                        value: String(format: "%.2f", activity.distance),
                        unit: "mi"
                    )
                    MetricDetailCard(
                        icon: "clock",
                        label: "Duration",
                        value: activity.timeText,
                        unit: ""
                    )
                    MetricDetailCard(
                        icon: "speedometer",
                        label: "Pace",
                        value: activity.paceText,
                        unit: "min/mi"
                    )
                    if let weight = activity.packWeight {
                        MetricDetailCard(
                            icon: "backpack",
                            label: "Pack Weight",
                            value: String(format: "%.1f", weight),
                            unit: "lb"
                        )
                    }
                }
                .padding(.horizontal)

                // Notes
                if !activity.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notes", systemImage: "note.text")
                            .font(.headline)
                        Text(activity.notes)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                Spacer(minLength: 40)

                // Delete button
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete Ruck", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationTitle("Ruck Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEditSheet = true }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AddEditActivityView(existingActivity: activity)
        }
        .alert("Delete Ruck?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                ActivityStore.shared.delete(activity)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

// MARK: - Metric Detail Card

struct MetricDetailCard: View {
    let icon: String
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.title3.bold())
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}
