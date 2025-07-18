import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var viewModel = SettingsViewModel()

    @State private var updatedName: String = ""
    @State private var updatedAbout: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let user = viewModel.user {
                    // Avatar
                    AsyncImage(url: URL(string: user.avatar)) { image in
                        image.resizable()
                             .aspectRatio(contentMode: .fill)
                             .frame(width: 100, height: 100)
                             .clipShape(Circle())
                    } placeholder: {
                        ProgressView()
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Username")
                            .font(.headline)
                        TextField("Username", text: $updatedName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Text("About")
                            .font(.headline)
                        TextEditor(text: $updatedAbout)
                            .frame(height: 100)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                    }
                    .padding()

                    Button("Save Changes") {
                        viewModel.updateUser(
                            name: updatedName,
                            about: updatedAbout,
                            token: authManager.accessToken ?? ""
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)

                    Button("Log Out") {
                        authManager.logout()
                    }
                    .foregroundColor(.red)
                    .padding(.top, 30)
                } else {
                    ProgressView("Loading user info...")
                        .onAppear {
                            if let token = authManager.accessToken {
                                viewModel.fetchUser(token: token) { fetchedUser in
                                    if let user = fetchedUser {
                                        updatedName = user.name
                                        updatedAbout = user.about
                                    }
                                }
                            }
                        }
                }
            }
            .padding()
        }
        .background(AppColors.background)
        .navigationTitle("Settings")
    }
}
