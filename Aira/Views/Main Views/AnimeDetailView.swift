import SwiftUI

struct AnimeDetailView: View {
    let anime: SearchAnime
    @State private var details: FullAnimeDetail.Media?
    @State private var isLoading = true
    @State private var isUpdating = false
    @State private var updateMessage = ""

    @State private var userProgress = ""
    @State private var userScore = ""
    @State private var userStatus = "CURRENT"

    @State private var userAnimeEntry: AniListMediaListEntry?

    @EnvironmentObject var animeListVM: AnimeListViewModel
    @EnvironmentObject var authManager: AuthManager

    let statusOptions = ["CURRENT", "COMPLETED", "PLANNING", "DROPPED", "PAUSED", "REPEATING"]

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else if let details = details {
                ScrollView {
                    VStack(spacing: 20) {
                        AsyncImage(url: URL(string: anime.imageURL)) { phase in
                            if let image = phase.image {
                                image.resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 300)
                                    .cornerRadius(12)
                            } else {
                                Color.gray.frame(width: 300, height: 400)
                            }
                        }

                        Text(details.title.romaji ?? anime.title)
                            .font(AppFonts.custom(size: 22))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        if let description = details.description {
                            Text(description
                                .replacingOccurrences(of: "<br>", with: "\n")
                                .replacingOccurrences(of: "<i>", with: "")
                                .replacingOccurrences(of: "</i>", with: ""))
                            .font(AppFonts.custom(size: 16))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal)
                        }

                        Group {
                            if let format = details.format {
                                DetailRow(label: "Format", value: format)
                            }
                            if let status = details.status {
                                DetailRow(label: "Status", value: status)
                            }
                            if let episodes = details.episodes {
                                DetailRow(label: "Episodes", value: "\(episodes)")
                            }
                            if let score = details.averageScore {
                                DetailRow(label: "Avg Score", value: "\(score)%")
                            }
                            if let genres = details.genres {
                                DetailRow(label: "Genres", value: genres.joined(separator: ", "))
                            }
                        }

                        Divider().background(.white.opacity(0.6)).padding(.top)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("🎯 Your AniList Entry")
                                .font(AppFonts.custom(size: 18))
                                .foregroundColor(.white)

                            TextField("Progress", text: $userProgress)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            TextField("Score (out of 100)", text: $userScore)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            Picker("Status", selection: $userStatus) {
                                ForEach(statusOptions, id: \.self) {
                                    Text($0.capitalized)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        .padding(.horizontal)

                        if isUpdating {
                            ProgressView()
                        } else {
                            HStack(spacing: 16) {
                                Button("💾 Save Changes to AniList") {
                                    updateAniListEntry()
                                }
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.pink)
                                .cornerRadius(12)

                                Button("🗑️ Delete") {
                                    deleteAniListEntry()
                                }
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.red)
                                .cornerRadius(12)
                            }
                        }

                        if !updateMessage.isEmpty {
                            Text(updateMessage)
                                .foregroundColor(.green)
                                .padding(.top, 8)
                        }
                    }
                    .padding()
                }
            } else {
                Text("❌ Failed to load details.")
                    .foregroundColor(.white)
            }
        }
        .navigationTitle("Anime Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchDetails()
            fetchUserEntry()
        }
    }

    // MARK: - Fetch Detail Info
    func fetchDetails() {
        isLoading = true
        let query = """
        {
          Media(id: \(anime.id)) {
            id
            title { romaji }
            description
            episodes
            format
            status
            genres
            averageScore
          }
        }
        """
        let body = ["query": query]
        performAniListRequest(with: body) { data in
            guard let decoded = try? JSONDecoder().decode(FullAnimeDetail.Root.self, from: data) else {
                isLoading = false
                return
            }
            DispatchQueue.main.async {
                self.details = decoded.data.media
                self.isLoading = false
            }
        }
    }

    // MARK: - Fetch User Entry
    func fetchUserEntry() {
        let query = """
        {
          Media(id: \(anime.id)) {
            id
            mediaListEntry {
              id
              status
              score
              progress
            }
          }
        }
        """
        let body = ["query": query]
        performAniListRequest(with: body) { data in
            if let decoded = try? JSONDecoder().decode(MediaListEntryCheck.self, from: data),
               let entry = decoded.data.Media.mediaListEntry {
                DispatchQueue.main.async {
                    self.userAnimeEntry = entry
                    self.userProgress = String(entry.progress)
                    self.userScore = String(Int(entry.score))
                    self.userStatus = entry.status
                }
            }
        }
    }

    // MARK: - Update User Entry
    func updateAniListEntry() {
        guard let token = loadToken() else {
            self.updateMessage = "❌ Not logged in"
            return
        }

        isUpdating = true
        let progress = Int(userProgress) ?? 0
        let score = Int(userScore) ?? 0

        let mutation = """
        mutation {
          SaveMediaListEntry(mediaId: \(anime.id), progress: \(progress), score: \(score), status: \(userStatus)) {
            id
            status
            score
            progress
          }
        }
        """

        var request = URLRequest(url: URL(string: "https://graphql.anilist.co")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["query": mutation])

        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                self.isUpdating = false
                if data != nil {
                    self.updateMessage = "✅ Updated successfully!"

                    // ✅ Fetch the latest anime info after update
                    fetchSingleAnime(animeID: anime.id, token: token) { freshAnime in
                        DispatchQueue.main.async {
                            if let fresh = freshAnime {
                                animeListVM.addOrUpdateAnime(fresh)
                            }
                        }
                    }
                } else {
                    self.updateMessage = "❌ Failed to update"
                }
            }
        }.resume()
    }



    // MARK: - Network Helper
    func performAniListRequest(with body: [String: Any], completion: @escaping (Data) -> Void) {
        var request = URLRequest(url: URL(string: "https://graphql.anilist.co")!)
        request.httpMethod = "POST"
        if let token = loadToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data {
                completion(data)
            }
        }.resume()
    }
    
    func deleteAniListEntry() {
        guard let entryId = userAnimeEntry?.id else {
            self.updateMessage = "❌ No entry to delete"
            return
        }

        guard let token = loadToken() else {
            self.updateMessage = "❌ Not logged in"
            return
        }

        isUpdating = true

        let mutation = """
        mutation {
          DeleteMediaListEntry(id: \(entryId)) {
            deleted
          }
        }
        """

        var request = URLRequest(url: URL(string: "https://graphql.anilist.co")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["query": mutation])

        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                self.isUpdating = false
                if data != nil {
                    self.updateMessage = "✅ Deleted successfully!"

                    // ✅ Fetch the latest anime info after update
                    fetchSingleAnime(animeID: anime.id, token: token) { freshAnime in
                        DispatchQueue.main.async {
                            if let fresh = freshAnime {
                                animeListVM.addOrUpdateAnime(fresh)
                            }
                        }
                    }
                } else {
                    self.updateMessage = "❌ Failed to Delete"
                }
            }
        }.resume()
    }

}

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text("\(label):")
                .font(AppFonts.custom(size: 16))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value)
                .font(AppFonts.custom(size: 16))
                .foregroundColor(.white)
        }
        .padding(.horizontal)
    }
}

// MARK: - AniList Entry Structures
struct MediaListEntryCheck: Codable {
    struct Data: Codable {
        struct Media: Codable {
            let mediaListEntry: AniListMediaListEntry?
        }
        let Media: Media
    }
    let data: Data
}

struct AniListMediaListEntry: Codable {
    let id: Int
    let status: String
    let score: Double
    let progress: Int
}
