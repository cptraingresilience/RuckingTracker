//
//  ProfileView.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    
    // Replace below with actual logic for user/activities as needed
    let dummyUser = UserModel(name: "SFC Rivera", profileImageName: "person.crop.circle.fill")
    let dummyActivities: [TrackedActivity] = [
        .init(id: UUID(), distance: 247, duration: 3600*12, pace: 11.98, startedAt: Date())
    ]

    var body: some View {
        VStack(spacing: 22) {
            HeaderView(title: "Profile", systemIcon: "person.circle.fill")
                .padding(.bottom, 8)
            // Profile Header
            VStack(spacing: 10) {
                Image(systemName: dummyUser.profileImageName)
                    .resizable()
                    .frame(width: 90, height: 90)
                    .foregroundColor(.white)
                Text(dummyUser.name)
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                Text("ODA 555 | Ruck Team Leader")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }
            .padding(.top)

            Divider()
            
            // Stats
            HStack(spacing: 26) {
                ForEach(viewModel.stats) { stat in
                    MetricCardView(title: stat.title, value: stat.value, unit: nil)
                }
            }
            Spacer()
        }
        .background(Color(UIColor.systemGray5).edgesIgnoringSafeArea(.all))
        .onAppear {
            viewModel.loadProfile(user: dummyUser, activities: dummyActivities)
        }
        .padding()
    }
}

