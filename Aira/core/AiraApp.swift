//
//  AiraApp.swift
//  Aira
//
//  Created by Gayathri Gondi on 27/06/25.
//

import SwiftUI
/*
@main
struct AiraApp: App {
    @StateObject var authManager = AuthManager()
    @StateObject var animeListVM = AnimeListViewModel()

    init() {
        setupTabBarAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(animeListVM)
                .onOpenURL { url in
                    authManager.handleRedirect(url: url)
                }
        }
    }

    private func setupTabBarAppearance() {
        let pinkColor = UIColor(red: 255/255, green: 133/255, blue: 178/255, alpha: 1)

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = pinkColor
        appearance.stackedLayoutAppearance.normal.iconColor = .white
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
*/
// AiraApp.swift

@main
struct AiraApp: App {
    @StateObject private var animeDataService = AnimeDataService.shared
    @StateObject private var authManager = AuthManager()
    @StateObject private var errorHandler = ErrorHandler()
    @StateObject private var animeListVM = AnimeListViewModel() // Add this
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(animeDataService)
                .environmentObject(authManager)
                .environmentObject(errorHandler)
                .environmentObject(animeListVM) // Add this
                .alert(item: $errorHandler.currentAlert) { alert in
                    Alert(
                        title: Text(alert.title),
                        message: Text(alert.message),
                        dismissButton: alert.dismissButton
                    )
                }
        }
    }
}
