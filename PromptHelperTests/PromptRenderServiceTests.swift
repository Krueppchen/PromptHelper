//
//  PromptRenderServiceTests.swift
//  PromptHelperTests
//
//  Created by Claude Code on 2025-11-14.
//

import XCTest
@testable import PromptHelper

final class PromptRenderServiceTests: XCTestCase {
    var sut: PromptRenderService!

    override func setUp() {
        super.setUp()
        sut = PromptRenderService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Basic Rendering Tests

    func testRender_withValidValues_shouldReplaceAllPlaceholders() {
        // Given
        let template = PromptTemplate(
            title: "Test Template",
            content: "Hello {{name}}, you are {{age}} years old."
        )

        let values = [
            "name": "Alice",
            "age": "30"
        ]

        // When
        let result = sut.render(template: template, with: values)

        // Then
        switch result {
        case .success(let rendered):
            XCTAssertEqual(rendered, "Hello Alice, you are 30 years old.")
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }

    func testRender_withMissingValue_shouldReturnError() {
        // Given
        let template = PromptTemplate(
            title: "Test Template",
            content: "Hello {{name}}, you are {{age}} years old."
        )

        let values = [
            "name": "Alice"
            // "age" is missing
        ]

        // When
        let result = sut.render(template: template, with: values)

        // Then
        switch result {
        case .success:
            XCTFail("Expected error but got success")
        case .failure(let error):
            XCTAssertTrue(error.localizedDescription.contains("age"))
        }
    }

    func testRender_withEmptyTemplate_shouldReturnEmptyString() {
        // Given
        let template = PromptTemplate(
            title: "Test Template",
            content: ""
        )

        let values: [String: String] = [:]

        // When
        let result = sut.render(template: template, with: values)

        // Then
        switch result {
        case .success(let rendered):
            XCTAssertEqual(rendered, "")
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }

    func testRender_withNoPlaceholders_shouldReturnOriginalContent() {
        // Given
        let template = PromptTemplate(
            title: "Test Template",
            content: "This is a template without placeholders."
        )

        let values: [String: String] = [:]

        // When
        let result = sut.render(template: template, with: values)

        // Then
        switch result {
        case .success(let rendered):
            XCTAssertEqual(rendered, "This is a template without placeholders.")
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }

    // MARK: - Validation Tests

    func testValidateValue_withValidNumber_shouldReturnNil() {
        // Given
        let placeholder = PlaceholderDefinition(
            key: "age",
            label: "Age",
            type: .number
        )

        // When
        let error = sut.validateValue("42", for: placeholder)

        // Then
        XCTAssertNil(error)
    }

    func testValidateValue_withInvalidNumber_shouldReturnError() {
        // Given
        let placeholder = PlaceholderDefinition(
            key: "age",
            label: "Age",
            type: .number
        )

        // When
        let error = sut.validateValue("not a number", for: placeholder)

        // Then
        XCTAssertNotNil(error)
    }

    func testValidateValue_withValidSingleChoice_shouldReturnNil() {
        // Given
        let placeholder = PlaceholderDefinition(
            key: "color",
            label: "Color",
            type: .singleChoice,
            options: ["Red", "Green", "Blue"]
        )

        // When
        let error = sut.validateValue("Red", for: placeholder)

        // Then
        XCTAssertNil(error)
    }

    func testValidateValue_withInvalidSingleChoice_shouldReturnError() {
        // Given
        let placeholder = PlaceholderDefinition(
            key: "color",
            label: "Color",
            type: .singleChoice,
            options: ["Red", "Green", "Blue"]
        )

        // When
        let error = sut.validateValue("Yellow", for: placeholder)

        // Then
        XCTAssertNotNil(error)
    }

    // MARK: - Preview Tests

    func testPreview_withPartialValues_shouldShowRemainingPlaceholders() {
        // Given
        let template = PromptTemplate(
            title: "Test Template",
            content: "Hello {{name}}, you are {{age}} years old and live in {{city}}."
        )

        let values = [
            "name": "Alice"
        ]

        // When
        let preview = sut.preview(template: template, with: values)

        // Then
        XCTAssertEqual(preview, "Hello Alice, you are {{age}} years old and live in {{city}}.")
    }

    func testPreview_withAllValues_shouldShowFullyRendered() {
        // Given
        let template = PromptTemplate(
            title: "Test Template",
            content: "Hello {{name}}, you are {{age}} years old."
        )

        let values = [
            "name": "Alice",
            "age": "30"
        ]

        // When
        let preview = sut.preview(template: template, with: values)

        // Then
        XCTAssertEqual(preview, "Hello Alice, you are 30 years old.")
    }
}
