import Combine
import Foundation



class AnimeListViewModel: ObservableObject {
    @Published var animeList: [Anime] = []
    @Published var isLoading = false
    @Published var error: Error?
    

    private let animeDataService: AnimeDataServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(service: AnimeDataServiceProtocol = AnimeDataService.shared) {
        self.animeDataService = service
        self.animeList = service.animeList

        // 🔄 Keep syncing whenever AnimeDataService updates
        if let shared = service as? AnimeDataService {
            shared.$animeList
                .receive(on: DispatchQueue.main)
                .sink { [weak self] updatedList in
                    self?.animeList = updatedList
                }
                .store(in: &cancellables)
        }
    }

    
    func fetchList(token: String) {
        error = nil
        
        animeDataService.fetchAnimeList(token: token)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                    print("❌ Fetch error: \(error.localizedDescription)")
                }
            } receiveValue: { _ in
                // 👇 No manual assignment here
            }
            .store(in: &cancellables)
    }
    
    func addOrUpdateAnime(_ newAnime: Anime) {
        if let index = animeList.firstIndex(where: { $0.id == newAnime.id }) {
            animeList[index] = newAnime
        } else {
            animeList.append(newAnime)
        }
        // No need for manual refresh - @Published will handle it
    }

    var ongoingAnimeList: [Anime] {
        animeList.filter { $0.animeStatus.uppercased() == "RELEASING" }
    }

    func addAnimeWithDetails(animeID: Int, token: String) {
        isLoading = true
        animeDataService.fetchSingleAnime(animeID: animeID, token: token)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error
                    print("❌ Single anime fetch error: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] anime in
                self?.addOrUpdateAnime(anime)
            }
            .store(in: &cancellables)
    }
    
    func filteredAnime(for section: AnimeSection) -> [Anime] {
        switch section {
        case .ongoing:
            return ongoingAnimeList
        case .currentlywatching:
            return animeList.filter { $0.userStatus.uppercased() == "CURRENT" }
        case .completed:
            return animeList.filter { $0.userStatus.uppercased() == "COMPLETED" }
        case .planning:
            return animeList.filter { $0.userStatus.uppercased() == "PLANNING" }
        case .all:
            return animeList
        }
    }
}
