//
//  AnimeImageView.swift
//  Aira
//
//  Created by Gayathri Gondi on 18/07/25.
//


// Views/Components/AnimeImageView.swift
import SwiftUI

struct AnimeImageView: View {
    let url: String
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 100, height: 140)
        .clipped()
        .cornerRadius(10)
        .onAppear { loadImage() }
    }
    
    private func loadImage() {
        guard let imageURL = URL(string: url) else {
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: imageURL) { data, _, _ in
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = uiImage
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }.resume()
    }
}

// Preview provider
#Preview {
    AnimeImageView(url: "https://example.com/anime.jpg")
        .frame(width: 100, height: 140)
}