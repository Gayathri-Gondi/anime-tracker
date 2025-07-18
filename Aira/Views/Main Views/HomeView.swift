import SwiftUI
import UserNotifications 

struct HomeView: View {
    @EnvironmentObject var animeListVM: AnimeListViewModel
    @EnvironmentObject var authManager: AuthManager
    @State private var currentTime = Date()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(animeListVM.ongoingAnimeList) { anime in
                    HStack(spacing: 16) {
                        AnimeImageView(url: anime.imageURL)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(anime.title)
                                .font(AppFonts.custom(size: 16))
                                .foregroundColor(.white)

                            if let airingAt = anime.nextAiringEpisodeTime {
                                let secondsLeft = airingAt - Int(currentTime.timeIntervalSince1970)
                                if secondsLeft > 0 {
                                    Text("Ep \(anime.episodeNumber ?? 0) airs in \(formatCountdown(seconds: secondsLeft))")
                                        .font(.caption)
                                        .foregroundColor(.pink)
                                } else {
                                    Text("Airing soon!")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            } else {
                                Text("No upcoming episode")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .background(AppColors.background.edgesIgnoringSafeArea(.all))
        .onAppear {
            requestNotificationPermission()

            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                currentTime = Date()
            }

            for anime in animeListVM.ongoingAnimeList {
                scheduleNotifications(for: anime)
            }

            scheduleDemoNotification()
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
