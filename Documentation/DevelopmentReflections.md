# To-Do App – Development Reflections

## Goals
- Build a small but complete iOS To-Do app that feels polished and intentional.
- Exercise modern SwiftUI patterns:
  - `NavigationStack`
  - Custom modifiers/components
  - Gesture-driven interactions
- Use Core Data for offline-capable persistence.

## Key Design Decisions

### 1. Core Data vs. Simpler Storage
- **Why Core Data**: The assignment calls for Core Data or Realm and offline support. Core Data integrates well with SwiftUI via `@FetchRequest` and the environment context.
- **Impact**: Allows previews with seeded data and simple mutation flows. For a small app, the overhead is acceptable and provides a realistic foundation for growth.

### 2. Single `Item` Entity
- Chose to keep a single `Item` entity instead of multiple related entities (e.g. `Category`).
- Pros:
  - Simpler schema and migration story.
  - Enough flexibility for a personal task manager.
- Cons:
  - No strong referential integrity for categories; they are strings.

### 3. Computed Properties on `Item`
- Introduced an extension that wraps Core Data attributes (`title`, `priority`, etc.) in Swift properties like `taskTitle`, `taskPriority`.
- Benefits:
  - Views do not depend on raw Core Data attributes or KVC.
  - Central place to apply defaults and derive values (e.g. `isOverdue`).

### 4. Navigation Structure
- `TabView` at the root with two `NavigationStack`s:
  - Keeps concerns separated: managing tasks vs. configuring the app.
  - Each stack manages its own history, which matches user expectations.

### 5. Creation Flow via Sheet
- Creating a task opens a sheet with a nested `NavigationStack`.
- Rationale:
  - Keeps the main list visible underneath.
  - Mirrors many system apps where creation appears modally.

## UI & UX Considerations

### Card-Based Task Rows
- Implemented a reusable `TaskCardModifier` and `taskCard` view extension.
- The goal was to:
  - Provide visual hierarchy.
  - Convey priority through color and shadow without overwhelming the content.

### Gestures
- Added a right-swipe gesture on rows to toggle completion.
- Combined with button-based toggling for discoverability.

### Accessibility
- Paid attention to:
  - Combined accessibility labels for rows.
  - Layout changes when Dynamic Type enters accessibility sizes.
  - Using system colors for Dark Mode compatibility.

## What Went Well
- SwiftUI’s `@FetchRequest` and Core Data integration makes data-driven lists straightforward.
- Using `@AppStorage` for settings kept configuration simple and automatically persisted.
- The modular split into `TaskModel`, `TaskComponents`, `TaskListView`, `TaskDetailView`, and `SettingsView` made it easier to reason about responsibilities.

## Potential Improvements
- **Predicates in Fetch Requests**
  - Currently, filtering is done in-memory on the fetched items. For very large datasets, moving some of the filtering into the Core Data fetch predicate would improve performance.

- **User-Defined Categories**
  - Allow users to create and rename categories instead of relying on a static list.

- **Reminders & Notifications**
  - Integrate with `UserNotifications` to alert users when tasks are near their due date.

- **Cloud Sync**
  - Introduce a CloudKit-backed store to sync tasks across devices while reusing most of the existing Core Data stack.

- **Testing**
  - Add unit tests for the `Item` extensions and UI tests for critical flows (creating, editing, deleting tasks).

## Summary
The resulting app balances simplicity and structure: a single-entity Core Data model, a clear navigation hierarchy with `NavigationStack`, and a focused feature set that still demonstrates modern SwiftUI capabilities. It is intentionally small but designed to be extended in realistic directions.
