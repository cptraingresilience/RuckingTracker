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
    
    init() {
        Task {
            await loadActivities()
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
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            // Ensure 'try' is used for the throwing method encode(_:)
            let data = try encoder.encode(activity)
            
            let url = directoryURL.appendingPathComponent("\(activity.id.uuidString).json")
            
            // Ensure 'try' is used for the throwing method write(to:options:)
            try data.write(to: url, options: .atomic)

            // Insert to published array
            activities.insert(activity, at: 0)

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
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(activity)
            let url = directoryURL.appendingPathComponent("\(activity.id.uuidString).json")
            try data.write(to: url, options: .atomic)
            // Replace in array to trigger SwiftUI refresh
            if let idx = activities.firstIndex(where: { $0.id == activity.id }) {
                activities[idx] = activity
            }
        } catch {
            print("Error updating activity: \(error)")
        }
    }

    // MARK: - Delete
    func delete(_ activity: TrackedActivity) {
        let url = directoryURL.appendingPathComponent("\(activity.id.uuidString).json")
        try? FileManager.default.removeItem(at: url)
        activities.removeAll { $0.id == activity.id }
    }

    // MARK: - Convenience
    func addActivity(_ activity: TrackedActivity) {
        save(activity) // saves to disk and updates @Published array
    }
}
