import Foundation
import Combine

// First, ensure the protocol is properly defined (should be in a separate file)
protocol AnimeDataServiceProtocol: AnyObject {
    var animeList: [Anime] { get }
    var searchResults: [SearchAnime] { get }
    var isLoading: Bool { get }
    var error: Error? { get }
    
    func fetchAnimeList(token: String) -> AnyPublisher<[Anime], Error>
    func fetchSingleAnime(animeID: Int, token: String) -> AnyPublisher<Anime, Error>
    func searchAnime(query: String) -> AnyPublisher<[SearchAnime], Error>
    func addOrUpdateAnime(_ newAnime: Anime)
}

class AnimeDataService: ObservableObject, AnimeDataServiceProtocol {
    static let shared = AnimeDataService()
    
    @Published var animeList: [Anime] = []
    @Published var searchResults: [SearchAnime] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private let networkService = NetworkService.shared

    // MARK: - Protocol Implementation
    
    func fetchAnimeList(token: String) -> AnyPublisher<[Anime], Error> {
        isLoading = true
        error = nil
        
        return fetchUserId(token: token)
            .flatMap { [weak self] userId -> AnyPublisher<[Anime], Error> in
                self?.fetchUserAnimeList(token: token, userId: userId) ?? Empty().eraseToAnyPublisher()
            }
            .handleEvents(
                receiveOutput: { [weak self] (animeList: [Anime]) in
                    self?.animeList = animeList
                },
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error
                    }
                }
            )
            .eraseToAnyPublisher()
    }
    
    func fetchSingleAnime(animeID: Int, token: String) -> AnyPublisher<Anime, Error> {
        isLoading = true
        error = nil
        
        let query = """
        query {
          Media(id: \(animeID), type: ANIME) {
            id
            title { romaji }
            coverImage { large }
            status
            nextAiringEpisode { airingAt episode }
          }
        }
        """
        
        return networkService.performRequest(query: query, token: token)
            .map { (response: SingleAnimeResponse) -> Anime in
                Anime(
                    id: response.data.Media.id,
                    title: response.data.Media.title.romaji,
                    imageURL: response.data.Media.coverImage.large,
                    animeStatus: response.data.Media.status,
                    userStatus: "CURRENT",
                    nextAiringEpisodeTime: response.data.Media.nextAiringEpisode?.airingAt,
                    episodeNumber: response.data.Media.nextAiringEpisode?.episode
                )
            }
            .handleEvents(receiveCompletion: { [weak self] (_: Subscribers.Completion<Error>) in
                self?.isLoading = false
            })
            .eraseToAnyPublisher()
    }
    
    func searchAnime(query: String) -> AnyPublisher<[SearchAnime], Error> {
        isLoading = true
        error = nil
        
        let graphQLQuery = """
        query ($search: String) {
          Page(perPage: 10) {
            media(search: $search, type: ANIME) {
              id
              title { romaji }
              coverImage { large }
              status
            }
          }
        }
        """
        
        return networkService.performRequest(
            query: graphQLQuery,
            variables: ["search": query]
        )
        .handleEvents(
            receiveOutput: { [weak self] (response: SearchResponse) in
                self?.searchResults = response.data.Page.media.map { SearchAnime(from: $0) }
            },
            receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error
                }
            }
        )
        .map { (response: SearchResponse) -> [SearchAnime] in
            response.data.Page.media.map { SearchAnime(from: $0) }
        }
        .eraseToAnyPublisher()
    }
    
    func addOrUpdateAnime(_ newAnime: Anime) {
        if let index = animeList.firstIndex(where: { $0.id == newAnime.id }) {
            animeList[index] = newAnime
        } else {
            animeList.append(newAnime)
        }
    }
    
    // MARK: - Helper Properties
    
    var ongoingAnimeList: [Anime] {
        animeList.filter { $0.animeStatus.uppercased() == "RELEASING" }
    }
    
    // MARK: - Private Methods
    
    private func fetchUserId(token: String) -> AnyPublisher<Int, Error> {
        let query = "query { Viewer { id } }"
        return networkService.performRequest(query: query, token: token)
            .map { (response: ViewerResponse) -> Int in
                response.data.Viewer.id
            }
            .eraseToAnyPublisher()
    }
    
    private func fetchUserAnimeList(token: String, userId: Int) -> AnyPublisher<[Anime], Error> {
        let query = """
        query {
          MediaListCollection(userId: \(userId), type: ANIME) {
            lists {
              entries {
                status
                media {
                  id
                  title { romaji }
                  coverImage { large }
                  status
                  nextAiringEpisode { airingAt episode }
                  relations {
                    edges {
                      relationType
                      node {
                        id
                        title { romaji }
                        coverImage { large }
                        format
                        status
                        startDate { year month day }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        """

        
        return networkService.performRequest(query: query, token: token)
            .map { (response: AnimeListResponse) -> [Anime] in
                response.data.MediaListCollection.lists
                    .flatMap { $0.entries }
                    .map { Anime(from: $0) }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Model Extensions

private extension SearchAnime {
    init(from media: SearchMedia) {
        self.init(
            id: media.id,
            title: media.title.romaji,
            imageURL: media.coverImage.large,
            animeStatus: media.status
        )
    }
}
