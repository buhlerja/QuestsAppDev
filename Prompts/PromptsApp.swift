//
//  PromptsApp.swift
//  Prompts
//
//  Created by Jack Buhler on 2024-05-19.
//

import SwiftUI
import SwiftData

@main
struct PromptsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            QuestView(quests: QuestStruc.sampleData)
        }
        .modelContainer(sharedModelContainer)
    }
}
