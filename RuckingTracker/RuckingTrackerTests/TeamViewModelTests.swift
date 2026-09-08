//
//  TeamViewModelTests.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import XCTest
@testable import RuckingTracker

class TeamViewModelTests: XCTestCase {
    var viewModel: TeamViewModel!

    override func setUp() {
        super.setUp()
        viewModel = TeamViewModel()
        viewModel.leaderboard = [
            LeaderRowData(rank: 1, name: "Alpha", score: 150),
            LeaderRowData(rank: 2, name: "Bravo", score: 100)
        ]
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testInitialSelectedGroup() {
        XCTAssertFalse(viewModel.selectedGroup.isEmpty)
    }

    func testSortLeaderboardByScore() {
        viewModel.leaderboard.append(LeaderRowData(rank: 3, name: "Charlie", score: 200))
        viewModel.sortLeaderboardByScore()
        XCTAssertEqual(viewModel.leaderboard.first?.score, 200)
    }
}

