import SwiftUI


import SwiftUI

/// Main entry view for the app. Handles login, loading state, and displays either login screen or anime list.
struct ContentView: View {
    @StateObject private var animeListVM = AnimeListViewModel()
    @EnvironmentObject var authManager: AuthManager
    @State private var showAnimeList = false
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                // ✅ Show anime list if token is valid and list is ready
                if let token = authManager.accessToken, !isTokenExpired(token) {
                    if showAnimeList {
                        MainTabView()
                            .environmentObject(animeListVM)
                    } else {
                        LoggingInView()
                    }
                } else {
                    // ✅ Show login screen if no token or expired
                    loginView
                }

                // ✅ Optional loading overlay
                if isLoading {
                    LoggingInView()
                }
            }
            .onAppear {
                checkLoginAndFetchList()
            }
            .onChange(of: authManager.accessToken) { _ in
                checkLoginAndFetchList()
            }
            .onOpenURL { url in
                handleOAuthRedirect(url)
            }
        }
    }

    // MARK: - 💡 Login View

    var loginView: some View {
        VStack(spacing: 10) {
            GIFView(gifName: "AirA_HI")
                .frame(width: 300, height: 300)
                .offset(x: 12)

            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .frame(width: 200, height: 50)

                Text("Welcome")
                    .font(AppFonts.custom(size: 28))
                    .foregroundColor(.black)
                    .fontWeight(.semibold)
            }
            .offset(y: -50)

            PixelButton(
                title: "Login with AniList",
                iconImageName: "AL",
                background: AppColors.accent,
                width: 280,
                height: 40
            ) {
                authManager.startLogin()
            }

            PixelButton(
                title: "Login with MyAnimeList",
                iconImageName: "MAL",
                background: AppColors.accent,
                width: 280,
                height: 40
            ) {
                // TODO: Implement MAL login
            }

            Spacer()
        }
        .padding()
        .background(Color(red: 25/255, green: 18/255, blue: 43/255))
    }

    // MARK: - 🔁 Login & Fetch Logic

    func checkLoginAndFetchList() {
        print("🔍 Checking login and fetching list")
        
        guard let token = authManager.accessToken else {
            print("🚫 No token found.")
            showAnimeList = false
            isLoading = false
            return
        }

        if isTokenExpired(token) {
            print("⛔️ Token expired.")
            authManager.logout()
            showAnimeList = false
            isLoading = false
            return
        }

        // ✅ Avoid re-fetching if list is already loaded
        if !animeListVM.animeList.isEmpty {
            print("🔁 Skipping fetch: anime list already loaded.")
            showAnimeList = true
            isLoading = false
            return
        }

        print("✅ Valid token. Fetching anime list...")
        isLoading = true
        showAnimeList = true

        animeListVM.fetchList(token: token)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
        }
    }


    func handleOAuthRedirect(_ url: URL) {
        if let code = extractCode(from: url) {
            isLoading = true
            authManager.getAccessToken(from: code)

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if let token = authManager.accessToken {
                    animeListVM.fetchList(token: token)
                    withAnimation {
                        self.showAnimeList = true
                    }
                } else {
                    self.isLoading = false
                }
            }
        }
    }
}
