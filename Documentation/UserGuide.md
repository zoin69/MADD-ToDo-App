# To-Do App – User Guide

## Overview
This To-Do app helps you capture tasks, organize them by category and priority, and keep track of due dates. It works fully offline and syncs changes automatically when the app is in use.

The app is optimized for iPhone and supports Light/Dark Mode and Dynamic Type accessibility.

## Main Screens

### 1. Tasks Tab
- **Task List**
  - Shows your tasks grouped into **Upcoming** and **Completed** sections.
  - Each row displays:
    - Title
    - Category (e.g. Work, Personal)
    - Priority with color and icon
    - Relative due date if set (e.g. "in 2 hours", "3d ago").
  - Rows are presented as interactive cards with subtle gradients and shadows.

- **Empty State**
  - When you have no tasks, you see an onboarding-style screen inviting you to create your first task.

- **Interactions**
  - **Tap a row** to open **Task Details**.
  - **Tap the circle icon** on the left to mark a task as completed / not completed.
  - **Swipe a row right** to quickly complete the task with haptic feedback.
  - **Swipe left** in a section and tap **Delete** to remove tasks.

- **Search & Filters**
  - Pull down on the list or tap in the search bar to filter by text. The app searches both title and notes.
  - Use the filter menu (funnel icon) in the navigation bar to:
    - Filter by **category** (All, Work, Personal, Errands, Other).
    - Toggle visibility of **Completed** tasks.

- **Creating Tasks**
  - Tap the **+** button in the navigation bar or the **"Add a task"** button in the empty state.
  - A sheet appears with the **Task Details** form in **New Task** mode.

### 2. Task Details
- **Modes**
  - **Create**: For new tasks.
  - **Edit**: For existing tasks.

- **Fields**
  - **Title** (required).
  - **Notes** – free-form text, supports multiple lines.
  - **Category** – choose from presets (All, Work, Personal, Errands, Other).
  - **Priority** – Low, Medium, High (with icons/colors).
  - **Due Date** – enable the toggle and pick date/time to set a due date.
  - **Completed** – mark task as done.

- **Actions**
  - **Save**
    - Validates title and writes your changes to local storage (Core Data).
    - Triggers a success haptic (if enabled in Settings).
  - **Cancel**
    - Discards changes.
    - In create mode, the draft task is deleted.
  - **Delete Task** (edit mode only)
    - Permanently removes the task from local storage.

### 3. Settings Tab
- **Task Sorting**
  - Choose how tasks are ordered on the Task List:
    - Due date
    - Priority
    - Title
    - Created time

- **Default Category**
  - Choose which category is preselected when creating new tasks.

- **Haptics**
  - Toggle haptic feedback for completion and save actions.

- **About**
  - Brief description of the app and reminder that it follows system appearance and text size.

## Gestures & Shortcuts
- **Tap row** – Open task details.
- **Tap completion icon** – Toggle completed state with animation and optional haptics.
- **Swipe right on row** – Quick-complete task.
- **Swipe left in list section** – Delete tasks via system delete controls.
- **Pull down** – Reveal search field if not visible.

## Offline Behavior
- All data is stored locally using Core Data.
- The app does not require network connectivity.
- Tasks, edits, and deletions are preserved between launches.

## Accessibility & Appearance
- **Dynamic Type**
  - The layout adapts for larger text sizes, including using more vertical stacking for task rows.
- **Dark Mode**
  - Colors are chosen from system palettes and adapt automatically to Light/Dark Mode.
- **VoiceOver**
  - Task rows expose a combined accessibility label summarizing title, priority, due date, and completion state.

## Tips
- Use **categories** to group tasks by context (e.g. Work vs Personal).
- Use **priorities** to highlight what must be done soon.
- Add **due dates** for time-sensitive tasks and watch for red overdue indicators.
