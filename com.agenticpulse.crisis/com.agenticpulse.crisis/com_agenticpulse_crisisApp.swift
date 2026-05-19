//
//  com_agenticpulse_crisisApp.swift
//  com.agenticpulse.crisis
//
//  Created by Apple on 17/05/2026.
//

import SwiftUI
#if canImport(GoogleMaps)
import GoogleMaps
#endif

@main
struct com_agenticpulse_crisisApp: App {
    @StateObject private var appModel = AppModel()

    init() {
        #if canImport(GoogleMaps)
        if let key = AppConfig.shared.googleMapsAPIKey {
            GMSServices.provideAPIKey(key)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appModel)
                .preferredColorScheme(.light)
        }
    }
}
