//
//  ActivityModel.swift
//  Rux
//
//  Created by Picos on 11/11/25.
//

import Foundation

struct ActivityModel: Identifiable {
    let id = UUID()
    let user: UserModel
    let isRuck: Bool
    let date: Date
    let locationText: String
    let title: String
    let distanceText: String
    let timeText: String
    let paceText: String
    let mapImageName: String
}
