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
    
    
    var relatedMedia: [RelatedMedia]? = nil  // ← ✅ NEW
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
    let status: String?           
}

// MARK: - Common Sub-models
struct Media: Decodable {
    let id: Int
    let title: Title
    let coverImage: CoverImage
    let status: String
    let nextAiringEpisode: AiringEpisode?
    let relations: MediaConnection?  // 👈 Add this
}

struct MediaConnection: Decodable {
    let edges: [MediaEdge]
}

struct MediaEdge: Decodable {
    let relationType: String
    let node: RelatedMedia
}

struct RelatedMedia: Decodable, Equatable {
    let id: Int
    let title: Title
    let coverImage: CoverImage
    let format: String?
    let status: String?
    let startDate: FuzzyDate?
    var relationType: String?  // ← Add this
    let nextAiringEpisode: AiringInfo? // ← Needed for `airingAt`

    var simplifiedTitle: String {
        title.romaji
    }

    var imageURL: String {
        coverImage.large
    }
}

struct AiringInfo: Decodable, Equatable  {
    let airingAt: Int // Unix timestamp
}


struct Title: Decodable, Equatable {
    let romaji: String
}

struct CoverImage: Decodable, Equatable {
    let large: String
}

struct FuzzyDate: Decodable, Equatable {
    let year: Int?
    let month: Int?
    let day: Int?
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
    
    init(from entry: MediaEntry) {
        let media = entry.media
        let airing = media.nextAiringEpisode

        self.init(
            id: media.id,
            title: media.title.romaji,
            imageURL: media.coverImage.large,
            animeStatus: media.status,
            userStatus: entry.status,
            nextAiringEpisodeTime: airing?.airingAt,
            episodeNumber: airing?.episode,
            userScore: nil,
            relatedMedia: media.relations?.edges.map { edge in
                var related = edge.node
                related.relationType = edge.relationType  // ← Inject relation type
                return related
            }
        )
    }
}

