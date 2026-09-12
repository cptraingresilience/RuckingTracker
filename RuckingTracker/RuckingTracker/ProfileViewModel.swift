//
//  ProfileViewModel.swift
//  Rux
//
//  Created by Picos on 11/11/25.
//

import Foundation
import Combine

struct ProfileStat: Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: UserModel? = nil
    @Published var subtitle: String = ""
    @Published var statusMessage: String = ""
    @Published var stats: [ProfileStat] = []
    @Published var latestActivity: TrackedActivity?

    private let store: ActivityStore
    private let currentUserProvider: () -> UserDTO?
    private let hasAccessTokenProvider: () -> Bool
    private var cancellables = Set<AnyCancellable>()

    init(
        activityStore: ActivityStore? = nil,
        currentUserProvider: @escaping () -> UserDTO? = { APIClient.shared.currentUser },
        hasAccessTokenProvider: @escaping () -> Bool = { APIClient.shared.hasAccessToken }
    ) {
        self.store = activityStore ?? ActivityStore.shared
        self.currentUserProvider = currentUserProvider
        self.hasAccessTokenProvider = hasAccessTokenProvider

        store.$activities
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activities in
                self?.applyProfile(activities: activities)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .apiClientCurrentUserDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyProfile(activities: self?.store.activities ?? [])
            }
            .store(in: &cancellables)

        applyProfile(activities: store.activities)
    }

    func refresh() {
        applyProfile(activities: store.activities)
    }

    func loadProfile(user: UserModel, activities: [TrackedActivity]) {
        self.user = user
        subtitle = ""
        statusMessage = ""
        latestActivity = activities.sorted { $0.startedAt > $1.startedAt }.first
        stats = Self.makeStats(from: activities)
    }

    private func applyProfile(activities: [TrackedActivity]) {
        if let currentUser = currentUserProvider() {
            let trimmedFullName = currentUser.fullName?.trimmingCharacters(in: .whitespacesAndNewlines)
            let displayName = (trimmedFullName?.isEmpty == false ? trimmedFullName : nil) ?? currentUser.username
            user = UserModel(name: displayName, profileImageName: "person.crop.circle.fill")
            subtitle = currentUser.email
            statusMessage = trimmedFullName?.isEmpty == false ? "@\(currentUser.username) • Signed in" : "@\(currentUser.username)"
        } else {
            user = UserModel(name: "Local Rucker", profileImageName: "person.crop.circle.fill")
            subtitle = hasAccessTokenProvider() ? "Signed-in profile details unavailable" : "Sign in to sync your profile"
            statusMessage = hasAccessTokenProvider() ? "" : "Tracking stays on this device until you sign in."
        }

        let sortedActivities = activities.sorted { $0.startedAt > $1.startedAt }
        latestActivity = sortedActivities.first
        stats = Self.makeStats(from: sortedActivities)
    }

    private static func makeStats(from activities: [TrackedActivity]) -> [ProfileStat] {
        let totalRucks = activities.count
        let totalMiles = activities.reduce(0) { $0 + $1.distance }
        let prPace = activities.map(\.pace).filter { $0 > 0 }.min() ?? 0

        return [
            ProfileStat(title: "Rucks", value: "\(totalRucks)"),
            ProfileStat(title: "Miles", value: String(format: "%.1f", totalMiles)),
            ProfileStat(title: "PR Pace", value: prPace > 0 ? String(format: "%.2f", prPace) : "--")
        ]
    }
}







