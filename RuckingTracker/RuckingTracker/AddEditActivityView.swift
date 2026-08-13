//
//  AddEditActivityView.swift
//  RuckingTracker
//

import SwiftUI

struct AddEditActivityView: View {
    @Environment(\.dismiss) private var dismiss

    /// Pass an existing activity to enter edit mode; nil creates a new ruck.
    var existingActivity: TrackedActivity?

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var distanceText: String = ""
    @State private var durationMinText: String = ""
    @State private var packWeightText: String = ""
    @State private var startedAt: Date = Date()

    @State private var showValidationAlert = false
    @State private var validationMessage = ""

    private var isEditing: Bool { existingActivity != nil }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    TextField("Title (e.g. Morning Ruck)", text: $title)
                        .autocapitalization(.words)
                    DatePicker(
                        "Date & Time",
                        selection: $startedAt,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section(header: Text("Metrics")) {
                    HStack {
                        Text("Distance")
                        Spacer()
                        TextField("0.0", text: $distanceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                        Text("mi").foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Duration")
                        Spacer()
                        TextField("0", text: $durationMinText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                        Text("min").foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Pack Weight")
                        Spacer()
                        TextField("optional", text: $packWeightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                        Text("lb").foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle(isEditing ? "Edit Ruck" : "Log Ruck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveActivity()
                    }
                }
            }
            .alert("Missing Info", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
            .onAppear {
                populateIfEditing()
            }
        }
    }

    // MARK: - Helpers

    private func populateIfEditing() {
        guard let a = existingActivity else { return }
        title = a.title
        notes = a.notes
        distanceText = a.distance > 0 ? String(format: "%.2f", a.distance) : ""
        durationMinText = a.duration > 0 ? String(format: "%.0f", a.duration / 60) : ""
        packWeightText = a.packWeight.map { String(format: "%.1f", $0) } ?? ""
        startedAt = a.startedAt
    }

    private func saveActivity() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else {
            validationMessage = "Please enter a title for this ruck."
            showValidationAlert = true
            return
        }

        let distance = Double(distanceText) ?? 0
        let durationMin = Double(durationMinText) ?? 0

        guard distance > 0 else {
            validationMessage = "Please enter a distance greater than 0."
            showValidationAlert = true
            return
        }
        guard durationMin > 0 else {
            validationMessage = "Please enter a duration greater than 0 minutes."
            showValidationAlert = true
            return
        }

        let duration = durationMin * 60
        let pace = durationMin / distance
        let packWeight = Double(packWeightText)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)

        if let existing = existingActivity {
            // Edit mode — mutate the existing object and persist
            existing.title = trimmedTitle
            existing.notes = trimmedNotes
            existing.distance = distance
            existing.duration = duration
            existing.pace = pace
            existing.packWeight = packWeight
            existing.startedAt = startedAt
            ActivityStore.shared.update(existing)
        } else {
            // Add mode — create and persist a new activity
            let activity = TrackedActivity(
                id: UUID(),
                title: trimmedTitle,
                notes: trimmedNotes,
                distance: distance,
                duration: duration,
                pace: pace,
                startedAt: startedAt,
                packWeight: packWeight
            )
            ActivityStore.shared.save(activity)
        }

        dismiss()
    }
}
