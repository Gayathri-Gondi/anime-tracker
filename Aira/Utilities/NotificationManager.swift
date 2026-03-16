//
//  NotificationManager.swift
//  Aira
//
//  Created by Gayathri Gondi on 22/07/25.
//

import Foundation
import UserNotifications

enum NotificationManager {
    
    // MARK: - Request Permission
    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            } else {
                print(granted ? "✅ Notification permission granted" : "❌ Notification permission denied")
            }
        }
    }
    
    // MARK: - Image Downloader
    private static func downloadImage(from urlString: String, completion: @escaping (URL?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        let task = URLSession.shared.downloadTask(with: url) { tempURL, _, _ in
            guard let tempURL = tempURL else {
                completion(nil)
                return
            }
            
            let fileManager = FileManager.default
            let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let localURL = cacheDir.appendingPathComponent(url.lastPathComponent)
            
            try? fileManager.removeItem(at: localURL)
            do {
                try fileManager.moveItem(at: tempURL, to: localURL)
                completion(localURL)
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }
    
    // MARK: - Core Scheduler
    static func scheduleNotification(
        id: String,
        title: String,
        subtitle: String? = nil,
        body: String? = nil,
        date: Date,
        imageURL: String? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = "🌸 \(title)"
        if let subtitle = subtitle { content.subtitle = subtitle }
        if let body = body { content.body = body }
        content.sound = .default
        content.categoryIdentifier = "airaNotification"
        
        // If imageURL exists, download and attach
        if let imageURL = imageURL {
            downloadImage(from: imageURL) { localURL in
                if let localURL = localURL,
                   let attachment = try? UNNotificationAttachment(identifier: "animeImage", url: localURL, options: nil) {
                    content.attachments = [attachment]
                }
                schedule(content: content, id: id, date: date)
            }
        } else {
            schedule(content: content, id: id, date: date)
        }
    }
    
    private static func schedule(content: UNMutableNotificationContent, id: String, date: Date) {
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            } else {
                print("✅ Notification scheduled: \(id)")
            }
        }
    }
    
    // MARK: - Anime Notifications
    static func scheduleNotifications(for anime: Anime) {
        guard let airingAt = anime.nextAiringEpisodeTime else { return }
        
        let airingDate = Date(timeIntervalSince1970: TimeInterval(airingAt))
        let oneHourBefore = airingDate.addingTimeInterval(-3600)
        let episodeText = "Episode \(anime.episodeNumber ?? 0)"
        
        if oneHourBefore > Date() {
            scheduleNotification(
                id: "\(anime.id)-1hr",
                title: "⏰ \(episodeText) Reminder!",
                subtitle: "🍡 Your cozy anime time is near~",
                body: "『\(anime.title)』 airs in 1 hour 🌸",
                date: oneHourBefore,
                imageURL: anime.imageURL
            )
        }
        
        if airingDate > Date() {
            scheduleNotification(
                id: "\(anime.id)-airing",
                title: "✨ Now Airing!",
                subtitle: anime.title,
                body: "\(episodeText) is live 💕 Tap to watch with Aira!",
                date: airingDate,
                imageURL: anime.imageURL
            )
        }
    }
    
    // MARK: - Demo Notification
    static func scheduleDemoNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🎉 Aira Test Alert"
        content.subtitle = "Just checking vibes 💌"
        content.body = "This is how your aesthetic notifications will look 🌸🍡✨"
        content.sound = .default

        // Attach a local image from your bundle (e.g. demoPoster.png in project)
        if let url = Bundle.main.url(forResource: "opnot", withExtension: "jpeg"),
           let attachment = try? UNNotificationAttachment(identifier: "opno", url: url, options: nil) {
            content.attachments = [attachment]
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
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
