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
}

class TeamViewModel: ObservableObject {
    @Published var selectedGroup: String = "TX Special Forces Mentorship"
    @Published var groups: [String] = [
        "ODA 555",
        "TX Special Forces Mentorship",
        "Drinking Crew",
        "Go Ruck Friends"
    ]
    @Published var leaderboard: [LeaderRowData] = [
        LeaderRowData(rank: 1, name: "SFC Rivera", score: 178),
        LeaderRowData(rank: 2, name: "SSG Torres", score: 163),
        LeaderRowData(rank: 3, name: "SGT Yeager", score: 148),
        LeaderRowData(rank: 4, name: "SPC Jones", score: 134)
    ]
    
    // Add functions to load/sort leaderboard data as needed, e.g. from network or ActivityStore
}
