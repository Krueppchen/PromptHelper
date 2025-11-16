# CLAUDE.md - AI Assistant Guide for PromptHelper

**Last Updated:** 2025-11-16
**Project:** PromptHelper - iOS/macOS Prompt Template Management Application
**Tech Stack:** SwiftUI, SwiftData, Swift 5.9+

---

## Project Overview

**PromptHelper** is an iOS/macOS application that helps users create, manage, and generate prompt templates with dynamic placeholders. Users can:

- Create reusable prompt templates with `{{placeholder}}` syntax
- Define global and template-specific placeholder definitions with validation
- Generate final prompts by filling in placeholder values
- Manage a library of templates with tags, favorites, and search
- Track generated prompt history

**Primary Use Case:** Streamline AI prompt creation through a structured template system with intelligent placeholder detection and synchronization.

---

## Architecture Overview

### Design Pattern: MVVM (Model-View-ViewModel)

```
PromptHelper/
├── Models/                    # SwiftData models
├── ViewModels/               # Business logic & state (@Observable)
├── Views/                    # SwiftUI presentation layer
├── Components/               # Reusable UI components
├── Services/                 # Business logic services
├── Persistence/              # SwiftData stack
├── Design/                   # Design system tokens
└── Utilities/                # Extensions & error handling
```

### Key Technologies
- **UI Framework:** SwiftUI
- **Data Persistence:** SwiftData (on-disk SQLite)
- **State Management:** @Observable macro, @State, @Query
- **Testing:** XCTest (Unit + UI)
- **Language:** Swift 5.9+, German localization

---

## Core Data Models

All models use SwiftData with @Model macro:

| Model | Purpose | Key Properties |
|-------|---------|----------------|
| **PromptTemplate** | Main template entity | `title`, `content`, `descriptionText`, `tags`, `isFavorite`, `placeholders` relationship |
| **PlaceholderDefinition** | Placeholder config | `key`, `label`, `type`, `isRequired`, `isGlobal`, `defaultValue`, `options` |
| **PromptTemplatePlaceholder** | Many-to-many link | `template`, `placeholder`, `sortOrder`, `templateSpecificDefault` |
| **PromptInstance** | Generated prompt history | `template`, `filledValues` (JSON), `generatedText`, `createdAt` |
| **PlaceholderType** | Enum | `.text`, `.number`, `.date`, `.singleChoice`, `.multiChoice` |

### Important Relationships
- Templates → Placeholders: Many-to-many through `PromptTemplatePlaceholder`
- Templates → Instances: One-to-many (cascade delete)
- PlaceholderDefinitions: Can be global or template-specific

---

## Key Conventions & Patterns

### 1. Placeholder Syntax

**Format:** `{{key}}`
- Double curly braces with trimmed content
- Keys: alphanumeric + underscore/dash only (`[a-zA-Z0-9_-]+`)
- Case-sensitive matching
- Duplicates allowed (same placeholder can appear multiple times)

**Example:**
```
Erstelle einen Blog-Post über {{thema}} für {{zielgruppe}}.
Der Ton sollte {{tonalitaet}} sein.
```

### 2. Automatic Placeholder Detection

**Service:** `PlaceholderDetectionService`

The app automatically detects placeholders using regex:
```swift
pattern: "\\{\\{\\s*([a-zA-Z0-9_-]+)\\s*\\}\\}"
```

**Auto-sync behavior:**
- Triggered with 1-second debounce after content changes
- Creates missing PlaceholderDefinition entries
- Creates PromptTemplatePlaceholder associations
- Handles duplicates intelligently
- Silent failure (no error dialogs for auto-sync)

**When modifying templates:** The system will automatically detect new placeholders and create associations.

### 3. ViewModels Pattern

All ViewModels use `@Observable` macro for reactive updates:

```swift
@Observable
class PromptListViewModel {
    var searchText = ""
    var selectedTags: Set<String> = []
    // ... properties are automatically observable
}
```

**Key ViewModels:**
- `PromptListViewModel` - Template CRUD, filtering, favorites
- `PromptEditorViewModel` - Template editing, auto-sync placeholders
- `PromptGeneratorViewModel` - Placeholder filling, rendering, clipboard
- `PlaceholderListViewModel` - Placeholder management, validation

### 4. Error Handling

All errors use centralized `AppError` enum:

```swift
enum AppError: LocalizedError {
    case invalidPlaceholderKey(String)
    case missingRequiredPlaceholder(String)
    case invalidNumberFormat(String)
    case renderingFailed(String)
    // ... localized in German
}
```

**Pattern:** Return `Result<Success, AppError>` for operations that can fail.

### 5. Validation Rules

**Placeholder Key Validation:**
- Must match: `^[a-zA-Z0-9_-]+$`
- Cannot be empty or whitespace-only
- Must be unique within scope (global vs. template-specific)

**Type-Specific Validation:**
- `.number`: Must be valid number format
- `.date`: Must be valid date
- `.singleChoice`: Must be one of defined options
- `.multiChoice`: Must be subset of defined options
- `.text`: No format validation (any string)

**Required Fields:**
- If `isRequired = true`, value must be non-empty before generation

### 6. German Localization

**Language Convention:**
- All UI text in German
- Code comments in German
- Error messages in German
- Consistent terminology:
  - Vorlage = Template
  - Platzhalter = Placeholder
  - Generieren = Generate
  - Erforderlich = Required

**When adding new features:** Use German for all user-facing text and comments.

---

## Design System (DesignSystem.swift)

### Spacing (4pt grid)
```swift
.xxs: 4pt    .xs: 8pt     .sm: 12pt    .md: 16pt
.lg: 20pt    .xl: 24pt    .xxl: 32pt   .xxxl: 40pt
```

### Typography
```swift
.largeTitle, .title, .title2, .title3
.headline, .body, .callout, .caption, .caption2
```

### Color Palette (WCAG AA Compliant)
```swift
Primary:   #7b45a1 (Deep Lilac, 5.5:1 contrast)
Secondary: #197278 (Stormy Teal, 5:1 contrast)
Success:   #6b9c7d (Muted Teal Dark, 4.5:1 contrast)
Warning:   #d4a574 (Warm Sand)
Error:     #c46c71 (Dusty Rose)
```

**Usage:**
```swift
.foregroundStyle(DesignSystem.Colors.primary)
.padding(DesignSystem.Spacing.md)
.cornerRadius(DesignSystem.CornerRadius.card)
```

### Animations
```swift
.quick    // 0.3s spring (0.7 damping)
.smooth   // 0.4s spring (0.8 damping)
.bouncy   // 0.5s spring (0.6 damping)
.gentle   // 0.3s easeInOut
```

**When creating UI:** Always use DesignSystem tokens instead of hardcoded values.

---

## Common Development Workflows

### Adding a New Feature

1. **Model Changes** (if needed)
   - Update SwiftData models in `Models/`
   - SwiftData handles migrations automatically
   - Test with sample data in DEBUG mode

2. **Service Layer** (if needed)
   - Add business logic to existing services or create new service
   - Keep services focused and testable
   - Return `Result<T, AppError>` for failable operations

3. **ViewModel**
   - Create or update ViewModel with `@Observable`
   - Keep ViewModels platform-independent (no View imports)
   - Add validation and error handling

4. **View**
   - Build SwiftUI view using DesignSystem tokens
   - Use existing components from `Components/` when possible
   - Follow existing patterns (cards, navigation, forms)

5. **Testing**
   - Add unit tests for services and utilities
   - Update UI tests if workflow changes
   - Test with sample data in simulator

### Modifying Template Rendering

**Key Files:**
- `PromptRenderService.swift` - Core rendering logic
- `PromptGeneratorViewModel.swift` - UI state for generation
- `PromptGeneratorView.swift` - Generation interface

**Testing:**
- Add tests to `PromptRenderServiceTests.swift`
- Test edge cases: missing values, type mismatches, empty templates

### Adding a New Placeholder Type

1. Add case to `PlaceholderType` enum
2. Update `PlaceholderInputView` with new input component
3. Add validation logic to `PromptRenderService`
4. Update `PlaceholderEditorView` for configuration
5. Add tests for new type

### Updating the Design System

**File:** `Design/DesignSystem.swift`

- Add new tokens to appropriate struct (Colors, Spacing, Typography, etc.)
- Ensure WCAG AA compliance for colors (4.5:1 contrast minimum)
- Add view extension helpers if needed
- Update this documentation

---

## File Organization Guidelines

### View Files
- Keep views focused on presentation
- Extract complex logic to ViewModels
- Reusable components → `Views/Components/`
- Screen-level views → `Views/`

### Naming Conventions
- Models: Noun (e.g., `PromptTemplate`)
- ViewModels: NounViewModel (e.g., `PromptListViewModel`)
- Views: NounView (e.g., `PromptEditorView`)
- Services: NounService (e.g., `PlaceholderDetectionService`)
- Extensions: Type+Category (e.g., `String+Placeholder`)

### Component Structure
```swift
struct ComponentView: View {
    // MARK: - Properties
    let requiredProp: String
    var optionalProp: String = "default"
    @State private var internalState = false

    // MARK: - Body
    var body: some View {
        // UI code
    }

    // MARK: - Private Methods
    private func helperMethod() { }
}
```

---

## Testing Guidelines

### Unit Tests

**Location:** `/PromptHelperTests/`

**Coverage priorities:**
1. Services (PlaceholderDetectionService, PromptRenderService)
2. Utilities (String extensions, validators)
3. ViewModels (business logic, validation)

**Pattern:**
```swift
final class ServiceTests: XCTestCase {
    var sut: ServiceName!  // System Under Test

    override func setUp() {
        super.setUp()
        sut = ServiceName()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testFeature_WhenCondition_ExpectedOutcome() {
        // Arrange
        let input = "test"

        // Act
        let result = sut.method(input)

        // Assert
        XCTAssertEqual(result, expected)
    }
}
```

**Existing Test Files:**
- `PlaceholderDetectionServiceTests.swift` - Detection logic
- `PromptRenderServiceTests.swift` - Rendering & validation
- `StringExtensionTests.swift` - String utilities

### UI Tests

**Location:** `/PromptHelperUITests/`

Basic launch and interaction tests. Expand as needed for critical user flows.

---

## SwiftData Patterns

### Querying Data

```swift
@Query(sort: \PromptTemplate.title)
var templates: [PromptTemplate]

@Query(filter: #Predicate<PlaceholderDefinition> { $0.isGlobal })
var globalPlaceholders: [PlaceholderDefinition]
```

### Inserting Data

```swift
let template = PromptTemplate(title: "New", content: "")
modelContext.insert(template)
```

### Deleting Data

```swift
modelContext.delete(template)  // Cascade deletes relationships
```

### Relationships

SwiftData handles relationships automatically:
```swift
// Access related data
template.placeholders  // Array of PromptTemplatePlaceholder
placeholder.templates  // Array of PromptTemplatePlaceholder
```

---

## Common Gotchas & Solutions

### 1. Placeholder Detection Not Triggering

**Issue:** Auto-sync not working after content change

**Solution:** Check `PromptEditorViewModel.detectAndSyncPlaceholders()`:
- Uses 1-second debounce with Task cancellation
- Ensure `onChange` modifier is attached to content TextField
- Task must be stored in `detectionTask` property

### 2. SwiftData Relationship Issues

**Issue:** Placeholders not appearing in template

**Solution:**
- Use `PromptTemplatePlaceholder` junction table, not direct relationship
- Ensure both sides of relationship are set correctly
- Check cascade delete rules

### 3. Form Validation Not Working

**Issue:** Required placeholders allowing empty values

**Solution:**
- Check `isRequired` flag on PlaceholderDefinition
- Validation happens in `PromptRenderService.renderPrompt()`
- PromptGeneratorViewModel should check validation before enabling copy

### 4. Design System Colors Not Showing

**Issue:** Custom colors appear as default system colors

**Solution:**
- Use `DesignSystem.Colors.primary` not `.primary`
- Ensure color values include both light/dark mode variants
- Check color asset catalog for missing definitions

### 5. Memory Leaks in ViewModels

**Issue:** ViewModels not deallocating

**Solution:**
- Use `[weak self]` in Task/async closures
- Cancel tasks in deinit or when view disappears
- Avoid circular references between ViewModel and Model

---

## Git Workflow

### Branch Strategy
- **Main branch:** `main` (production-ready code)
- **Feature branches:** `claude/descriptive-name-{session-id}`
- **Always develop on designated feature branch**

### Commit Guidelines

**Commit Message Format:**
```
[Type] Brief description (German or English)

- Detail 1
- Detail 2
```

**Types:**
- `[Feature]` - New functionality
- `[Fix]` - Bug fixes
- `[Refactor]` - Code restructuring
- `[Design]` - UI/UX improvements
- `[Test]` - Test additions/updates
- `[Docs]` - Documentation updates

**Recent patterns from git history:**
- "Verbessere Eingabefeld-Design und Benutzerführung"
- "Überarbeite Generieren-Menü und implementiere neue Farbpalette"
- "Fix CoreData migration error for tags attribute"

### Pre-Push Checklist
- [ ] All tests pass
- [ ] No compiler warnings
- [ ] Code follows existing patterns
- [ ] German localization for user-facing text
- [ ] DesignSystem tokens used (no hardcoded values)
- [ ] Comments added for complex logic

---

## Key Files Reference

### Must-Read Files
| File | Purpose | Why Important |
|------|---------|---------------|
| `PromptHelperApp.swift` | App entry point | Understand navigation structure |
| `Design/DesignSystem.swift` | Design tokens | All UI styling rules |
| `Models/PromptTemplate.swift` | Core model | Central data structure |
| `Services/PlaceholderDetectionService.swift` | Placeholder extraction | Core business logic |
| `Services/PromptRenderService.swift` | Template rendering | Core generation logic |

### Frequently Modified Files
- `Views/PromptGeneratorView.swift` (248 lines) - Generation UI
- `Views/PromptEditorView.swift` (268 lines) - Template editing
- `Views/Components/PlaceholderInputView.swift` (289 lines) - Dynamic inputs
- `ViewModels/PromptEditorViewModel.swift` - Template editing logic

---

## Accessibility Guidelines

### Color Contrast
- **Minimum:** WCAG AA (4.5:1 for normal text, 3:1 for large text)
- **Current compliance:** All design system colors meet WCAG AA
- **When adding colors:** Test with contrast checker

### Semantic Colors
- Use semantic colors (success, warning, error) consistently
- Don't rely on color alone for information
- Add text labels or icons for status

### Interactive Elements
- Minimum tap target: 44x44 points (iOS HIG)
- Clear focus indicators
- Descriptive labels for screen readers

---

## Performance Considerations

### SwiftData Best Practices
- Avoid loading entire relationship graphs unnecessarily
- Use `@Query` with filters to limit data fetch
- Consider pagination for large lists
- Use preview containers for SwiftUI previews (in-memory)

### Async Operations
- Use `@MainActor` for UI updates
- Cancel pending tasks when view disappears
- Debounce rapid user input (e.g., search, auto-sync)

### View Optimization
- Extract subviews to reduce body complexity
- Use `EquatableView` for expensive computations
- Avoid excessive `@State` dependencies
- Use `@Bindable` for Observable objects in bindings

---

## Quick Reference Commands

### Build & Run
```bash
# Open project
open PromptHelper.xcodeproj

# Run tests
xcodebuild test -scheme PromptHelper -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Common File Searches
```bash
# Find all ViewModels
find . -name "*ViewModel.swift"

# Find all Views
find . -name "*View.swift" -not -path "*/.*"

# Find placeholder-related code
grep -r "{{" --include="*.swift"
```

---

## Contact & Resources

### Documentation
- SwiftUI: https://developer.apple.com/documentation/swiftui
- SwiftData: https://developer.apple.com/documentation/swiftdata
- Swift 5.9: https://docs.swift.org/swift-book/

### Project-Specific Resources
- Git Repository: Current working directory
- Recent Commits: See git log for development patterns
- Sample Data: `PersistenceController.swift` line ~35-120

---

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2025-11-16 | Initial CLAUDE.md creation | Claude |
| 2025-11-16 | Added comprehensive architecture documentation | Claude |
| 2025-11-16 | Documented design system and conventions | Claude |

---

## Quick Start for AI Assistants

When working on this codebase:

1. **Read DesignSystem.swift first** - All UI work uses these tokens
2. **Check existing ViewModels** - Follow established patterns
3. **Use German for user-facing text** - Maintain localization consistency
4. **Test placeholder detection** - Core feature, easy to break
5. **Run unit tests** - Especially after service changes
6. **Follow MVVM strictly** - Keep Views dumb, logic in ViewModels
7. **Use Result types** - For operations that can fail
8. **Debounce user input** - Network/computation-heavy operations

**Most Common Tasks:**
- Adding template features → Modify `PromptEditorView` + `PromptEditorViewModel`
- Changing placeholder behavior → Modify `PlaceholderDetectionService` or `PromptRenderService`
- UI improvements → Use `DesignSystem` tokens, update `Components/`
- New placeholder types → Update `PlaceholderType` enum + related views

---

**End of CLAUDE.md**
