//
//  ALHelpers.swift
//  Aira
//
//  Created by Gayathri Gondi on 29/06/25.
//

import Foundation

func extractCode(from url: URL) -> String? {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let queryItem = components.queryItems?.first(where: { $0.name == "code" }) else {
        return nil
    }
    return queryItem.value
}

func exchangeCodeForToken(code: String, completion: @escaping (String) -> Void) {
    let clientID = "27952"
    let clientSecret = "RXSuyZwhMuoAz4sTFLWPZ3ov8XUA7zNVy7mksfQK"
    let redirectURI = "AirA://anilist-callback"
    let url = URL(string: "https://anilist.co/api/v2/oauth/token")!

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    let body = [
        "grant_type": "authorization_code",
        "client_id": clientID,
        "client_secret": clientSecret,
        "redirect_uri": redirectURI,
        "code": code
    ]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("❌ Token exchange error: \(error.localizedDescription)")
            return
        }

        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            print("❌ Failed to extract token")
            return
        }

        DispatchQueue.main.async {
            completion(accessToken)
        }
    }.resume()
}
