//
//  PromptHelperApp.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import SwiftUI
import SwiftData

@main
struct PromptHelperApp: App {
    /// Persistence Controller für SwiftData
    @State private var persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(persistenceController.container)
        }
    }
}

/// Haupt-View der App mit Tab-Navigation
struct ContentView: View {
    var body: some View {
        TabView {
            // Tab 1: Prompt-Liste
            NavigationStack {
                PromptListView()
            }
            .tabItem {
                Label("Prompts", systemImage: "doc.text")
            }

            // Tab 2: Platzhalter-Verwaltung
            NavigationStack {
                PlaceholderListView()
            }
            .tabItem {
                Label("Platzhalter", systemImage: "curlybraces")
            }
        }
    }
}

// MARK: - Previews

#Preview {
    ContentView()
        .modelContainer(PersistenceController.preview.container)
}
