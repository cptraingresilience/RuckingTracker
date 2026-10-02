//
//  MapView.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//  Rebuilt 10.2.26 on Mapbox — full-bleed map with live route tracking.
//

import SwiftUI
import CoreLocation
import MapboxMaps
import SceneKit

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewport: Viewport = .followPuck(zoom: 15)
    @State private var showStartAnimation = false

    /// Custom Rux style published from Mapbox Studio.
    private static let ruxStyleURI = StyleURI(rawValue: "mapbox://styles/cptrainingresilience/cmi54pmjl00pp01s1b28x5rcp")!

    private var routeCoordinates: [CLLocationCoordinate2D] {
        viewModel.route.map(\.coordinate)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Layer 1: the map
            Map(viewport: $viewport) {
                Puck2D(bearing: .heading)

                if routeCoordinates.count > 1 {
                    PolylineAnnotation(lineCoordinates: routeCoordinates)
                        .lineColor(StyleColor(UIColor.orange))
                        .lineWidth(4)
                        .lineOpacity(0.9)
                }
            }
            .mapStyle(MapStyle(uri: Self.ruxStyleURI))
            .ignoresSafeArea()

            // Floating controls
            VStack(spacing: 10) {
                if viewModel.isTracking {
                    HStack(spacing: 12) {
                        ForEach(viewModel.liveMetrics, id: \.kind) { metric in
                            statChip(metric.value)
                        }
                    }
                }

                if let statusMessage = viewModel.statusMessage {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                }

                if viewModel.showSaveActivity, let activity = viewModel.currentActivity {
                    Text("Saved: \(String(format: "%.2f", activity.distance)) mi in \(Int(activity.duration / 60)) min")
                        .font(.footnote.bold())
                        .foregroundColor(.green)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                }

                if viewModel.isTracking {
                    HStack(spacing: 12) {
                        // Pause / Resume
                        Button {
                            if viewModel.isPaused {
                                viewModel.resumeSession()
                            } else {
                                viewModel.pauseSession()
                            }
                        } label: {
                            Label(
                                viewModel.isPaused ? "Resume" : "Pause",
                                systemImage: viewModel.isPaused ? "play.fill" : "pause.fill"
                            )
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(viewModel.isPaused ? Color.green : Color.orange, in: Capsule())
                        }

                        // Stop & review
                        Button {
                            viewModel.stopSession()
                        } label: {
                            Label("Stop", systemImage: "stop.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(Color.red, in: Capsule())
                        }
                    }
                } else {
                    Button {
                        if viewModel.isLocationAuthorized {
                            // Play the 3D intro, then begin the session on completion.
                            withAnimation { showStartAnimation = true }
                        } else {
                            // Not authorized yet — tap requests permission.
                            viewModel.startSession()
                        }
                    } label: {
                        Label(
                            viewModel.isLocationAuthorized ? "Start Ruck" : viewModel.permissionButtonTitle,
                            systemImage: "figure.walk"
                        )
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(viewModel.isLocationAuthorized ? Color.orange : Color.blue, in: Capsule())
                    }
                }
            }
            .padding(.bottom, 150) // clear the tab bar + collapsed metrics drawer
            .shadow(color: .black.opacity(0.35), radius: 6, y: 3)

            // Pull-up metrics drawer (custom overlay so Start stays reachable)
            MetricsDrawerView(viewModel: viewModel)

            // 3D Start-Ruck animation (blocks until it finishes, then starts tracking)
            if showStartAnimation {
                StartRuckAnimationView {
                    showStartAnimation = false
                    viewModel.startSession()
                    viewport = .followPuck(zoom: 15)
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .onAppear {
            // Warm the 3D model off the main thread so tapping Start never hitches.
            ModelSceneCache.shared.preload("QuadNodsNoHelmet")
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                viewModel.handleAppMovedToBackground()
            }
        }
        .sheet(isPresented: $viewModel.isReviewing) {
            if let draft = viewModel.draftActivity {
                RuckSummarySheet(
                    activity: draft,
                    onSave: { title, notes, rpe in
                        viewModel.saveReviewedSession(title: title, notes: notes, rpe: rpe)
                    },
                    onDiscard: {
                        viewModel.discardSession()
                    }
                )
            }
        }
    }

    private func statChip(_ value: String) -> some View {
        Text(value)
            .font(.subheadline.bold())
            .monospacedDigit()
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
    }

    /// Formats elapsed seconds as H:MM:SS (or M:SS under an hour).
    static func timeString(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}

// MARK: - Metrics pull-up drawer
/// Custom draggable overlay anchored to the bottom of the map. Collapsed it shows a
/// grab handle + label; expanded it reveals metric toggles and the Ruck Weight control.
/// Built as an overlay (not a sheet) so the Start/Stop controls stay reachable.
struct MetricsDrawerView: View {
    @ObservedObject var viewModel: MapViewModel

    @State private var isExpanded = false
    @GestureState private var dragOffset: CGFloat = 0

    // Layout constants
    private let expandedHeight: CGFloat = 430
    private let peekHeight: CGFloat = 56      // visible sliver above the tab bar when collapsed
    private let tabBarClearance: CGFloat = 84 // bottom zone covered by the tab bar

    private var collapsedOffset: CGFloat { expandedHeight - (peekHeight + tabBarClearance) }

    private var currentOffset: CGFloat {
        let base = isExpanded ? 0 : collapsedOffset
        // Rubber-band: follow the finger but clamp within bounds.
        return min(max(base + dragOffset, 0), collapsedOffset)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Grab handle + title (always visible — the drag/tap target)
            VStack(spacing: 6) {
                Capsule()
                    .fill(Color.white.opacity(0.45))
                    .frame(width: 44, height: 5)
                    .padding(.top, 10)
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.blue.opacity(0.8))
                    Text("Metrics")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isExpanded.toggle()
                }
            }

            Divider().background(Color.white.opacity(0.15))

            // Toggle list
            VStack(spacing: 4) {
                ForEach(MetricKind.allCases) { kind in
                    HStack(spacing: 12) {
                        Image(systemName: kind.systemImage)
                            .foregroundColor(.orange)
                            .frame(width: 26)
                        Text(kind.title)
                            .foregroundColor(.white)
                        if !kind.unit.isEmpty {
                            Text(kind.unit)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { viewModel.selectedMetrics.contains(kind) },
                            set: { isOn in
                                if isOn {
                                    viewModel.selectedMetrics.insert(kind)
                                } else {
                                    viewModel.selectedMetrics.remove(kind)
                                }
                            }
                        ))
                        .labelsHidden()
                        .tint(.orange)
                        .disabled(viewModel.isTracking)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }

                // Ruck Weight control
                HStack(spacing: 12) {
                    Image(systemName: "scalemass")
                        .foregroundColor(.orange)
                        .frame(width: 26)
                    Text("Weight")
                        .foregroundColor(.white)
                    Spacer()
                    Stepper(
                        value: $viewModel.ruckWeight,
                        in: 0...200,
                        step: 5
                    ) {
                        Text(viewModel.ruckWeight > 0 ? String(format: "%.0f lb", viewModel.ruckWeight) : "None")
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundColor(.white)
                            .frame(minWidth: 56, alignment: .trailing)
                    }
                    .disabled(viewModel.isTracking)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

                if viewModel.isTracking {
                    Text("Loadout is locked while a ruck is in progress.")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.55))
                        .padding(.top, 2)
                }
            }
            .padding(.top, 6)

            Spacer(minLength: 0)
        }
        .frame(height: expandedHeight, alignment: .top)
        .frame(maxWidth: .infinity)
        .background(
            // Frosted gradient to match the app's card language
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(.ultraThinMaterial)
                LinearGradient(
                    colors: [Color.gray.opacity(0.18), Color.black.opacity(0.30)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 22))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 10, y: -4)
        .offset(y: currentOffset)
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation.height
                }
                .onEnded { value in
                    let threshold: CGFloat = 60
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        if isExpanded {
                            if value.translation.height > threshold { isExpanded = false }
                        } else {
                            if value.translation.height < -threshold { isExpanded = true }
                        }
                    }
                }
        )
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Ruck Summary review sheet
/// Shown after Stop. Lets the user name the ruck, rate exertion (RPE), add notes,
/// then Save (persist + sync) or Discard. Ruck Weight is intentionally omitted here —
/// it will live in the upcoming adjustable metrics drawer.
struct RuckSummarySheet: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var activity: TrackedActivity
    var onSave: (_ title: String, _ notes: String, _ rpe: Int?) -> Void
    var onDiscard: () -> Void

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var rpe: Int = 5
    @State private var rpeEnabled: Bool = true

    var body: some View {
        ZStack {
            // Frosted dark-blue backdrop to match the activity cards / comment sheet.
            Color.black.opacity(0.25).ignoresSafeArea()
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            Color.blue.opacity(0.12).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Ruck Complete")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(.top, 8)

                    // Read-only metrics summary
                    HStack {
                        metric("DISTANCE", String(format: "%.2f mi", activity.distance))
                        Divider().frame(height: 40).background(Color.white.opacity(0.15))
                        metric("TIME", MapView.timeString(activity.duration))
                        Divider().frame(height: 40).background(Color.white.opacity(0.15))
                        metric("PACE", String(format: "%.1f /mi", activity.pace))
                        Divider().frame(height: 40).background(Color.white.opacity(0.15))
                        metric("SPEED", String(format: "%.1f mph", activity.averageSpeedMph))
                    }
                    .padding(.vertical, 8)

                    // Title
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TITLE").font(.caption).foregroundColor(.white.opacity(0.7))
                        TextField("Name this ruck", text: $title)
                            .textInputAutocapitalization(.words)
                            .padding(12)
                            .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                            .foregroundColor(.white)
                    }

                    // RPE 1–10
                    VStack(alignment: .leading, spacing: 6) {
                        Toggle(isOn: $rpeEnabled) {
                            Text("RATE OF PERCEIVED EXERTION")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .tint(.orange)

                        if rpeEnabled {
                            HStack {
                                Text("\(rpe)")
                                    .font(.title3.bold().monospacedDigit())
                                    .foregroundColor(.orange)
                                    .frame(width: 34, alignment: .leading)
                                Slider(value: Binding(
                                    get: { Double(rpe) },
                                    set: { rpe = Int($0.rounded()) }
                                ), in: 1...10, step: 1)
                                .tint(.orange)
                            }
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NOTES").font(.caption).foregroundColor(.white.opacity(0.7))
                        TextField("How did it go?", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(12)
                            .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                            .foregroundColor(.white)
                    }

                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            onSave(title, notes, rpeEnabled ? rpe : nil)
                            dismiss()
                        } label: {
                            Text("Save Ruck")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange, in: Capsule())
                        }

                        Button(role: .destructive) {
                            onDiscard()
                            dismiss()
                        } label: {
                            Text("Discard")
                                .font(.subheadline.bold())
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(20)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(true) // force an explicit Save/Discard choice
        .onAppear {
            title = activity.title
            notes = activity.notes
            if let existing = activity.rpe { rpe = existing }
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundColor(.white.opacity(0.6))
            Text(value).font(.subheadline.bold()).foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Start Ruck 3D Animation
struct StartRuckAnimationView: View {
    /// Called once the full drop → spin → retreat sequence finishes.
    var onComplete: () -> Void

    @State private var verticalOffset: CGFloat = -700
    @State private var modelOpacity: Double = 0

    // Sequence timing (seconds)
    private let dropDuration = 0.6
    private let holdDuration = 1.0
    private let retreatDuration = 0.6

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            SpinningModelView(modelName: "QuadNodsNoHelmet", spinDuration: 1.2)
                .frame(width: 240, height: 240)
                .offset(y: verticalOffset)
                .opacity(modelOpacity)
        }
        .onAppear(perform: runSequence)
    }

    private func runSequence() {
        // 1. Drop in from above (model spins continuously via SceneKit)
        withAnimation(.easeOut(duration: dropDuration)) {
            verticalOffset = 0
            modelOpacity = 1
        }

        // Impact haptic at landing
        DispatchQueue.main.asyncAfter(deadline: .now() + dropDuration) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }

        // 2. Retreat back up the way it came, after the hold
        withAnimation(.easeIn(duration: retreatDuration).delay(dropDuration + holdDuration)) {
            verticalOffset = -700
            modelOpacity = 0
        }

        // 3. Hand off to the session
        let total = dropDuration + holdDuration + retreatDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + total) {
            onComplete()
        }
    }
}

// MARK: - USDZ scene preloader / cache
/// Loads and caches heavy USDZ scenes off the main thread so first use is instant.
/// Thread-safe via a serial queue; all cache access funnels through it.
final class ModelSceneCache {
    static let shared = ModelSceneCache()

    private var cache: [String: SCNScene] = [:]
    private let queue = DispatchQueue(label: "com.rux.model.preload", qos: .userInitiated)

    private init() {}

    /// Decode and cache a USDZ in the background. Safe to call repeatedly (no-op once cached).
    func preload(_ name: String) {
        queue.async { [weak self] in
            guard let self, self.cache[name] == nil else { return }
            guard let url = Bundle.main.url(forResource: name, withExtension: "usdz"),
                  let scene = try? SCNScene(url: url, options: nil) else { return }
            self.cache[name] = scene
        }
    }

    /// Returns the cached scene, loading synchronously as a fallback if preload hasn't finished.
    func scene(_ name: String) -> SCNScene? {
        queue.sync {
            if let cached = cache[name] { return cached }
            guard let url = Bundle.main.url(forResource: name, withExtension: "usdz"),
                  let scene = try? SCNScene(url: url, options: nil) else { return nil }
            cache[name] = scene
            return scene
        }
    }
}

// MARK: - SceneKit USDZ spinner
struct SpinningModelView: UIViewRepresentable {
    let modelName: String
    var spinDuration: Double = 1.2

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.autoenablesDefaultLighting = true
        scnView.antialiasingMode = .multisampling4X
        scnView.allowsCameraControl = true       // auto-frames the model
        scnView.isUserInteractionEnabled = false  // but no stray drags during the intro

        // Pull from the preloaded cache; clone the node tree so we never mutate the cached copy.
        guard let cachedScene = ModelSceneCache.shared.scene(modelName) else {
            return scnView
        }

        let scene = SCNScene()
        let spinContainer = SCNNode()
        for child in cachedScene.rootNode.childNodes {
            spinContainer.addChildNode(child.clone())
        }
        scene.rootNode.addChildNode(spinContainer)

        spinContainer.runAction(
            .repeatForever(.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: spinDuration))
        )

        scnView.scene = scene
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
}
