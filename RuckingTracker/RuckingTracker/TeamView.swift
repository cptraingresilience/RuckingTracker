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

            if !viewModel.teams.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Select Team", selection: $viewModel.selectedTeamId) {
                        ForEach(viewModel.teams) { team in
                            Text(team.name)
                                .tag(team.id)
                        }
                    }
                    .pickerStyle(.menu)

                    if !viewModel.selectedTeamSummary.isEmpty {
                        Text(viewModel.selectedTeamSummary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
            }

            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading leaderboard...")
                Spacer()
            } else if let errorMessage = viewModel.errorMessage {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 36))
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task { await viewModel.loadTeamData() }
                    }
                }
                .padding(.horizontal)
                Spacer()
            } else if viewModel.leaderboard.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "person.3.sequence.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text(viewModel.emptyStateMessage)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            } else {
                VStack(spacing: 16) {
                    ForEach(viewModel.leaderboard) { row in
                        LeaderRowView(row: row)
                    }
                }
                Spacer()
            }
        }
        .padding()
        .onChange(of: viewModel.selectedTeamId) { newTeamId in
            guard !newTeamId.isEmpty else { return }
            Task {
                await viewModel.refreshSelectedTeam()
            }
        }
    }
}
