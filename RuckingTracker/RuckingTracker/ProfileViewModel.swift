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

class ProfileViewModel: ObservableObject {
    @Published var user: UserModel? = nil
    @Published var stats: [ProfileStat] = []
    
    func loadProfile(user: UserModel, activities: [TrackedActivity]) {
        self.user = user
        
        let totalRucks = activities.count
        let totalMiles = activities.reduce(0) { $0 + $1.distance }
        let prPace = activities.map { $0.pace }.min() ?? 0
        
        stats = [
            ProfileStat(title: "Rucks", value: "\(totalRucks)"),
            ProfileStat(title: "Miles", value: String(format: "%.0f", totalMiles)),
            ProfileStat(title: "PR Pace", value: String(format: "%.2f", prPace))
        ]
    }
}









