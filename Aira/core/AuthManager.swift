import Foundation
import Security
import SwiftUI
import UIKit

// MARK: - 🔐 Keychain Helpers

private let tokenKey = "anilist_token"
private let serviceID = "com.aira.anilist"

func saveToken(_ token: String) {
    let data = token.data(using: .utf8)!
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: tokenKey,
        kSecAttrService as String: serviceID,
        kSecValueData as String: data
    ]
    SecItemDelete(query as CFDictionary)
    SecItemAdd(query as CFDictionary, nil)
}

func loadToken() -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: tokenKey,
        kSecAttrService as String: serviceID,
        kSecReturnData as String: true,
        kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    if status == errSecSuccess,
       let data = item as? Data,
       let token = String(data: data, encoding: .utf8) {
        return token
    }

    return nil
}

func clearToken() {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: tokenKey,
        kSecAttrService as String: serviceID
    ]
    SecItemDelete(query as CFDictionary)
}

// MARK: - 🧠 Token Expiry Check

func isTokenExpired(_ token: String) -> Bool {
    let segments = token.split(separator: ".")
    guard segments.count >= 2 else { return true }

    var base64 = String(segments[1])
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")

    while base64.count % 4 != 0 {
        base64 += "="
    }

    guard let payloadData = Data(base64Encoded: base64),
          let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
          let exp = payload["exp"] as? TimeInterval else {
        return true
    }

    return Date().timeIntervalSince1970 > exp
}

// MARK: - 🔑 Auth Manager

class AuthManager: ObservableObject {
    @Published var accessToken: String?
    @Published var isExchangingCode = false

    init() {
        print("🔄 AuthManager init()")
        let token = loadToken()
        print("📦 Loaded token: \(token ?? "nil")")
        
        if let token = token, !isTokenExpired(token) {
            print("✅ Valid token found")
            self.accessToken = token
        } else {
            print("🧹 No valid token. Clearing and setting to nil")
            clearToken()
            self.accessToken = nil
        }
    }

    func startLogin() {
        guard let url = URL(string: "https://anilist.co/api/v2/oauth/authorize?client_id=27952&redirect_uri=AirA://anilist-callback&response_type=code") else { return }
        UIApplication.shared.open(url)
    }

    func handleRedirect(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            print("❌ No auth code found in redirect URL.")
            return
        }

        print("🚀 Got new auth code: \(code)")
        clearToken()
        getAccessToken(from: code)
    }

    func getAccessToken(from code: String) {
        guard !isExchangingCode else {
            print("⚠️ Already exchanging token. Skipping duplicate call.")
            return
        }

        isExchangingCode = true

        let clientID = "27952"
        let clientSecret = "RXSuyZwhMuoAz4sTFLWPZ3ov8XUA7zNVy7mksfQK"
        let redirectURI = "AirA://anilist-callback"

        guard let tokenURL = URL(string: "https://anilist.co/api/v2/oauth/token") else {
            isExchangingCode = false
            return
        }

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        let body = "grant_type=authorization_code&client_id=\(clientID)&client_secret=\(clientSecret)&redirect_uri=\(redirectURI)&code=\(code)"
        request.httpBody = body.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isExchangingCode = false
            }

            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("❌ No data received.")
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = json["access_token"] as? String {
                DispatchQueue.main.async {
                    self.accessToken = token
                    saveToken(token)
                    print("✅ Access Token: \(token)")
                }
            } else {
                let responseText = String(data: data, encoding: .utf8) ?? "Unreadable"
                print("❌ Failed to parse token. Response: \(responseText)")
            }
        }.resume()
    }

    func logout() {
        clearToken()
        accessToken = nil
    }

    // 🧪 Debug token (optional)
    func debugTokenStatus() {
        if let token = loadToken() {
            print("🧪 Token Exists. Expired? \(isTokenExpired(token))")
        } else {
            print("❌ No token found.")
        }
    }
}
