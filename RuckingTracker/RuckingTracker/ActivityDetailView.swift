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
                        .foregroundColor(.white)
                    Text(activity.startedAt, style: .date)
                        .foregroundColor(.white.opacity(0.7))
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
                            .foregroundColor(.white)
                        Text(activity.notes)
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
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
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.ultraThinMaterial)
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.red.opacity(0.18))
                            }
                        )
                        .foregroundColor(.red)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .ruxBackground()
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
                .foregroundColor(.white.opacity(0.75))
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
    }
}