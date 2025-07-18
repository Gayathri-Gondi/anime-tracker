import Foundation

struct FullAnimeDetail: Codable {
    let media: Media

    enum CodingKeys: String, CodingKey {
        case media = "Media"
    }

    struct Media: Codable, Identifiable {
        let id: Int
        let title: Title
        let description: String?
        let episodes: Int?
        let format: String?
        let status: String?
        let genres: [String]?
        let averageScore: Int?

        struct Title: Codable {
            let romaji: String?
        }
    }
}

extension FullAnimeDetail {
    struct Root: Codable {
        let data: FullAnimeDetail
    }
}
