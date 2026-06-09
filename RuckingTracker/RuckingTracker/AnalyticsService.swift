//
//  AnalyticsService.swift
//  Rux
//
//  Created by Picos on 11/11/25.
//

import Foundation
import FirebaseAnalytics

class AnalyticsService {
    static let shared = AnalyticsService()

    private init() {}

    /// Logs a simple event with optional parameters.
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        #if DEBUG
        print("Analytics Debug - Event: \(name), Parameters: \(parameters ?? [:])")
        #endif
        Analytics.logEvent(name, parameters: parameters)
    }

    /// Tracks when a user completes an activity (custom helper)
    func trackActivityCompleted(activityID: String, distance: Double, duration: TimeInterval) {
        logEvent("activity_completed", parameters: [
            "activity_id": activityID,
            "distance": distance,
            "duration": duration
        ])
    }

    /// Tracks when a user views a screen.
    func trackScreenView(screenName: String) {
        logEvent("screen_view", parameters: [
            "screen_name": screenName
        ])
    }

    /// Tracks when a user taps a button (custom helper)
    func trackButtonTap(buttonName: String) {
        logEvent("button_tap", parameters: [
            "button_name": buttonName
        ])
    }
}

