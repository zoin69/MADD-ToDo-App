import Foundation
import CoreData
import SwiftUI

// Shared task-related types and helpers used across the SwiftUI views.

enum TaskPriority: Int16, CaseIterable, Identifiable {
    case low = 0
    case medium = 1
    case high = 2

    var id: Int16 { rawValue }

    var title: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    var systemImageName: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "equal"
        case .high: return "arrow.up"
        }
    }

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

enum TaskSortOption: String, CaseIterable, Identifiable {
    case dueDate
    case priority
    case title
    case createdAt

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dueDate: return "Due date"
        case .priority: return "Priority"
        case .title: return "Title"
        case .createdAt: return "Created time"
        }
    }

    var systemImageName: String {
        switch self {
        case .dueDate: return "calendar"
        case .priority: return "flag.fill"
        case .title: return "text.alignleft"
        case .createdAt: return "clock.fill"
        }
    }
}

struct TaskCategories {
    static let all: [String] = ["All", "Work", "Personal", "Errands", "Other"]
}

struct TaskFormatting {
    static let dueDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
}

// Wrapper around Core Data-backed Item to provide safe SwiftUI-friendly accessors.
extension Item {
    var taskID: UUID {
        get {
            if let existing = value(forKey: "id") as? UUID {
                return existing
            }
            let new = UUID()
            setValue(new, forKey: "id")
            return new
        }
        set { setValue(newValue, forKey: "id") }
    }

    var taskTitle: String {
        get {
            if let raw = value(forKey: "title") as? String,
               !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return raw
            }
            return "New Task"
        }
        set { setValue(newValue, forKey: "title") }
    }

    var taskNotes: String {
        get { (value(forKey: "notes") as? String) ?? "" }
        set { setValue(newValue, forKey: "notes") }
    }

    var taskCategory: String {
        get {
            if let raw = value(forKey: "category") as? String,
               !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return raw
            }
            return "General"
        }
        set { setValue(newValue, forKey: "category") }
    }

    var taskPriority: TaskPriority {
        get {
            let raw = (value(forKey: "priority") as? Int16) ?? TaskPriority.medium.rawValue
            return TaskPriority(rawValue: raw) ?? .medium
        }
        set { setValue(newValue.rawValue, forKey: "priority") }
    }

    var taskDueDate: Date? {
        get { value(forKey: "dueDate") as? Date }
        set { setValue(newValue, forKey: "dueDate") }
    }

    var taskIsCompleted: Bool {
        get { (value(forKey: "isCompleted") as? Bool) ?? false }
        set { setValue(newValue, forKey: "isCompleted") }
    }

    var createdAt: Date {
        get {
            if let existing = value(forKey: "timestamp") as? Date {
                return existing
            }
            let now = Date()
            setValue(now, forKey: "timestamp")
            return now
        }
        set { setValue(newValue, forKey: "timestamp") }
    }

    var isOverdue: Bool {
        guard let due = taskDueDate else { return false }
        return !taskIsCompleted && due < Date()
    }
}
