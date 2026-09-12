//
//  TeamViewModel.swift
//  Rux
//
//  Created by Picos on 11/11/25.
//

import Foundation
import Combine

struct LeaderRowData: Identifiable {
    let id = UUID()
    let rank: Int
    let name: String
    let score: Int
    let subtitle: String

    init(rank: Int, name: String, score: Int, subtitle: String = "") {
        self.rank = rank
        self.name = name
        self.score = score
        self.subtitle = subtitle
    }
}

@MainActor
final class TeamViewModel: ObservableObject {
    @Published var teams: [TeamResponse] = []
    @Published var selectedTeamId: String = ""
    @Published var leaderboard: [LeaderRowData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var emptyStateMessage: String = "No teams available yet."
    private static let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    private let teamsLoader: () async throws -> [TeamResponse]
    private let leaderboardLoader: (String?) async throws -> [LeaderboardEntryResponse]
    private var lastLoadedTeamId: String?

    var selectedTeam: TeamResponse? {
        teams.first(where: { $0.id == selectedTeamId })
    }

    var selectedTeamSummary: String {
        guard let selectedTeam else { return "" }
        let memberCount = selectedTeam.members?.count ?? 0
        let memberLabel = memberCount == 1 ? "member" : "members"
        return "\(selectedTeam.name) • \(memberCount) \(memberLabel)"
    }

    init(
        teamsLoader: @escaping () async throws -> [TeamResponse] = { try await APIClient.shared.getTeams() },
        leaderboardLoader: @escaping (String?) async throws -> [LeaderboardEntryResponse] = { teamId in
            try await APIClient.shared.getLeaderboard(teamId: teamId)
        }
    ) {
        self.teamsLoader = teamsLoader
        self.leaderboardLoader = leaderboardLoader

        if !Self.isRunningTests {
            Task {
                await loadTeamData()
            }
        }
    }

    func loadTeamData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let loadedTeams = try await teamsLoader()
            teams = loadedTeams

            if selectedTeamId.isEmpty || !loadedTeams.contains(where: { $0.id == selectedTeamId }) {
                selectedTeamId = loadedTeams.first?.id ?? ""
            }

            guard !selectedTeamId.isEmpty else {
                leaderboard = []
                lastLoadedTeamId = nil
                emptyStateMessage = "No teams available yet."
                errorMessage = nil
                return
            }

            let leaderboardEntries = try await leaderboardLoader(selectedTeamId)
            applyLeaderboard(entries: leaderboardEntries)
            lastLoadedTeamId = selectedTeamId
            errorMessage = nil
        } catch {
            teams = []
            leaderboard = []
            lastLoadedTeamId = nil
            errorMessage = error.localizedDescription
            emptyStateMessage = "Unable to load teams right now."
        }
    }

    func refreshSelectedTeam() async {
        guard !selectedTeamId.isEmpty else {
            leaderboard = []
            lastLoadedTeamId = nil
            emptyStateMessage = "No teams available yet."
            return
        }

        guard selectedTeamId != lastLoadedTeamId || leaderboard.isEmpty || errorMessage != nil else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let leaderboardEntries = try await leaderboardLoader(selectedTeamId)
            applyLeaderboard(entries: leaderboardEntries)
            lastLoadedTeamId = selectedTeamId
            errorMessage = nil
        } catch {
            leaderboard = []
            errorMessage = error.localizedDescription
            emptyStateMessage = "Unable to load teams right now."
        }
    }

    func sortLeaderboardByScore() {
        leaderboard.sort { left, right in
            if left.score == right.score {
                return left.rank < right.rank
            }
            return left.score > right.score
        }
    }

    private func applyLeaderboard(entries: [LeaderboardEntryResponse]) {
        leaderboard = entries.map {
            LeaderRowData(
                rank: $0.rank,
                name: $0.username,
                score: Int($0.totalDistance.rounded()),
                subtitle: "\($0.totalActivities) rucks"
            )
        }

        let memberCount = selectedTeam?.members?.count ?? 0
        if memberCount == 0 {
            emptyStateMessage = "No members have joined this team yet."
        } else {
            emptyStateMessage = "No tracked rucks for this team yet."
        }
    }
}
