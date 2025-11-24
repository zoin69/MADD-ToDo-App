import SwiftUI
import CoreData
import UIKit

// Custom visual style and interactive task row components used throughout the app.

struct TaskCardModifier: ViewModifier {
    let priority: TaskPriority
    let isCompleted: Bool

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(background)
            .overlay(border)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: shadowColor, radius: isCompleted ? 0 : 6, x: 0, y: isCompleted ? 0 : 3)
            .animation(.spring(response: 0.32, dampingFraction: 0.8), value: isCompleted)
    }

    private var background: some View {
        let base = Color(.secondarySystemBackground)
        let accent = priority.color.opacity(colorScheme == .dark ? 0.35 : 0.18)
        return LinearGradient(
            colors: [base, accent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(priority.color.opacity(isCompleted ? 0.25 : 0.6), lineWidth: isCompleted ? 1 : 1.5)
    }

    private var shadowColor: Color {
        priority.color.opacity(colorScheme == .dark ? 0.4 : 0.25)
    }
}

extension View {
    func taskCard(priority: TaskPriority, isCompleted: Bool) -> some View {
        modifier(TaskCardModifier(priority: priority, isCompleted: isCompleted))
    }
}

struct TaskRowView: View {
    @ObservedObject var item: Item
    let hapticsEnabled: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @GestureState private var isPressed = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        let layoutIsVertical = dynamicTypeSize.isAccessibilitySize

        HStack(spacing: 12) {
            completionToggle

            if layoutIsVertical {
                VStack(alignment: .leading, spacing: 6) {
                    titleAndCategory
                    metaRow
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    titleAndCategory
                    metaRow
                }
            }

            Spacer(minLength: 4)
        }
        .taskCard(priority: item.taskPriority, isCompleted: item.taskIsCompleted)
        .scaleEffect(isPressed ? 0.97 : 1)
        .opacity(isPressed ? 0.9 : 1)
        .offset(x: dragOffset)
        .gesture(longPressGesture)
        .gesture(dragGesture)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to edit. Swipe right to complete.")
    }

    private var completionToggle: some View {
        Button {
            toggleCompleted(withHaptics: true)
        } label: {
            Image(systemName: item.taskIsCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(item.taskIsCompleted ? TaskPriority.low.color : item.taskPriority.color)
                .symbolRenderingMode(.palette)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.taskIsCompleted ? "Mark as not completed" : "Mark as completed")
    }

    private var titleAndCategory: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.taskTitle)
                .font(.system(.headline, design: .rounded))
                .lineLimit(2)
                .strikethrough(item.taskIsCompleted, pattern: .solid, color: .primary.opacity(0.7))

            HStack(spacing: 6) {
                Image(systemName: "folder")
                    .imageScale(.small)
                Text(item.taskCategory)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    private var metaRow: some View {
        HStack(spacing: 8) {
            Label {
                Text(item.taskPriority.title)
            } icon: {
                Image(systemName: item.taskPriority.systemImageName)
            }
            .font(.caption2)
            .foregroundColor(item.taskPriority.color)

            if let due = item.taskDueDate {
                Label {
                    Text(TaskFormatting.relativeDateFormatter.localizedString(for: due, relativeTo: Date()))
                } icon: {
                    Image(systemName: "calendar.badge.clock")
                }
                .font(.caption2)
                .foregroundColor(item.isOverdue ? .red : .secondary)
            }
        }
    }

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.12)
            .updating($isPressed) { value, state, _ in
                state = value
            }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                let translation = value.translation.width
                if translation > 0 { // only track rightward drags
                    dragOffset = translation * 0.6
                }
            }
            .onEnded { value in
                let translation = value.translation.width
                if translation > 80 {
                    toggleCompleted(withHaptics: true)
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    dragOffset = 0
                }
            }
    }

    private func toggleCompleted(withHaptics: Bool) {
        item.taskIsCompleted.toggle()
        do {
            try item.managedObjectContext?.save()
            if withHaptics, hapticsEnabled {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        } catch {
            // For a production app, route this into a user-visible error surface or logging.
            print("Failed to save completion toggle: \(error)")
        }
    }

    private var accessibilityLabel: String {
        var components: [String] = []
        components.append(item.taskTitle)
        components.append("Priority \(item.taskPriority.title)")
        if let due = item.taskDueDate {
            let formatted = TaskFormatting.dueDateFormatter.string(from: due)
            components.append("Due \(formatted)")
        }
        if item.taskIsCompleted {
            components.append("Completed")
        }
        return components.joined(separator: ", ")
    }
}
