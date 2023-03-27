//
//  ImageProcessingApp.swift
//  ImageProcessing
//
//  Created by Ho Si Tuan on 27/03/2023.
//

import SwiftUI
import ComposableArchitecture

@main
struct ImageProcessingApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                HomeView(
                    store: Store(
                        initialState: Home.State(),
                        reducer: Home()._printChanges()
                    )
                )
            }
        }
    }
}
