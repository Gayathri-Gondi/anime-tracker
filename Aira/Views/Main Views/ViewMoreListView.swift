import SwiftUI

struct ViewMoreListView: View {
    @EnvironmentObject var animeDataService: AnimeDataService
    let section: AnimeSection

    var body: some View {
        List(filteredAnime) { anime in
            NavigationLink(destination:
                AnimeDetailView(anime: SearchAnime(
                    id: anime.id,
                    title: anime.title,
                    imageURL: anime.imageURL
                ))
                .environmentObject(animeDataService)
            ) {
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: anime.imageURL)) { phase in
                        if let image = phase.image {
                            image.resizable()
                        } else {
                            Color.gray
                        }
                    }
                    .frame(width: 60, height: 90)
                    .cornerRadius(6)

                    VStack(alignment: .leading) {
                        Text(anime.title)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)

                        Text("Status: \(anime.userStatus.capitalized)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .listRowBackground(AppColors.background)
        }
        .navigationTitle(section.rawValue)
        .background(AppColors.background)
        .scrollContentBackground(.hidden)
    }

    private var filteredAnime: [Anime] {
        switch section {
        case .currentlywatching:
            return animeDataService.animeList.filter {
                $0.userStatus.uppercased() == "CURRENT"
            }
        case .completed:
            return animeDataService.animeList.filter {
                $0.userStatus.uppercased() == "COMPLETED"
            }
        case .planning:
            return animeDataService.animeList.filter {
                $0.userStatus.uppercased() == "PLANNING"
            }
        case .all:
            return animeDataService.animeList
        }
    }
}
