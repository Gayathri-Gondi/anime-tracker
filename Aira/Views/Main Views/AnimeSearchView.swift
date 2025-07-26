import SwiftUI

// MARK: - Model
struct SearchAnime: Identifiable, Hashable {
    let id: Int
    let title: String
    let imageURL: String
    var animeStatus: String? = nil
}


// MARK: - View
struct AnimeSearchView: View {
    @StateObject private var viewModel = AnimeSearchViewModel()
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var animeListVM: AnimeListViewModel
    @EnvironmentObject var animeDataService: AnimeDataService
    @State private var showAllRecentSearches = false
    @State private var query = ""
    @State private var addedAnimeIDs: Set<Int> = []
    @State private var selectedAnime: SearchAnime?
    @State private var showSuccessAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 30/255, green: 30/255, blue: 60/255), .black]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    // 🔍 Search Field
                    HStack(spacing: 8) {
                        TextField("Search for anime...", text: $query)
                            .font(.system(size: 12, design: .monospaced))
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

                        if !query.isEmpty {
                            Button(action: {
                                query = ""
                                viewModel.searchResults = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.trailing, 8)
                            }
                            .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut, value: query)
                    .padding([.horizontal, .top])

                    // 🔁 Main Content
                    if !viewModel.searchResults.isEmpty {
                        searchResultsSection  // ✅ this shows results
                    } else if query.isEmpty {
                        ScrollView {
                            VStack(spacing: 24) {
                                if !viewModel.recentSearches.isEmpty {
                                    recentSearchesSection
                                    Divider().background(Color.white.opacity(0.1)).padding(.horizontal, 16)
                                }

                                if !animeListVM.upcomingSequels.isEmpty {
                                    upcomingSequelsSection
                                    Divider().background(Color.white.opacity(0.1)).padding(.horizontal, 16)
                                }

                                if !animeListVM.finishedSequels.isEmpty {
                                    finishedSequelsSection
                                    Divider().background(Color.white.opacity(0.1)).padding(.horizontal, 16)
                                }

                                if !viewModel.recommendedAnime.isEmpty {
                                    recommendedAnimeSection.padding(.bottom, 30)
                                }
                            }
                            .padding(.top, 40)
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
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

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                SectionHeader(title: "Recent Searches")
                Spacer()
                if viewModel.recentSearches.count > 3 {
                    Button(showAllRecentSearches ? "Hide" : "View All") {
                        withAnimation {
                            showAllRecentSearches.toggle()
                        }
                    }
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.pink)
                }
            }

            ChipCloudView(
                data: showAllRecentSearches ? viewModel.recentSearches : Array(viewModel.recentSearches.prefix(3)),
                onSelect: { selectedQuery in
                    self.query = selectedQuery
                    viewModel.performSearch(for: selectedQuery)
                },
                onRemove: { queryToRemove in
                    viewModel.removeRecentSearch(queryToRemove)
                }
            )
            .padding(.horizontal)
        }
    }
    
    
    private var upcomingSequelsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Upcoming Sequels")
                .padding(.top, 10)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(animeListVM.upcomingSequels, id: \.id) { sequel in
                        NavigationLink(
                            destination: AnimeDetailView(anime: sequel)
                                .environmentObject(animeDataService)
                        ) {
                            RecommendationCard(anime: sequel)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var finishedSequelsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "You might like")
                .padding(.top, 10)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(animeListVM.finishedSequels, id: \.id) { sequel in
                        NavigationLink(
                            destination: AnimeDetailView(anime: sequel)
                                .environmentObject(animeDataService)
                        ) {
                            RecommendationCard(anime: sequel)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }



    private var recommendedAnimeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Recommended Anime")
                .padding(.top, 15)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.recommendedAnime) { anime in
                        NavigationLink(
                            destination: AnimeDetailView(anime: anime)
                                .environmentObject(animeDataService)
                        ) {
                            RecommendationCard(anime: anime)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var searchResultsSection: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(viewModel.searchResults) { anime in
                    NavigationLink(
                        destination: AnimeDetailView(anime: anime)
                            .environmentObject(animeListVM)
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
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
    }
}


// MARK: - Chip Cloud View

struct ChipCloudView: View {
    let data: [String]
    let onSelect: (String) -> Void
    let onRemove: (String) -> Void

    let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(data, id: \.self) { query in
                HStack(spacing: 8) {
                    Text(query)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: {
                        onRemove(query)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .cornerRadius(10) // Rectangle with slightly rounded edges
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .onTapGesture {
                    onSelect(query)
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
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(2)

                if isAdded {
                    Label("Added to AniList", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 12,  design: .monospaced))
                        .foregroundColor(.green)
                } else {
                    Button(action: addAction) {
                        Label("Add to AniList", systemImage: "plus.circle.fill")
                            .font(.system(size: 12, design: .monospaced))
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

struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            Spacer() // Pushes text to the left
        }
        .padding(.horizontal)
    }
}


// MARK: - Preview
#Preview {
    let mockAnimeListVM = AnimeListViewModel()
    AnimeSearchView()
        .environmentObject(AuthManager())
        .environmentObject(mockAnimeListVM)
}
