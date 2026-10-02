//
//  TabViewMain.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//  Redesigned 10.1.26 — Home feed + orange accent.
//
//  Note: UserModel and ActivityModel live in their own files.
//

import SwiftUI

// MARK: - Sample Data
extension Date {
    static func from(year: Int, month: Int, day: Int, hour: Int = 8, minute: Int = 0) -> Date {
        var dc = DateComponents()
        dc.year = year; dc.month = month; dc.day = day; dc.hour = hour; dc.minute = minute
        return Calendar.current.date(from: dc) ?? Date()
    }
}

let sampleUser = UserModel(name: "Justin A", profileImageName: "SampleProfile1")
let friendAlex = UserModel(name: "Sunny", profileImageName: "SampleProfile2")
let friendMaya = UserModel(name: "SFC Negron", profileImageName: "SampleProfile3")

let sampleActivities: [ActivityModel] = [
    ActivityModel(user: sampleUser, isRuck: true,
                  date: .from(year: 2025, month: 10, day: 29, hour: 6, minute: 15),
                  locationText: "South Austin Trail",
                  title: "Pre-dawn Ruck: Hills & Intervals",
                  distanceText: "12.5 mi", timeText: "2:30:00", paceText: "11:26 /mi",
                  mapImageName: "MapSample1"),
    ActivityModel(user: friendAlex, isRuck: false,
                  date: .from(year: 2025, month: 10, day: 28, hour: 18, minute: 5),
                  locationText: "Old San Juan",
                  title: "Evening Tempo Run",
                  distanceText: "5.1 mi", timeText: "0:42:15", paceText: "8:18 /mi",
                  mapImageName: "MapSample2"),
    ActivityModel(user: friendMaya, isRuck: false,
                  date: .from(year: 2025, month: 10, day: 26, hour: 7, minute: 0),
                  locationText: "Riverfront",
                  title: "Hike & Bike Trail",
                  distanceText: "3.8 mi", timeText: "0:31:10", paceText: "8:12 /mi",
                  mapImageName: "MapSample3")
]

// MARK: - Main TabView
struct TabViewMain: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(activities: sampleActivities)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            MapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(1)

            LogView()
                .tabItem {
                    Label("Log", systemImage: "doc.fill")
                }
                .tag(2)

            TeamView()
                .tabItem {
                    Label("Team", systemImage: "person.2.fill")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
        .accentColor(.orange)
    }
}

// MARK: - HomeView
struct HomeView: View {
    let activities: [ActivityModel]
    @State private var commentsByActivity: [UUID: [String]] = [:]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background image fills screen and ignores safe area
                Image("Background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()
                    .opacity(0.85)
                    .saturation(1.15)

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Image("ArrowHeadLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                        Image("RuxLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 48)

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 40)

                    // ScrollView for activities
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 14) {
                            ForEach(activities) { act in
                                ActivityCardDetailed(
                                    activity: act,
                                    comments: Binding(
                                        get: { commentsByActivity[act.id] ?? [] },
                                        set: { commentsByActivity[act.id] = $0 }
                                    )
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 110)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Activity Card Detailed
struct ActivityCardDetailed: View {
    let activity: ActivityModel
    @Binding var comments: [String]
    @State private var isLiked = false
    @State private var showCommentSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: profile + name
            HStack {
                Image(activity.user.profileImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))

                Text(activity.user.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .foregroundColor(.orange)
                        .padding(8)
                }
            }

            // Subheading
            HStack(spacing: 8) {
                Image(systemName: activity.isRuck ? "shoeprints.fill" : "figure.run")
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(shortDateString(activity.date)) • \(shortTimeString(activity.date))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                    Text(activity.locationText)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
            }

            Text(activity.title)
                .font(.headline)
                .foregroundColor(.white)

            // Metrics row
            HStack {
                metricBlock(title: "DISTANCE", value: activity.distanceText)
                Divider().frame(height: 36).background(Color.white.opacity(0.12))
                metricBlock(title: "TIME", value: activity.timeText)
                Divider().frame(height: 36).background(Color.white.opacity(0.12))
                metricBlock(title: "AVG PACE", value: activity.paceText)
            }

            // Map snapshot
            Image(activity.mapImageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 220)
                .clipped()
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.06), lineWidth: 1))

            // Actions
            HStack(spacing: 22) {
                Button(action: { isLiked.toggle() }) {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                        Text("Like")
                    }
                }
                .foregroundColor(isLiked ? .orange : .white)

                Button(action: { showCommentSheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                        Text(comments.isEmpty ? "Comment" : "Comment (\(comments.count))")
                    }
                }
                .foregroundColor(.white)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                }
                .foregroundColor(.white)
            }
            .padding(.top, 6)

            // Posted comments
            if !comments.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Divider().background(Color.white.opacity(0.12))
                    ForEach(Array(comments.enumerated()), id: \.offset) { _, comment in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "bubble.right.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                                .padding(.top, 3)
                            Text(comment)
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.95))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(BlurAndCardBackground())
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 6)
        .sheet(isPresented: $showCommentSheet) {
            CommentSheet(activityTitle: activity.title) { newComment in
                comments.append(newComment)
            }
        }
    }

    private func metricBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.9))
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func shortDateString(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: d)
    }

    private func shortTimeString(_ d: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: d)
    }
}

// MARK: - Comment Sheet
struct CommentSheet: View {
    let activityTitle: String
    var onSubmit: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var isFocused: Bool

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Comment")
                .font(.headline)
                .foregroundColor(.white)

            Text(activityTitle)
                .font(.caption)
                .foregroundColor(.white.opacity(0.75))
                .lineLimit(1)

            TextField("Share something...", text: $text, axis: .vertical)
                .lineLimit(3...6)
                .padding(12)
                .background(Color.white.opacity(0.10))
                .cornerRadius(10)
                .foregroundColor(.white)
                .tint(.orange)
                .focused($isFocused)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.white.opacity(0.9))

                Spacer()

                Button {
                    onSubmit(trimmedText)
                    dismiss()
                } label: {
                    Text("Submit")
                        .fontWeight(.semibold)
                        .foregroundColor(trimmedText.isEmpty ? .white.opacity(0.35) : .orange)
                }
                .disabled(trimmedText.isEmpty)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
        .presentationBackground {
            // Frosted dark-blue treatment to match the activity cards
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Color.blue.opacity(0.12)
                Color.black.opacity(0.35)
            }
        }
        .onAppear { isFocused = true }
    }
}

// MARK: - Card background
struct BlurAndCardBackground: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.20)
            VisualEffectBlur(blurStyle: .systemThinMaterialDark)
                .opacity(0.4)
        }
    }
}

// MARK: - VisualEffectBlur
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView { UIVisualEffectView(effect: UIBlurEffect(style: blurStyle)) }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - Preview
struct TabViewMain_Previews: PreviewProvider {
    static var previews: some View {
        TabViewMain()
            .environmentObject(LoginViewModel())
    }
}


