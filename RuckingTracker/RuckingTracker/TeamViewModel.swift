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
class TeamViewModel: ObservableObject {
    @Published var selectedGroup: String = "ODA 555"
    @Published var groups: [String] = [
        "ODA 555",
        "TX Special Forces Mentorship",
        "Drinking Crew",
        "Go Ruck Friends"
    ]
    @Published var leaderboard: [LeaderRowData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    private static let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    init() {
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
            async let teamsTask = APIClient.shared.getTeams()
            async let leaderboardTask = APIClient.shared.getLeaderboard()

            let (teams, leaderboardEntries) = try await (teamsTask, leaderboardTask)
            groups = teams.map(\.name)

            if selectedGroup.isEmpty || !groups.contains(selectedGroup) {
                selectedGroup = groups.first ?? ""
            }

            leaderboard = leaderboardEntries.map {
                LeaderRowData(
                    rank: $0.rank,
                    name: $0.username,
                    score: Int($0.totalDistance.rounded()),
                    subtitle: "\($0.totalActivities) rucks"
                )
            }
            sortLeaderboardByScore()
            errorMessage = nil
        } catch {
            leaderboard = []
            errorMessage = error.localizedDescription
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
}
