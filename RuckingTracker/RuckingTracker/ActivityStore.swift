//
//  ActivityStore.swift
//  Rux
//
//  Created by Picos on 11/10/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ActivityStore: ObservableObject {
    static let shared = ActivityStore()
    @Published var lastSyncError: String?
    private static let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    
    init() {
        guard !Self.isRunningTests else { return }

        Task {
            await loadActivities()
            await refreshFromBackendIfAvailable()
        }
    }

    @Published var activities: [TrackedActivity] = []

    // MARK: - File System (Final Clean)
    private var directoryURL: URL {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = docs.appendingPathComponent("activities", isDirectory: true)
        
        // Use do/catch locally to contain the throwing call, ensuring the function returns.
        if !fm.fileExists(atPath: folder.path) {
            do {
                try fm.createDirectory(at: folder, withIntermediateDirectories: true)
            } catch {
                print("Error creating activity directory: \(error)")
            }
        }
        
        return folder
    }

    // MARK: - Save
    func save(_ activity: TrackedActivity) {
        do {
            try writeActivityToDisk(activity)
            activities.insert(activity, at: 0)
            let request = makeRequest(from: activity)
            Task { [weak self] in
                await self?.syncCreate(request)
            }
        } catch {
            print("Error saving activity: \(error)")
        }
    }


    // MARK: - Load All (Fixed with MainActor for Decoding)
    func loadActivities() async {
        let fm = FileManager.default

        do {
            // 1. Get files list (quick metadata operation)
            let files = try fm.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            
            // 2. Read and Decode files in a background task
            // The closure is marked @Sendable and the file reading/data handling is done here.
            let decoded: [TrackedActivity] = try await Task.detached(priority: .background) { @Sendable in
                var items: [TrackedActivity] = []
                let decoder = JSONDecoder()
                
                // FIX 1 & 2: Corrected to dateDecodingStrategy
                decoder.dateDecodingStrategy = .iso8601

                for file in files {
                    guard file.pathExtension.lowercased() == "json" else { continue }
                    
                    if let data = try? Data(contentsOf: file) {
                        // FIX 3: Decoding a Main Actor-isolated type must happen on the Main Actor.
                        // We switch threads temporarily for just this operation.
                        let act = try? await MainActor.run {
                            try decoder.decode(TrackedActivity.self, from: data)
                        }

                        if let act = act {
                            items.append(act)
                        }
                    }
                }
                
                return items
            }.value

            // 3. Sort & publish on main actor (safe because ActivityStore is @MainActor)
            let sortedItems = decoded.sorted { $0.startedAt > $1.startedAt }
            self.activities = sortedItems

        } catch {
            print("Error loading activities: \(error)")
        }
    }

    // MARK: - Update
    func update(_ activity: TrackedActivity) {
        do {
            try writeActivityToDisk(activity)
            if let idx = activities.firstIndex(where: { $0.id == activity.id }) {
                activities[idx] = activity
            }
            let request = makeRequest(from: activity)
            Task { [weak self] in
                await self?.syncUpdate(request)
            }
        } catch {
            print("Error updating activity: \(error)")
        }
    }

    // MARK: - Delete
    func delete(_ activity: TrackedActivity) {
        removeActivityFromDisk(activity)
        activities.removeAll { $0.id == activity.id }
        let activityID = activity.id.uuidString
        Task { [weak self] in
            await self?.syncDelete(activityID)
        }
    }

    // MARK: - Convenience
    func addActivity(_ activity: TrackedActivity) {
        save(activity) // saves to disk and updates @Published array
    }

    func refreshFromBackendIfAvailable() async {
        guard APIClient.shared.hasAccessToken else {
            lastSyncError = nil
            return
        }

        do {
            let remoteActivities = try await APIClient.shared.getActivities()
            let mappedActivities = remoteActivities.compactMap(Self.makeTrackedActivity(from:))
            let mergedActivities = mergeActivities(local: activities, remote: mappedActivities)
            try replaceActivitiesOnDisk(with: mergedActivities)
            activities = mergedActivities.sorted { $0.startedAt > $1.startedAt }
            lastSyncError = nil
        } catch APIError.unauthorized {
            lastSyncError = nil
        } catch {
            lastSyncError = error.localizedDescription
        }
    }

    func clearSyncError() {
        lastSyncError = nil
    }

    private func syncCreate(_ request: ActivitySubmissionRequest) async {
        guard APIClient.shared.hasAccessToken else { return }

        do {
            let response = try await APIClient.shared.submitActivity(request)
            if let updatedActivity = Self.makeTrackedActivity(from: response) {
                upsertLocalActivity(updatedActivity)
                lastSyncError = nil
            }
        } catch {
            lastSyncError = "Saved locally. Backend sync failed: \(error.localizedDescription)"
        }
    }

    private func syncUpdate(_ request: ActivitySubmissionRequest) async {
        guard APIClient.shared.hasAccessToken else { return }

        do {
            let response = try await APIClient.shared.updateActivity(id: request.id, request)
            if let updatedActivity = Self.makeTrackedActivity(from: response) {
                upsertLocalActivity(updatedActivity)
                lastSyncError = nil
            }
        } catch {
            lastSyncError = "Updated locally. Backend sync failed: \(error.localizedDescription)"
        }
    }

    private func syncDelete(_ activityID: String) async {
        guard APIClient.shared.hasAccessToken else { return }

        do {
            try await APIClient.shared.deleteActivity(id: activityID)
            lastSyncError = nil
        } catch {
            lastSyncError = "Deleted locally. Backend sync failed: \(error.localizedDescription)"
        }
    }

    private func upsertLocalActivity(_ activity: TrackedActivity) {
        do {
            try writeActivityToDisk(activity)
            if let index = activities.firstIndex(where: { $0.id == activity.id }) {
                activities[index] = activity
            } else {
                activities.insert(activity, at: 0)
            }
            activities.sort { $0.startedAt > $1.startedAt }
        } catch {
            print("Error writing synced activity: \(error)")
        }
    }

    private func writeActivityToDisk(_ activity: TrackedActivity) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(activity)
        let url = directoryURL.appendingPathComponent("\(activity.id.uuidString).json")
        try data.write(to: url, options: .atomic)
    }

    private func removeActivityFromDisk(_ activity: TrackedActivity) {
        let url = directoryURL.appendingPathComponent("\(activity.id.uuidString).json")
        try? FileManager.default.removeItem(at: url)
    }

    private func replaceActivitiesOnDisk(with items: [TrackedActivity]) throws {
        let fm = FileManager.default
        let files = try fm.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)

        for file in files where file.pathExtension.lowercased() == "json" {
            try? fm.removeItem(at: file)
        }

        for item in items {
            try writeActivityToDisk(item)
        }
    }

    private func mergeActivities(local: [TrackedActivity], remote: [TrackedActivity]) -> [TrackedActivity] {
        var mergedById = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })

        for activity in remote {
            mergedById[activity.id] = activity
        }

        return Array(mergedById.values)
    }

    private func makeRequest(from activity: TrackedActivity) -> ActivitySubmissionRequest {
        ActivitySubmissionRequest(
            id: activity.id.uuidString,
            title: activity.title,
            notes: activity.notes.isEmpty ? nil : activity.notes,
            distance: activity.distance,
            duration: activity.duration,
            pace: activity.pace,
            packWeight: activity.packWeight,
            startedAt: Self.iso8601String(from: activity.startedAt),
            endedAt: Self.iso8601String(from: activity.startedAt.addingTimeInterval(activity.duration))
        )
    }

    private static func makeTrackedActivity(from response: ActivityResponse) -> TrackedActivity? {
        guard let id = UUID(uuidString: response.id),
              let startedAt = parseDate(response.startedAt) else {
            return nil
        }

        return TrackedActivity(
            id: id,
            title: response.title,
            notes: response.notes,
            distance: response.distance,
            duration: response.duration,
            pace: response.pace,
            startedAt: startedAt,
            packWeight: response.packWeight
        )
    }

    private static func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    private static func parseDate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: value) {
            return date
        }

        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}
