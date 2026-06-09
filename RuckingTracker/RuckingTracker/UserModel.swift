//
//  UserModel.swift
//  Rux
//
//  Created by Picos on 11/11/25.
//
import Foundation

// MARK: - Models
struct UserModel: Identifiable {
    let id = UUID()
    let name: String
    let profileImageName: String
}
