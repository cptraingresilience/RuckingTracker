//
//  TeamViewModelTests.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import XCTest
@testable import RuckingTracker

@MainActor
class TeamViewModelTests: XCTestCase {
    var viewModel: TeamViewModel!

    override func setUp() {
        super.setUp()
        viewModel = TeamViewModel(
            teamsLoader: {
                [
                    TeamResponse(id: "team-alpha", name: "Alpha", members: ["u1", "u2"]),
                    TeamResponse(id: "team-bravo", name: "Bravo", members: ["u3"])
                ]
            },
            leaderboardLoader: { teamId in
                switch teamId {
                case "team-alpha":
                    return [
                        LeaderboardEntryResponse(rank: 1, username: "Alpha One", totalDistance: 150, totalActivities: 4)
                    ]
                case "team-bravo":
                    return [
                        LeaderboardEntryResponse(rank: 1, username: "Bravo One", totalDistance: 90, totalActivities: 2)
                    ]
                default:
                    return []
                }
            }
        )
        viewModel.leaderboard = [
            LeaderRowData(rank: 1, name: "Alpha", score: 150),
            LeaderRowData(rank: 2, name: "Bravo", score: 100)
        ]
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testInitialSelectedTeamAfterLoad() async {
        await viewModel.loadTeamData()

        XCTAssertEqual(viewModel.selectedTeamId, "team-alpha")
        XCTAssertEqual(viewModel.selectedTeam?.name, "Alpha")
        XCTAssertEqual(viewModel.leaderboard.first?.name, "Alpha One")
    }

    func testRefreshingAfterTeamSelectionLoadsDifferentLeaderboard() async {
        await viewModel.loadTeamData()
        viewModel.selectedTeamId = "team-bravo"

        await viewModel.refreshSelectedTeam()

        XCTAssertEqual(viewModel.leaderboard.first?.name, "Bravo One")
    }

    func testSortLeaderboardByScore() {
        viewModel.leaderboard.append(LeaderRowData(rank: 3, name: "Charlie", score: 200))
        viewModel.sortLeaderboardByScore()
        XCTAssertEqual(viewModel.leaderboard.first?.score, 200)
    }
}
