//
//  SettingsViewModel.swift
//  Rux
//
//  Created by Picos on 11/11/25.
//

import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled: Bool {
        didSet { saveSetting("notificationsEnabled", notificationsEnabled) }
    }
    @Published var darkModeEnabled: Bool {
        didSet { saveSetting("darkModeEnabled", darkModeEnabled) }
    }
    @Published var selectedUnits: String {
        didSet { saveSetting("selectedUnits", selectedUnits) }
    }
    
    init() {
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        self.darkModeEnabled = UserDefaults.standard.bool(forKey: "darkModeEnabled")
        self.selectedUnits = UserDefaults.standard.string(forKey: "selectedUnits") ?? "Imperial"
    }
    
    private func saveSetting(_ key: String, _ value: Any) {
        UserDefaults.standard.set(value, forKey: key)
    }
}

