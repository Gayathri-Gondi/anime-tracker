//
//  NetworkService.swift
//  Aira
//
//  Created by Gayathri Gondi on 18/07/25.
//

// Utilities/NetworkService.swift
import Foundation
import Combine

class NetworkService {
    static let shared = NetworkService()
    private let baseURL = "https://graphql.anilist.co"
    
    private init() {}
    
    func performRequest<T: Decodable>(query: String,
                                    variables: [String: Any]? = nil,
                                    token: String? = nil) -> AnyPublisher<T, Error> {
        
        guard let url = URL(string: baseURL) else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var body: [String: Any] = ["query": query]
        if let variables = variables {
            body["variables"] = variables
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return Fail(error: NetworkError.encodingFailed).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error -> Error in
                if let decodingError = error as? DecodingError {
                    print("Decoding error: \(decodingError)")
                }
                return error
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    enum NetworkError: Error {
        case invalidURL
        case encodingFailed
        case decodingFailed
        case authenticationFailed
        case serverError(String)
    }
}
