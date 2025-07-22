//
//  NotificationManager.swift
//  Aira
//
//  Created by Gayathri Gondi on 22/07/25.
//


import Foundation
import UserNotifications

enum NotificationManager {
    
    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    static func scheduleNotification(id: String, title: String, date: Date) {
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

    static func scheduleNotifications(for anime: Anime) {
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

    static func scheduleDemoNotification() {
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
    
}
