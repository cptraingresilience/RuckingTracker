//
//  TabViewMain.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import SwiftUI

struct TabViewMain: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MapView()
                .tabItem {
                    Label("Maps", systemImage: "globe.europe.africa.fill")
                }.tag(0)
            LogView()
                .tabItem {
                    Label("Log", systemImage: "chart.bar.fill")
                }.tag(1)
            TeamView()
                .tabItem {
                    Label("Team", systemImage: "person.3.fill")
                }.tag(2)
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }.tag(3)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }.tag(4)
        }
    }
}


