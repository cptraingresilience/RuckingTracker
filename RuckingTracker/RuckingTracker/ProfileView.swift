//
//  ProfileView.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var loginViewModel: LoginViewModel
    @State private var showSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                ZStack(alignment: .topTrailing) {
                    HeaderView(title: "Profile", systemIcon: "person.circle.fill")

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                            .padding(8)
                    }
                    .accessibilityLabel("Settings")
                }
                .padding(.bottom, 8)

                VStack(spacing: 10) {
                    Image(systemName: viewModel.user?.profileImageName ?? "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 90, height: 90)
                        .foregroundColor(.white)
                        .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                        .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 4)
                    Text(viewModel.user?.name ?? "Profile")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    if !viewModel.subtitle.isEmpty {
                        Text(viewModel.subtitle)
                            .foregroundColor(.white.opacity(0.75))
                            .font(.subheadline)
                    }

                    if !viewModel.statusMessage.isEmpty {
                        Text(viewModel.statusMessage)
                            .foregroundColor(.white.opacity(0.7))
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(viewModel.stats) { stat in
                        MetricCardView(title: stat.title, value: stat.value, unit: nil)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Latest Ruck")
                        .font(.headline)
                        .foregroundColor(.white)

                    if let activity = viewModel.latestActivity {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(activity.title.isEmpty ? "Untitled ruck" : activity.title)
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            Text(activity.startedAt.formattedShort())
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))

                            HStack {
                                Label("\(activity.distanceText) mi", systemImage: "figure.walk")
                                Spacer()
                                Label(activity.timeText, systemImage: "clock")
                                Spacer()
                                Label("\(activity.paceText) min/mi", systemImage: "speedometer")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))

                            if !activity.notes.isEmpty {
                                Text(activity.notes)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.ultraThinMaterial)
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.black.opacity(0.20))
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 4)
                    } else {
                        Text("No rucks logged yet. Your next saved activity will show up here.")
                            .foregroundColor(.white.opacity(0.75))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(.ultraThinMaterial)
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.black.opacity(0.20))
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                }

                Spacer(minLength: 0)
            }
            .padding()
        }
        .ruxBackground()
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(loginViewModel)
        }
        .onAppear {
            viewModel.refresh()
        }
    }
}