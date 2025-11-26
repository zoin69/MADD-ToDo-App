# To-Do App – Technical Design

## Stack
- **Language**: Swift
- **UI Framework**: SwiftUI
- **Persistence**: Core Data (+ NSPersistentContainer wrapper)
- **Target**: iPhone (supports Light/Dark Mode and Dynamic Type)

## Architecture Overview
- **Entry Point**: `ToDoApp` (conforming to `App`)
  - Creates a shared `PersistenceController`.
  - Injects `managedObjectContext` into the environment.
  - Hosts `ContentView` in a `WindowGroup`.

- **Root View**: `ContentView`
  - Contains a `TabView` with two `NavigationStack`s:
    - **Tasks Tab** → `TaskListView` and `TaskDetailView`.
    - **Settings Tab** → `SettingsView`.
  - Uses `@AppStorage` for:
    - `taskSortOption`
    - `taskDefaultCategory`
    - `taskHapticsEnabled`

## Data Model

### Core Data
- **Model file**: `ToDo.xcdatamodeld`
- **Entity**: `Item`
- **Attributes**:
  - `id: UUID` – unique identifier.
  - `title: String` – required task title.
  - `notes: String?` – optional extended description.
  - `category: String?` – category label.
  - `priority: Int16` – encoded `TaskPriority` value.
  - `dueDate: Date?` – optional due date.
  - `isCompleted: Bool` – completion state.
  - `timestamp: Date?` – creation or last-touched time.

### Persistence Helper
- **`PersistenceController`**
  - Wraps `NSPersistentContainer(name: "ToDo")`.
  - Adds `preview` static instance with seeded sample data for SwiftUI previews.
  - Enables `automaticallyMergesChangesFromParent` to reduce merge conflicts.

### Model Utilities (`TaskModel.swift`)
- **Enums**
  - `TaskPriority` (low, medium, high)
    - Maps to `Int16`.
    - Provides `title`, `systemImageName`, and SwiftUI `Color`.
  - `TaskSortOption` (dueDate, priority, title, createdAt)
    - Used with `@AppStorage` and `SettingsView`.

- **Static Helpers**
  - `TaskCategories` – canonical list of category strings.
  - `TaskFormatting` – shared `DateFormatter` and `RelativeDateTimeFormatter`.

- **`extension Item`**
  - Adds computed properties like `taskTitle`, `taskNotes`, `taskCategory`, `taskPriority`, `taskDueDate`, `taskIsCompleted`, `createdAt`, `isOverdue`, and `taskID`.
  - Encapsulates Core Data KVC access so views use type-safe Swift properties.

## UI Layer

### Root Navigation
- **`NavigationStack`**
  - Each tab has its own navigation stack to keep task navigation independent from settings.

### Task List (`TaskListView`)
- Uses `@FetchRequest` on `Item` with a base sort by timestamp.
- Applies in-memory filters and sorts according to:
  - `TaskSortOption`
  - Active category
  - Search text
  - Show/hide completed flag
- Splits into **Upcoming** and **Completed** sections.
- Uses `TaskRowView` for each row.
- Presents `TaskDetailView` in two ways:
  - **Navigation push** for editing existing tasks.
  - **Sheet with NavigationStack** for creating new tasks.

### Task Detail (`TaskDetailView`)
- Controlled by `TaskDetailMode` (create/edit).
- Binds to local `@State` copies of the task fields for form editing.
- On **Save**:
  - Validates title.
  - Writes back to `Item` via the computed properties.
  - Saves through `managedObjectContext`.
  - Optionally triggers `UINotificationFeedbackGenerator`.
- On **Cancel**:
  - Deletes inserted items in create mode.
  - Refreshes from context in edit mode.

### Settings (`SettingsView`)
- Binds to three `@Binding` values from `ContentView`:
  - Sort option (via `TaskSortOption`).
  - Default category.
  - Haptics enabled flag.
- Uses standard `Form` controls to keep behavior familiar.

## Custom Components & Modifiers

### `TaskCardModifier` and `taskCard` extension
- Reusable modifier giving rows a card-like appearance:
  - Gradient background using system secondary background plus a priority-tinted overlay.
  - Rounded rectangle clipping and priority-colored stroke.
  - Priority-colored shadow.
  - Spring animation tied to completion state.

### `TaskRowView`
- Composed of:
  - Completion toggle button.
  - Vertical stack with title and category.
  - Meta row with priority and relative due date.
- Supports advanced interactions:
  - Long-press visual feedback.
  - Rightward drag gesture to mark task completed.
  - Card styling via `taskCard` modifier.
- Implements a combined accessibility label summarizing key information.

## Navigation and State Management
- **State**
  - Lightweight view-local `@State` in list and detail views.
  - Persistent global settings via `@AppStorage` in `ContentView`.
- **Navigation**
  - `NavigationStack` + `NavigationLink` in the list.
  - `sheet` presentation for create flow keeps the main list focused.

## Performance and Responsiveness
- **Core Data**
  - Uses `@FetchRequest` with animation for efficient incremental updates.
  - Heavy operations (e.g. sorting, filtering) done on in-memory arrays of `Item` which is acceptable for typical to-do list sizes.
- **Animations**
  - Uses `spring` animations with reasonable damping to avoid excessive layout thrash.
- **Memory**
  - No large images; primarily text and SF Symbols.
  - Relies on system-managed Core Data contexts without custom caching.

## Theming and Accessibility
- **Colors**
  - Rooted in system colors (`.accentColor`, `.secondary`, `Color(.secondarySystemBackground)`), plus priority-based accents.
- **Dark Mode**
  - Background and shadow opacities adjust based on `colorScheme`.
- **Dynamic Type**
  - `TaskRowView` responds to `.dynamicTypeSize` and adjusts vertical layout.
- **VoiceOver**
  - Combined labels on rows with hints for key gestures.

## Extensibility Notes
- Easy to extend with:
  - Additional categories or user-defined categories.
  - Reminders/notifications using `UNUserNotificationCenter`.
  - Data syncing via CloudKit by updating the Core Data stack.
