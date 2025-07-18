//
//  AniListAPI.swift
//  Aira
//
//  Created by Gayathri Gondi on 17/07/25.
//


import Foundation

class AniListAPI {
    static func performGraphQL<T: Decodable>(
        query: String,
        token: String,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: "https://graphql.anilist.co") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["query": query]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "dataNil", code: 0)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                print("❌ Decode Error: \(error)")
                if let raw = String(data: data, encoding: .utf8) {
                    print("📨 Raw response:\n\(raw)")
                }
                completion(.failure(error))
            }
        }.resume()
    }
}

