//
//  ProfileView.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                HeaderView(title: "Profile", systemIcon: "person.circle.fill")
                    .padding(.bottom, 8)

                VStack(spacing: 10) {
                    Image(systemName: viewModel.user?.profileImageName ?? "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 90, height: 90)
                        .foregroundColor(.white)
                    Text(viewModel.user?.name ?? "Profile")
                        .font(.title2.bold())
                        .foregroundColor(.primary)

                    if !viewModel.subtitle.isEmpty {
                        Text(viewModel.subtitle)
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }

                    if !viewModel.statusMessage.isEmpty {
                        Text(viewModel.statusMessage)
                            .foregroundColor(.secondary)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top)

                Divider()

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(viewModel.stats) { stat in
                        MetricCardView(title: stat.title, value: stat.value, unit: nil)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Latest Ruck")
                        .font(.headline)

                    if let activity = viewModel.latestActivity {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(activity.title.isEmpty ? "Untitled ruck" : activity.title)
                                .font(.title3.bold())
                            Text(activity.startedAt.formattedShort())
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack {
                                Label("\(activity.distanceText) mi", systemImage: "figure.walk")
                                Spacer()
                                Label(activity.timeText, systemImage: "clock")
                                Spacer()
                                Label("\(activity.paceText) min/mi", systemImage: "speedometer")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                            if !activity.notes.isEmpty {
                                Text(activity.notes)
                                    .font(.body)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                    } else {
                        Text("No rucks logged yet. Your next saved activity will show up here.")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(12)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding()
        }
        .background(Color(UIColor.systemGray5).edgesIgnoringSafeArea(.all))
        .onAppear {
            viewModel.refresh()
        }
    }
}
