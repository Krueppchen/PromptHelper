//
//  StringExtensionTests.swift
//  PromptHelperTests
//
//  Created by Claude Code on 2025-11-14.
//

import XCTest
@testable import PromptHelper

final class StringExtensionTests: XCTestCase {

    // MARK: - extractPlaceholderKeys Tests

    func testExtractPlaceholderKeys_withMultiplePlaceholders_shouldReturnAllKeys() {
        // Given
        let text = "Hello {{name}}, you are {{age}} years old."

        // When
        let keys = text.extractPlaceholderKeys()

        // Then
        XCTAssertEqual(keys.count, 2)
        XCTAssertTrue(keys.contains("name"))
        XCTAssertTrue(keys.contains("age"))
    }

    func testExtractPlaceholderKeys_withNoPlaceholders_shouldReturnEmpty() {
        // Given
        let text = "Hello, this has no placeholders."

        // When
        let keys = text.extractPlaceholderKeys()

        // Then
        XCTAssertTrue(keys.isEmpty)
    }

    func testExtractPlaceholderKeys_withNestedBraces_shouldExtractCorrectly() {
        // Given
        let text = "Test {{outer}} and {{inner}}"

        // When
        let keys = text.extractPlaceholderKeys()

        // Then
        XCTAssertEqual(keys.count, 2)
        XCTAssertTrue(keys.contains("outer"))
        XCTAssertTrue(keys.contains("inner"))
    }

    // MARK: - replacingPlaceholders Tests

    func testReplacingPlaceholders_withValidValues_shouldReplaceAll() {
        // Given
        let text = "Hello {{name}}, you are {{age}} years old."
        let values = [
            "name": "Alice",
            "age": "30"
        ]

        // When
        let result = text.replacingPlaceholders(with: values)

        // Then
        XCTAssertEqual(result, "Hello Alice, you are 30 years old.")
    }

    func testReplacingPlaceholders_withPartialValues_shouldReplaceOnlyProvided() {
        // Given
        let text = "Hello {{name}}, you are {{age}} years old."
        let values = [
            "name": "Alice"
        ]

        // When
        let result = text.replacingPlaceholders(with: values)

        // Then
        XCTAssertEqual(result, "Hello Alice, you are {{age}} years old.")
    }

    func testReplacingPlaceholders_withEmptyValues_shouldNotReplace() {
        // Given
        let text = "Hello {{name}}, you are {{age}} years old."
        let values: [String: String] = [:]

        // When
        let result = text.replacingPlaceholders(with: values)

        // Then
        XCTAssertEqual(result, text)
    }

    func testReplacingPlaceholders_withExtraValues_shouldOnlyReplaceMatching() {
        // Given
        let text = "Hello {{name}}!"
        let values = [
            "name": "Alice",
            "age": "30",  // not in template
            "city": "Berlin"  // not in template
        ]

        // When
        let result = text.replacingPlaceholders(with: values)

        // Then
        XCTAssertEqual(result, "Hello Alice!")
    }

    // MARK: - hasUnfilledPlaceholders Tests

    func testHasUnfilledPlaceholders_withPlaceholders_shouldReturnTrue() {
        // Given
        let text = "Hello {{name}}, you are {{age}} years old."

        // When
        let hasUnfilled = text.hasUnfilledPlaceholders()

        // Then
        XCTAssertTrue(hasUnfilled)
    }

    func testHasUnfilledPlaceholders_withoutPlaceholders_shouldReturnFalse() {
        // Given
        let text = "Hello Alice, you are 30 years old."

        // When
        let hasUnfilled = text.hasUnfilledPlaceholders()

        // Then
        XCTAssertFalse(hasUnfilled)
    }

    // MARK: - isValidPlaceholderKey Tests

    func testIsValidPlaceholderKey_withValidKeys_shouldReturnTrue() {
        // Given
        let validKeys = [
            "name",
            "user_name",
            "user-name",
            "userName123"
        ]

        // When & Then
        for key in validKeys {
            XCTAssertTrue(key.isValidPlaceholderKey(), "Expected '\(key)' to be valid")
        }
    }

    func testIsValidPlaceholderKey_withInvalidKeys_shouldReturnFalse() {
        // Given
        let invalidKeys = [
            "user name",   // space
            "user@name",   // @
            "user.name",   // .
            "",            // empty
            "user/name"    // /
        ]

        // When & Then
        for key in invalidKeys {
            XCTAssertFalse(key.isValidPlaceholderKey(), "Expected '\(key)' to be invalid")
        }
    }
}
