import Foundation

// MARK: - ViewModel
class AnimeSearchViewModel: ObservableObject {
    @Published var searchResults: [SearchAnime] = []

    // MARK: - Search Anime
    func performSearch(for query: String) {
        guard let url = URL(string: "https://graphql.anilist.co") else {
            print("❌ Invalid search query.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let graphQLQuery = """
        query ($search: String) {
          Page(perPage: 10) {
            media(search: $search, type: ANIME) {
              id
              title {
                romaji
              }
              coverImage {
                large
              }
            }
          }
        }
        """

        let jsonBody: [String: Any] = [
            "query": graphQLQuery,
            "variables": ["search": query]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        } catch {
            print("❌ Failed to encode request body: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Network error:", error.localizedDescription)
                    return
                }

                guard let data = data else {
                    print("❌ No data received")
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let page = (json["data"] as? [String: Any])?["Page"] as? [String: Any],
                       let mediaArray = page["media"] as? [[String: Any]] {

                        let results = mediaArray.compactMap { item -> SearchAnime? in
                            guard let id = item["id"] as? Int,
                                  let titleDict = item["title"] as? [String: Any],
                                  let title = titleDict["romaji"] as? String,
                                  let cover = item["coverImage"] as? [String: Any],
                                  let imageURL = cover["large"] as? String else {
                                return nil
                            }
                            return SearchAnime(id: id, title: title, imageURL: imageURL)
                        }

                        self.searchResults = results

                    } else {
                        print("❌ Failed to parse JSON response.")
                    }
                } catch {
                    print("❌ JSON decoding error:", error)
                }
            }
        }.resume()
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
