import SwiftUI

enum AnimeSection: String, CaseIterable, Identifiable {
    case ongoing = "Ongoing"
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
                        ProgressView()
                            .frame(maxWidth: .infinity)
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
                .font(AppFonts.custom(size: 20))
                .foregroundColor(.white)
                .padding(.leading, 16)

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
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Subviews (Keep your existing implementations)
struct AnimeCard: View {
    let anime: Anime
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AnimeImageView(url: anime.imageURL)
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
