//
//  SettingsViewModel.swift
//  Aira
//
//  Created by Gayathri Gondi on 17/07/25.
//

import Foundation

class SettingsViewModel: ObservableObject {
    @Published var user: AniListUser?
    
    func fetchUser(token: String, completion: ((AniListUser?) -> Void)? = nil) {
        let query = """
        query {
          Viewer {
            id
            name
            about
            avatar {
              large
            }
          }
        }
        """
        
        AniListAPI.performGraphQL(query: query, token: token) { (result: Result<ViewerResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // Safely unwrap optional values
                    let avatarURL = response.data.Viewer.avatar?.large ?? ""
                    
                    let fetchedUser = AniListUser(
                        id: response.data.Viewer.id,
                        name: response.data.Viewer.name ?? "", // Provide default empty string
                        about: response.data.Viewer.about ?? "",
                        avatar: avatarURL
                    )
                    self.user = fetchedUser
                    completion?(fetchedUser)
                    
                case .failure(let error):
                    print("❌ Error fetching user: \(error)")
                    completion?(nil)
                }
            }
        }
    }
    
    func updateUser(name: String, about: String, token: String) {
        // Escape special characters in the strings
        let escapedName = name.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedAbout = about.replacingOccurrences(of: "\"", with: "\\\"")
        
        let mutation = """
        mutation {
          SaveUser(name: "\(escapedName)", about: "\(escapedAbout)") {
            id
            name
            about
          }
        }
        """
        
        AniListAPI.performGraphQL(query: mutation, token: token) { (result: Result<UpdateUserResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("✅ Updated: \(response.data.saveUser.name)")
                    self.user?.name = response.data.saveUser.name
                    self.user?.about = response.data.saveUser.about ?? ""
                case .failure(let error):
                    print("❌ Failed to update: \(error)")
                }
            }
        }
    }
}
