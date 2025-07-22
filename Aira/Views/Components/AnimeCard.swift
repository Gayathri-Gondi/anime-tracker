//
//  AnimeCard.swift
//  Aira
//
//  Created by Gayathri Gondi on 22/07/25.
//
import SwiftUI

// MARK: - Subviews (Keep your existing implementations)
struct AnimeCard: View {
    let anime: Anime
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AnimeImageView(url: anime.imageURL)
                .frame(width: 100, height: 140) // ⛔️ hardcoded size
            Text(anime.title)
                .font(AppFonts.custom(size: 12))
                .foregroundColor(.white)
                .frame(width: 100, alignment: .leading)
        }
    }
}

struct ViewMoreCard: View {
    let section: AnimeSection

    var body: some View {
        VStack {
            Image(systemName: "ellipsis")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(AppColors.accent)

            Text("View More")
                .font(AppFonts.custom(size: 12))
                .foregroundColor(.white)
        }
        .frame(width: 100, height: 140)
        .background(AppColors.accent.opacity(0.2))
        .cornerRadius(10)
    }
}

struct AnimeListCard: View {
    let anime: Anime
    let currentTime: Date

    var body: some View {
        HStack(spacing: 16) {
            AnimeImageView(url: anime.imageURL)
                .frame(width: 67, height: 100)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 6) {
                Text(anime.title)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)             // truncate after 1 line
                    .truncationMode(.tail)    // show "..." at end

                if let airingAt = anime.nextAiringEpisodeTime {
                    let secondsLeft = airingAt - Int(currentTime.timeIntervalSince1970)
                    if secondsLeft > 0 {
                        Text("Ep \(anime.episodeNumber ?? 0) in \(formatCountdown(seconds: secondsLeft))")
                            .font(.caption2)
                            .foregroundColor(.pink)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    } else {
                        Text("Airing soon!")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                } else {
                    Text("No upcoming episode")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }
        .frame(height: 90)   // fixed height for uniform cards
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .pink.opacity(0.1), radius: 2, x: 0, y: 2)
    }
}

struct AnimeGridCard: View {
    let anime: Anime
    let currentTime: Date

    var body: some View {
        VStack(spacing: 8) {
            AnimeImageView(url: anime.imageURL)
                .frame(width: 130, height: 182)
                .cornerRadius(12)

            Text(anime.title)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)            // truncate after 1 line
                .truncationMode(.tail)   // "..."

            if let airingAt = anime.nextAiringEpisodeTime {
                let secondsLeft = airingAt - Int(currentTime.timeIntervalSince1970)
                if secondsLeft > 0 {
                    Text("Ep \(anime.episodeNumber ?? 0) in \(formatCountdown(seconds: secondsLeft))")
                        .font(.caption2)
                        .foregroundColor(.pink)
                        .lineLimit(1)
                        .truncationMode(.tail)
                } else {
                    Text("Airing soon!")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .frame(width: 160, height: 240)  // fixed size for uniform grid cards
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(4)
    }
}
