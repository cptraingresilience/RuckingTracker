//
//  TeamView.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import SwiftUI
import Combine

struct TeamView: View {
    @StateObject private var viewModel = TeamViewModel()

    var body: some View {
        VStack(spacing: 18) {
            HeaderView(title: "Team Leaderboard", systemIcon: "person.3.fill")
                .padding(.bottom, 8)

            Picker("Select Group", selection: $viewModel.selectedGroup) {
                ForEach(viewModel.groups, id: \.self) { group in
                    Text(group)
                        .tag(group)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            VStack(spacing: 16) {
                ForEach(viewModel.leaderboard) { row in
                    LeaderRowView(row: row)
                }
            }
            Spacer()
        }
        .padding()
    }
}

