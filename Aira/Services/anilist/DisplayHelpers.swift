//
//  DisplayHelpers.swift
//  Aira
//
//  Created by Gayathri Gondi on 28/06/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var animeListVM: AnimeListViewModel
    init(){
        let pinkColor = UIColor(red: 255/255, green: 133/255, blue: 178/255, alpha: 1)

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = pinkColor
        appearance.stackedLayoutAppearance.normal.iconColor = .white
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    var body: some View {
        ZStack {AppColors.accent.ignoresSafeArea()

            TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                AnimeListView()
                    .tabItem {
                        Label("Anime", systemImage: "film.fill")
                    }

                AnimeSearchView()
                    .environmentObject(animeListVM) // ✅ Shared ViewModel injected
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            .accentColor(AppColors.background)
        }
    }
}

/// A semi-transparent overlay with a loading indicator and "Logging in..." text.
/// Used when the app is in the process of authenticating the user.
struct LoggingInView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4) // 🔲 Background overlay to dim the screen.
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView() // ⏳ Native loading spinner.
                    .scaleEffect(1.5) // Enlarged spinner.
                Text("Logging in...") // 📝 Status message.
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.black.opacity(0.6)) // 🎨 Slightly darker box around the loader.
            .cornerRadius(12) // 🔵 Rounded corners.
        }
    }
}
