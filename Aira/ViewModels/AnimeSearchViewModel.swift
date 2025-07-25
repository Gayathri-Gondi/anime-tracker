import Foundation
import Combine

class AnimeSearchViewModel: ObservableObject {
    @Published var searchResults: [SearchAnime] = []
    @Published var recommendedAnime: [SearchAnime] = []
    @Published var recentSearches: [String] = []

    private let recentSearchesKey = "recentSearches"
    private let dataService = AnimeDataService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadRecentSearches()
        fetchRecommendedAnime()
    }

    // MARK: - Recent Searches

    private func saveRecentSearch(_ query: String) {
        var searches = UserDefaults.standard.stringArray(forKey: recentSearchesKey) ?? []
        searches.removeAll { $0.lowercased() == query.lowercased() }
        searches.insert(query, at: 0)
        if searches.count > 10 { searches = Array(searches.prefix(10)) }
        UserDefaults.standard.setValue(searches, forKey: recentSearchesKey)
        recentSearches = searches
    }

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: recentSearchesKey) ?? []
    }
    
    
     func removeRecentSearch(_ query: String) {
         recentSearches.removeAll { $0 == query }
         UserDefaults.standard.setValue(recentSearches, forKey: recentSearchesKey)
     }

    // MARK: - Recommended Anime (Trending)

    func fetchRecommendedAnime() {
        let query = """
        query {
          Page(perPage: 10) {
            media(sort: TRENDING_DESC, type: ANIME) {
              id
              title { romaji }
              coverImage { large }
            }
          }
        }
        """

        NetworkService.shared.performRequest(query: query)
                    .map { (response: SearchResponse) -> [SearchAnime] in
                        response.data.Page.media.map { media in
                            SearchAnime(
                                id: media.id,
                                title: media.title.romaji,
                                imageURL: media.coverImage.large
                            )
                        }
                    }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Trending fetch failed:", error.localizedDescription)
                }
            }, receiveValue: { [weak self] animes in
                self?.recommendedAnime = animes
            })
            .store(in: &cancellables)
    }

    // MARK: - Search Anime

    func performSearch(for query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        saveRecentSearch(query)

        dataService.searchAnime(query: query)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("❌ Search failed:", error.localizedDescription)
                    self?.searchResults = []
                }
            }, receiveValue: { [weak self] animes in
                self?.searchResults = animes
            })
            .store(in: &cancellables)
    }

    // MARK: - Add Anime to AniList
    func addToAniList(
           animeID: Int,
           token: String,
           status: String,
           score: Int,
           progress: Int,
           completion: @escaping (Bool) -> Void
       ) {
           guard let url = URL(string: "https://graphql.anilist.co") else {
               completion(false)
               return
           }

           var request = URLRequest(url: url)
           request.httpMethod = "POST"
           request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
           request.setValue("application/json", forHTTPHeaderField: "Content-Type")

           let mutation = """
           mutation {
             SaveMediaListEntry(mediaId: \(animeID), status: \(status), score: \(score), progress: \(progress)) {
               id
             }
           }
           """

           let body: [String: Any] = ["query": mutation]

           do {
               request.httpBody = try JSONSerialization.data(withJSONObject: body)
           } catch {
               print("❌ Failed to serialize body:", error)
               completion(false)
               return
           }

           URLSession.shared.dataTask(with: request) { data, response, error in
               DispatchQueue.main.async {
                   if let httpResponse = response as? HTTPURLResponse {
                       if httpResponse.statusCode == 200 {
                           completion(true)
                       } else {
                           print("❌ Failed with status code:", httpResponse.statusCode)
                           if let data = data, let responseString = String(data: data, encoding: .utf8) {
                               print("🔻 Response:", responseString)
                           }
                           completion(false)
                       }
                   } else {
                       print("❌ Invalid response or error:", error?.localizedDescription ?? "Unknown error")
                       completion(false)
                   }
               }
           }.resume()
       }

    // MARK: - Check If Anime Exists
    func checkIfAnimeIsInAniList(animeID: Int, token: String) async -> Bool {
        guard let url = URL(string: "https://graphql.anilist.co") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let query = """
        query {
          Media(id: \(animeID), type: ANIME) {
            mediaListEntry {
              id
            }
          }
        }
        """

        let body: [String: Any] = ["query": query]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("❌ Failed to serialize query:", error)
            return false
        }

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let media = (json["data"] as? [String: Any])?["Media"] as? [String: Any],
               let entry = media["mediaListEntry"] as? [String: Any] {
                return entry["id"] != nil
            }
        } catch {
            print("❌ AniList check failed:", error.localizedDescription)
        }

        return false
    }

}

func fetchSingleAnime(animeID: Int, token: String, completion: @escaping (Anime?) -> Void) {
    let query = """
    query {
      Media(id: \(animeID), type: ANIME) {
        id
        title {
          romaji
        }
        coverImage {
          large
        }
        status
        nextAiringEpisode {
          airingAt
          episode
        }
      }
    }
    """

    var request = URLRequest(url: URL(string: "https://graphql.anilist.co")!)
    request.httpMethod = "POST"
    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try? JSONSerialization.data(withJSONObject: ["query": query])

    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let media = (json["data"] as? [String: Any])?["Media"] as? [String: Any],
              let id = media["id"] as? Int,
              let titleDict = media["title"] as? [String: Any],
              let romaji = titleDict["romaji"] as? String,
              let cover = media["coverImage"] as? [String: Any],
              let imageURL = cover["large"] as? String,
              let animeStatus = media["status"] as? String
        else {
            DispatchQueue.main.async { completion(nil) }
            return
        }

        let nextAiring = media["nextAiringEpisode"] as? [String: Any]
        let airingAt = nextAiring?["airingAt"] as? Int
        let episode = nextAiring?["episode"] as? Int

        let anime = Anime(
            id: id,
            title: romaji,
            imageURL: imageURL,
            animeStatus: animeStatus,
            userStatus: "CURRENT", // or infer from elsewhere
            nextAiringEpisodeTime: airingAt,
            episodeNumber: episode,
            userScore: 0
        )

        DispatchQueue.main.async {
            completion(anime)
        }
    }.resume()
}
