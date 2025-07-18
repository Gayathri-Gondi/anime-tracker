import SwiftUI

// MARK: - Model
struct SearchAnime: Identifiable, Hashable {
    let id: Int
    let title: String
    let imageURL: String
}

// MARK: - View
struct AnimeSearchView: View {
    @StateObject private var viewModel = AnimeSearchViewModel()
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var animeListVM: AnimeListViewModel

    @State private var query = ""
    @State private var addedAnimeIDs: Set<Int> = []
    @State private var selectedAnime: SearchAnime?
    @State private var showSuccessAlert = false

    var body: some View {
        NavigationStack {
            ZStack {AppColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        TextField("Search for anime...", text: $query)
                            .font(AppFonts.custom(size: 16))
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .submitLabel(.search)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .onSubmit {
                                viewModel.performSearch(for: query)
                            }
                    }
                    .padding([.horizontal, .top])

                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(viewModel.searchResults) { anime in
                                NavigationLink(
                                    destination: AnimeDetailView(anime: anime)
                                        .environmentObject(animeListVM) // ✅ Inject shared view model
                                ) {
                                    AnimeCardView(
                                        anime: anime,
                                        isAdded: addedAnimeIDs.contains(anime.id),
                                        addAction: {
                                            selectedAnime = anime
                                        }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .sheet(item: $selectedAnime) { anime in
                AddAnimeSheet(anime: anime) { status, score, progress in
                    guard let token = authManager.accessToken else {
                        print("❌ No access token available.")
                        return
                    }
                    viewModel.addToAniList(animeID: anime.id, token: token, status: status, score: score, progress: progress) { success in
                        if success {
                            animeListVM.addAnimeWithDetails(animeID: anime.id, token: token)
                            addedAnimeIDs.insert(anime.id)
                            showSuccessAlert = true
                        }
                        selectedAnime = nil
                    }
                }
            }
            .alert("Added to AniList ✅", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) { }
            }
            .navigationTitle("Anime Search")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: viewModel.searchResults) { _, results in
                Task {
                    guard let token = authManager.accessToken else { return }
                    for anime in results {
                        let alreadyAdded = await viewModel.checkIfAnimeIsInAniList(animeID: anime.id, token: token)
                        if alreadyAdded {
                            addedAnimeIDs.insert(anime.id)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Card View
struct AnimeCardView: View {
    let anime: SearchAnime
    let isAdded: Bool
    let addAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: anime.imageURL)) { phase in
                if let image = phase.image {
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 140)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    Color.gray.frame(width: 100, height: 140)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(anime.title)
                    .font(AppFonts.custom(size: 18))
                    .foregroundColor(.white)
                    .lineLimit(2)

                if isAdded {
                    Label("Added to AniList", systemImage: "checkmark.seal.fill")
                        .font(AppFonts.custom(size: 14))
                        .foregroundColor(.green)
                } else {
                    Button(action: addAction) {
                        Label("Add to AniList", systemImage: "plus.circle.fill")
                            .font(AppFonts.custom(size: 14))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color(red: 1.0, green: 133/255, blue: 178/255))
                            .cornerRadius(8)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

// MARK: - Add Sheet
struct AddAnimeSheet: View {
    let anime: SearchAnime
    var onAdd: (String, Int, Int) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var selectedStatus = "CURRENT"
    @State private var score = 0
    @State private var progress = 0

    let statuses = ["CURRENT", "PLANNING", "COMPLETED", "DROPPED", "PAUSED", "REPEATING"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Status")) {
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(statuses, id: \.self) { Text($0.capitalized) }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                Section(header: Text("Score")) {
                    Stepper(value: $score, in: 0...100) {
                        Text("Score: \(score)")
                    }
                }

                Section(header: Text("Progress")) {
                    Stepper(value: $progress, in: 0...1000) {
                        Text("Episodes Watched: \(progress)")
                    }
                }

                Button("Add to AniList") {
                    onAdd(selectedStatus, score, progress)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .navigationTitle("Add to AniList")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let mockAnimeListVM = AnimeListViewModel()
    AnimeSearchView()
        .environmentObject(AuthManager())
        .environmentObject(mockAnimeListVM)
}
