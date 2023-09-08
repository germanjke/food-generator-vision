//
//  Diffusion_macOSApp.swift
//  Diffusion-macOS
//
//  Created by German Abramov on 20/08/23.


import SwiftUI

@main
struct Diffusion_macOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white, Color.mint]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .edgesIgnoringSafeArea(.all)
                            )
        }
    }
}
