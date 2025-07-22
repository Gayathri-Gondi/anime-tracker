// Models/AniListModels.swift
import Foundation

// MARK: - User Models
// Models/ViewerResponse.swift
struct ViewerResponse: Decodable {
    struct Data: Decodable {
        struct Viewer: Decodable {
            let id: Int
            let name: String?  // Make optional if sometimes missing
            let about: String?
            let avatar: Avatar?
        }
        let Viewer: Viewer
    }
    let data: Data
}

struct Viewer: Decodable {
    let id: Int
    let name: String
    let about: String?
    let avatar: Avatar
}

struct Avatar: Decodable {
    let large: String
}

struct AniListUser {
    let id: Int
    var name: String
    var about: String
    var avatar: String
}

// MARK: - Anime List Models
struct AnimeListResponse: Decodable {
    let data: Data
    
    struct Data: Decodable {
        let MediaListCollection: MediaListCollection
    }
}

struct MediaListCollection: Decodable {
    let lists: [MediaList]
}

struct MediaList: Decodable {
    let entries: [MediaEntry]
}

struct MediaEntry: Decodable {
    let status: String
    let media: Media
}

// MARK: - Anime Models
struct Anime: Identifiable, Equatable {
    let id: Int
    let title: String
    let imageURL: String
    var animeStatus: String
    var userStatus: String
    var nextAiringEpisodeTime: Int?
    var episodeNumber: Int?
    var userScore: Int?
}

// MARK: - Search Models
struct SearchResponse: Decodable {
    let data: Data
    
    struct Data: Decodable {
        let Page: Page
    }
}

struct Page: Decodable {
    let media: [SearchMedia]
}

struct SearchMedia: Decodable {
    let id: Int
    let title: Title
    let coverImage: CoverImage
}

// MARK: - Common Sub-models
struct Media: Decodable {
    let id: Int
    let title: Title
    let coverImage: CoverImage
    let status: String
    let nextAiringEpisode: AiringEpisode?
}

struct Title: Decodable {
    let romaji: String
}

struct CoverImage: Decodable {
    let large: String
}

struct AiringEpisode: Decodable {
    let airingAt: Int?
    let episode: Int?
}

// MARK: - Mutation Models
struct UpdateUserResponse: Decodable {
    let data: Data
    
    struct Data: Decodable {
        let saveUser: SavedUser
    }
}

struct SavedUser: Decodable {
    let id: Int
    let name: String
    let about: String?
}

// MARK: - Single Anime Response
struct SingleAnimeResponse: Decodable {
    let data: Data
    
    struct Data: Decodable {
        let Media: Media
    }
}

enum AnimeViewMode: String, CaseIterable, Identifiable {
    case grid = "grid"
    case list = "list"

    var id: String { self.rawValue }
}

extension Anime {
    static let placeholder = Anime(
        id: -1,
        title: "Loading...",
        imageURL: "https://via.placeholder.com/100x140.png?text=...",
        animeStatus: "",
        userStatus: "",
        nextAiringEpisodeTime: nil,
        episodeNumber: nil
    )
}
