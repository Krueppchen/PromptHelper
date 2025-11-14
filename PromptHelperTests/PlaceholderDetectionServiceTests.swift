//
//  PlaceholderDetectionServiceTests.swift
//  PromptHelperTests
//
//  Created by Claude Code on 2025-11-14.
//

import XCTest
@testable import PromptHelper

final class PlaceholderDetectionServiceTests: XCTestCase {
    var sut: PlaceholderDetectionService!

    override func setUp() {
        super.setUp()
        sut = PlaceholderDetectionService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Detection Tests

    func testDetectPlaceholderKeys_withMultiplePlaceholders_shouldReturnAllKeys() {
        // Given
        let template = PromptTemplate(
            title: "Test Template",
            content: "Hello {{name}}, you are {{age}} years old and live in {{city}}."
        )

        // When
        let keys = sut.detectPlaceholderKeys(in: template)

        // Then
        XCTAssertEqual(keys.count, 3)
        XCTAssertTrue(keys.contains("name"))
        XCTAssertTrue(keys.contains("age"))
        XCTAssertTrue(keys.contains("city"))
    }

    func testDetectPlaceholderKeys_withDuplicates_shouldReturnUniqueKeys() {
        // Given
        let template = PromptTemplate(
            title: "Test Template",
            content: "Hello {{name}}, nice to meet you {{name}}!"
        )

        // When
        let keys = sut.detectPlaceholderKeys(in: template)

        // Then
        XCTAssertEqual(keys.count, 1)
        XCTAssertEqual(keys.first, "name")
    }

    func testDetectPlaceholderKeys_withNoPlaceholders_shouldReturnEmptyArray() {
        // Given
        let template = PromptTemplate(
            title: "Test Template",
            content: "This is a template without placeholders."
        )

        // When
        let keys = sut.detectPlaceholderKeys(in: template)

        // Then
        XCTAssertTrue(keys.isEmpty)
    }

    func testDetectPlaceholderKeys_withWhitespaceInPlaceholders_shouldTrimWhitespace() {
        // Given
        let template = PromptTemplate(
            title: "Test Template",
            content: "Hello {{ name }}, you are {{ age }} years old."
        )

        // When
        let keys = sut.detectPlaceholderKeys(in: template)

        // Then
        XCTAssertEqual(keys.count, 2)
        XCTAssertTrue(keys.contains("name"))
        XCTAssertTrue(keys.contains("age"))
    }

    // MARK: - Validation Tests

    func testIsValidPlaceholderKey_withValidKey_shouldReturnTrue() {
        // Given
        let validKeys = [
            "name",
            "user_name",
            "user-name",
            "userName123",
            "age"
        ]

        // When & Then
        for key in validKeys {
            XCTAssertTrue(sut.isValidPlaceholderKey(key), "Expected '\(key)' to be valid")
        }
    }

    func testIsValidPlaceholderKey_withInvalidKey_shouldReturnFalse() {
        // Given
        let invalidKeys = [
            "user name",  // contains space
            "user@name",  // contains @
            "user.name",  // contains .
            "user/name",  // contains /
            ""            // empty
        ]

        // When & Then
        for key in invalidKeys {
            XCTAssertFalse(sut.isValidPlaceholderKey(key), "Expected '\(key)' to be invalid")
        }
    }

    // MARK: - Key Suggestion Tests

    func testSuggestKey_fromGermanLabel_shouldConvertUmlauts() {
        // Given
        let label = "Größe und Länge"

        // When
        let key = sut.suggestKey(from: label)

        // Then
        XCTAssertEqual(key, "groesse_und_laenge")
    }

    func testSuggestKey_fromLabelWithSpaces_shouldReplaceWithUnderscores() {
        // Given
        let label = "User Name"

        // When
        let key = sut.suggestKey(from: label)

        // Then
        XCTAssertEqual(key, "user_name")
    }

    func testSuggestKey_fromLabelWithSpecialChars_shouldRemoveSpecialChars() {
        // Given
        let label = "User@Name!"

        // When
        let key = sut.suggestKey(from: label)

        // Then
        XCTAssertEqual(key, "username")
    }

    func testSuggestKey_shouldConvertToLowercase() {
        // Given
        let label = "UserName"

        // When
        let key = sut.suggestKey(from: label)

        // Then
        XCTAssertEqual(key, "username")
    }
}
