import SwiftUI
import UserNotifications

struct HomeView: View {
    @EnvironmentObject var animeListVM: AnimeListViewModel
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var animeDataService: AnimeDataService
    @State private var selectedViewMode: AnimeViewMode = .grid
    @State private var currentTime = Date()

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 30/255, green: 30/255, blue: 60/255), .black]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // ✅ Fixed (non-scrollable) title
                Text("Anime Airboard")
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: .pink.opacity(0.3), radius: 2, x: 0, y: 1)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
                
                Picker("View Mode", selection: $selectedViewMode) {
                    ForEach(AnimeViewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                Spacer()
                
                // ✅ Scrollable content below
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if !todaysReleases.isEmpty {
                            Text("Today’s Releases")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(.yellow)
                                .padding(.horizontal)

                            animeSection(for: todaysReleases)
                        }

                        if !upcomingAnime.isEmpty {
                            Text("Upcoming Episodes")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal)

                            animeSection(for: upcomingAnime)
                        }
                    }
                    .padding(.top)
                }
            }
        }
        .onAppear {
            NotificationManager.requestNotificationPermission()

            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                currentTime = Date()
            }

            for anime in animeListVM.ongoingAnimeList {
                NotificationManager.scheduleNotifications(for: anime)
            }
            
            NotificationManager.scheduleDemoNotification()
        }
    }
    
    @ViewBuilder
    func animeSection(for list: [Anime]) -> some View {
        switch selectedViewMode {
        case .grid:
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(list) { anime in
                    NavigationLink(
                        destination: AnimeDetailView(
                            anime: SearchAnime(id: anime.id, title: anime.title, imageURL: anime.imageURL)
                        )
                    ) {
                        AnimeGridCard(anime: anime, currentTime: currentTime)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)

        case .list:
            ForEach(list) { anime in
                NavigationLink(
                    destination: AnimeDetailView(
                        anime: SearchAnime(id: anime.id, title: anime.title, imageURL: anime.imageURL)
                    )
                ) {
                    AnimeListCard(anime: anime, currentTime: currentTime)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
        }
    }

    var sortedAnimeList: [Anime] {
        animeListVM.ongoingAnimeList.sorted {
            let aTime = $0.nextAiringEpisodeTime ?? Int.max
            let bTime = $1.nextAiringEpisodeTime ?? Int.max
            return aTime < bTime
        }
    }

    var todaysReleases: [Anime] {
        let now = currentTime
        let calendar = Calendar.current
        return animeListVM.ongoingAnimeList.filter { anime in
            guard let airingAt = anime.nextAiringEpisodeTime else { return false }
            
            let airingDate = Date(timeIntervalSince1970: TimeInterval(airingAt))
            let pastAiringDate = calendar.date(byAdding: .day, value: -7, to: airingDate) ?? airingDate
            
            return calendar.isDate(airingDate, inSameDayAs: now) || calendar.isDate(pastAiringDate, inSameDayAs: now)
        }
    }

    var upcomingAnime: [Anime] {
        let todayIDs = Set(todaysReleases.map { $0.id })
        return sortedAnimeList.filter { !todayIDs.contains($0.id) }
    }
    
}

func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if let error = error {
            print("Notification permission error: \(error.localizedDescription)")
        }
    }
}

func scheduleNotification(id: String, title: String, date: Date) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.sound = .default

    let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
    let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Notification error: \(error.localizedDescription)")
        }
    }
}

func scheduleNotifications(for anime: Anime) {
    guard let airingAt = anime.nextAiringEpisodeTime else { return }

    let airingDate = Date(timeIntervalSince1970: TimeInterval(airingAt))
    let oneHourBefore = airingDate.addingTimeInterval(-3600)
    let title = "\(anime.title) Episode \(anime.episodeNumber ?? 0)"

    if oneHourBefore > Date() {
        scheduleNotification(
            id: "\(anime.id)-1hr",
            title: "\(title) airs in 1 hour!",
            date: oneHourBefore
        )
    }

    if airingDate > Date() {
        scheduleNotification(
            id: "\(anime.id)-airing",
            title: "\(title) is airing now!",
            date: airingDate
        )
    }
}

func scheduleDemoNotification() {
    let content = UNMutableNotificationContent()
    content.title = "🎉 Demo Notification"
    content.body = "This is a test notification to check how it looks!"
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
    let request = UNNotificationRequest(identifier: "demo-notification", content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Demo Notification Error: \(error.localizedDescription)")
        } else {
            print("✅ Demo notification scheduled!")
        }
    }
}

func formatCountdown(seconds: Int) -> String {
    let days = seconds / 86400
    let hours = (seconds % 86400) / 3600
    let minutes = (seconds % 3600) / 60
    let seconds = seconds % 60
    
    if days > 0 {
        return String(format: "%dd %02dh %02dm %02ds", days, hours, minutes, seconds)
    } else {
        return String(format: "%02dh %02dm %02ds", hours, minutes, seconds)
    }
}
