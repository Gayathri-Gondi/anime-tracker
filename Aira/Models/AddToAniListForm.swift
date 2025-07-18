import SwiftUI

struct AddToAniListForm: View {
    let anime: SearchAnime
    var onSubmit: (_ status: String, _ score: Int, _ progress: Int) -> Void

    @Environment(\.dismiss) var dismiss

    @State private var status = "CURRENT"
    @State private var score = 0
    @State private var progress = 0

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Status")) {
                    Picker("Status", selection: $status) {
                        Text("Watching").tag("CURRENT")
                        Text("Completed").tag("COMPLETED")
                        Text("Paused").tag("PAUSED")
                        Text("Dropped").tag("DROPPED")
                        Text("Plan to Watch").tag("PLANNING")
                    }
                    .pickerStyle(.menu)
                }

                Section(header: Text("Score (0–100)")) {
                    Stepper(value: $score, in: 0...100, step: 1) {
                        Text("\(score)")
                    }
                }

                Section(header: Text("Episodes Watched")) {
                    Stepper(value: $progress, in: 0...1000, step: 1) {
                        Text("\(progress)")
                    }
                }
            }
            .navigationTitle("Add to AniList")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSubmit(status, score, progress)
                        dismiss()
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddToAniListForm(anime: SearchAnime(id: 1, title: "Sample Anime", imageURL: "")) { status, score, progress in
        print("Status: \(status), Score: \(score), Progress: \(progress)")
    }
}
