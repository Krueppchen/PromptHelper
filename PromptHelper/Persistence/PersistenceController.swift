//
//  PersistenceController.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import Foundation
import SwiftData

/// Controller für die SwiftData-Persistenz
/// Verwaltet den ModelContainer und stellt Hilfsfunktionen bereit
@MainActor
final class PersistenceController {
    /// Shared Singleton-Instanz
    static let shared = PersistenceController()

    /// Der SwiftData ModelContainer
    let container: ModelContainer

    /// Main ModelContext für UI-Operationen
    var mainContext: ModelContext {
        container.mainContext
    }

    // MARK: - Initialisierung

    /// Initializes the PersistenceController singleton and configures the SwiftData stack.
    /// 
    /// Responsibilities:
    /// - Defines the app's data model schema (PromptTemplate, PlaceholderDefinition, PromptTemplatePlaceholder, PromptInstance).
    /// - Creates a persistent ModelContainer with on-disk storage and saving enabled.
    /// - In DEBUG builds, seeds the store with sample data if it's empty (asynchronously).
    ///
    /// Behavior:
    /// - Uses a fatalError if the ModelContainer cannot be created, as this is a critical, unrecoverable setup failure.
    /// - Exposes the container's mainContext for use on the main actor (UI-bound operations).
    ///
    /// Threading:
    /// - Marked @MainActor to ensure initialization and subsequent mainContext access occur on the main thread.
    ///
    /// Notes:
    /// - For previews and tests, prefer using the `preview` static property or the `init(inMemory:)` initializer to avoid
    ///   writing to disk and to produce deterministic sample data.
    private init() {
        let schema = Schema([
            PromptTemplate.self,
            PlaceholderDefinition.self,
            PromptTemplatePlaceholder.self,
            PromptInstance.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        // Seed-Daten für Entwicklung/Testing (nur wenn leer)
        #if DEBUG
        Task {
            await seedDataIfNeeded()
        }
        #endif
    }

    /// Preview-Container für SwiftUI-Previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        Task { @MainActor in
            await controller.createSampleData()
        }
        return controller
    }()

    /// Initialisierung für In-Memory-Datenbank (Testing/Previews)
    private init(inMemory: Bool) {
        let schema = Schema([
            PromptTemplate.self,
            PlaceholderDefinition.self,
            PromptTemplatePlaceholder.self,
            PromptInstance.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            allowsSave: !inMemory
        )

        do {
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    // MARK: - Seed Data

    /// Erstellt Beispieldaten, wenn die Datenbank leer ist
    private func seedDataIfNeeded() async {
        let context = mainContext

        // Prüfe, ob bereits Daten vorhanden sind
        let descriptor = FetchDescriptor<PromptTemplate>()
        let existingTemplates = try? context.fetch(descriptor)

        if existingTemplates?.isEmpty == true {
            await createSampleData()
        }
    }

    /// Erstellt Beispieldaten für Demo und Testing
    func createSampleData() async {
        let context = mainContext

        // Beispiel-Platzhalter erstellen
        let targetAudiencePlaceholder = PlaceholderDefinition(
            key: "zielgruppe",
            label: "Zielgruppe",
            type: .text,
            isGlobal: true,
            descriptionText: "Die Zielgruppe für den Content"
        )

        let topicPlaceholder = PlaceholderDefinition(
            key: "thema",
            label: "Thema",
            type: .text,
            isGlobal: true,
            descriptionText: "Das Hauptthema des Contents"
        )

        let tonePlaceholder = PlaceholderDefinition(
            key: "tonalitaet",
            label: "Tonalität",
            type: .singleChoice,
            options: ["Professionell", "Freundlich", "Witzig", "Sachlich"],
            isGlobal: true,
            descriptionText: "Der Ton der Kommunikation"
        )

        let lengthPlaceholder = PlaceholderDefinition(
            key: "laenge",
            label: "Länge",
            type: .singleChoice,
            options: ["Kurz (100 Wörter)", "Mittel (250 Wörter)", "Lang (500 Wörter)"],
            isGlobal: true
        )

        context.insert(targetAudiencePlaceholder)
        context.insert(topicPlaceholder)
        context.insert(tonePlaceholder)
        context.insert(lengthPlaceholder)

        // Beispiel-Template erstellen
        let blogPostTemplate = PromptTemplate(
            title: "Blog-Post Generator",
            descriptionText: "Generiert einen Blog-Post für eine bestimmte Zielgruppe",
            content: """
            Schreibe einen Blog-Post über das Thema "{{thema}}" für die Zielgruppe "{{zielgruppe}}".

            Der Tonfall soll {{tonalitaet}} sein.
            Die Länge sollte {{laenge}} betragen.

            Strukturiere den Post wie folgt:
            1. Einleitung mit Hook
            2. Hauptteil mit konkreten Beispielen
            3. Zusammenfassung und Call-to-Action
            """,
            tags: ["Blog", "Content Marketing", "Text"],
            isFavorite: true
        )

        context.insert(blogPostTemplate)

        // Platzhalter-Zuordnungen erstellen
        let placeholder1 = PromptTemplatePlaceholder(
            template: blogPostTemplate,
            placeholder: topicPlaceholder,
            isRequired: true,
            sortOrder: 0
        )

        let placeholder2 = PromptTemplatePlaceholder(
            template: blogPostTemplate,
            placeholder: targetAudiencePlaceholder,
            isRequired: true,
            sortOrder: 1
        )

        let placeholder3 = PromptTemplatePlaceholder(
            template: blogPostTemplate,
            placeholder: tonePlaceholder,
            isRequired: true,
            sortOrder: 2
        )

        let placeholder4 = PromptTemplatePlaceholder(
            template: blogPostTemplate,
            placeholder: lengthPlaceholder,
            isRequired: false,
            sortOrder: 3
        )

        context.insert(placeholder1)
        context.insert(placeholder2)
        context.insert(placeholder3)
        context.insert(placeholder4)

        // Weiteres Beispiel-Template
        let emailTemplate = PromptTemplate(
            title: "Marketing E-Mail",
            descriptionText: "Erstellt eine Marketing-E-Mail",
            content: """
            Schreibe eine Marketing-E-Mail zum Thema "{{thema}}" für {{zielgruppe}}.

            Die E-Mail soll {{tonalitaet}} formuliert sein und zum Handeln auffordern.
            """,
            tags: ["E-Mail", "Marketing"],
            isFavorite: false
        )

        context.insert(emailTemplate)

        // Speichern
        do {
            try context.save()
        } catch {
            print("Error creating sample data: \(error)")
        }
    }
}
