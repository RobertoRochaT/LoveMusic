//
//  LoveMusicApp.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 08/06/25.
//

import SwiftUI
import FirebaseCore

@main
struct RadioWorldApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

