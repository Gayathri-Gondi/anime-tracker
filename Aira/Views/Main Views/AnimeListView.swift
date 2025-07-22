import SwiftUI

enum AnimeSection: String, CaseIterable, Identifiable {
    case currentlywatching = "Currently Watching"
    case completed = "Completed"
    case planning = "Planning"
    case all = "All"
    
    var id: String { self.rawValue }
}

struct AnimeListView: View {
    @EnvironmentObject var viewModel: AnimeListViewModel
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var animeDataService: AnimeDataService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.isLoading {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(0..<4) { _ in
                                    AnimeCard(anime: Anime.placeholder)
                                        .redacted(reason: .placeholder)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    } else if let error = viewModel.error {
                        ErrorView(error: error)
                    } else {
                        ForEach(AnimeSection.allCases.filter { $0 != .all }) { section in
                            sectionView(for: section)
                        }
                    }
                }
                .padding(.top, 16)
            }
            .background(AppColors.background.edgesIgnoringSafeArea(.all))
            .navigationTitle("My Anime")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let token = authManager.accessToken {
                    viewModel.fetchList(token: token)
                }
            }
        }
    }
    
    @ViewBuilder
    private func sectionView(for section: AnimeSection) -> some View {
        let filteredAnime = viewModel.filteredAnime(for: section)
        
        VStack(alignment: .leading, spacing: 12) {
            Text(section.rawValue)
            
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(filteredAnime.prefix(6)) { anime in
                        NavigationLink(
                            destination: AnimeDetailView(
                                anime: SearchAnime(
                                    id: anime.id,
                                    title: anime.title,
                                    imageURL: anime.imageURL
                                )
                            )
                            .environmentObject(animeDataService)
                        ) {
                            AnimeCard(anime: anime)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    if filteredAnime.count > 6 {
                        NavigationLink(
                            destination: ViewMoreListView(section: section)
                                .environmentObject(animeDataService)
                                .environmentObject(authManager) // Add this if needed
                        ) {
                            ViewMoreCard(section: section)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppColors.accent.opacity(0.4), lineWidth: 1)
                                )
                                .shadow(color: AppColors.accent.opacity(0.2), radius: 3, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.horizontal, 16)
        }
    }
}


struct ErrorView: View {
    let error: Error
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
            Text("Error loading anime list")
                .font(AppFonts.custom(size: 16))
            Text(error.localizedDescription)
                .font(AppFonts.custom(size: 14))
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    let mockDataService = AnimeDataService()
    mockDataService.animeList = [
        Anime(
            id: 1,
            title: "Demon Slayer",
            imageURL: "https://example.com/image.jpg",
            animeStatus: "RELEASING",
            userStatus: "CURRENT",
            nextAiringEpisodeTime: Int(Date().timeIntervalSince1970) + 86400,
            episodeNumber: 11
        )
    ]
    
    return AnimeListView()
        .environmentObject(AuthManager())
        .environmentObject(mockDataService)
}
