import SwiftUI
import CoreData
import UIKit

enum TaskDetailMode {
    case create
    case edit
}

struct TaskDetailView: View {
    let mode: TaskDetailMode

    @ObservedObject var item: Item
    let hapticsEnabled: Bool

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var category: String = TaskCategories.all.first ?? "General"
    @State private var priority: TaskPriority = .medium
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    @State private var isCompleted: Bool = false

    @FocusState private var titleIsFocused: Bool

    var body: some View {
        Form {
            Section("Task") {
                TextField("Title", text: $title)
                    .font(.system(.title3, design: .rounded))
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(false)
                    .focused($titleIsFocused)

                TextEditor(text: $notes)
                    .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 140 : 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.secondary.opacity(0.25))
                    )
                    .padding(.vertical, 4)
            }

            Section("Details") {
                Picker("Category", selection: $category) {
                    ForEach(TaskCategories.all, id: \.self) { value in
                        Text(value).tag(value)
                    }
                }

                Picker("Priority", selection: $priority) {
                    ForEach(TaskPriority.allCases) { level in
                        Label(level.title, systemImage: level.systemImageName)
                            .tag(level)
                    }
                }
                .pickerStyle(.segmented)

                Toggle(isOn: $hasDueDate.animation()) {
                    Label("Due date", systemImage: "calendar")
                }

                if hasDueDate {
                    DatePicker(
                        "Due",
                        selection: $dueDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            }

            Section("Status") {
                Toggle(isOn: $isCompleted) {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                }
            }

            if mode == .edit {
                Section {
                    Button(role: .destructive) {
                        deleteTask()
                    } label: {
                        Label("Delete task", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(mode == .create ? "New Task" : "Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    cancel()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    save()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear(perform: loadFromItem)
        .onChange(of: item.taskIsCompleted) { newValue in
            isCompleted = newValue
        }
        .task {
            if mode == .create {
                // Slight delay so keyboard transition feels smoother
                try? await Task.sleep(nanoseconds: 300_000_000)
                titleIsFocused = true
            }
        }
    }

    private func loadFromItem() {
        title = item.taskTitle
        notes = item.taskNotes
        category = item.taskCategory
        priority = item.taskPriority
        if let existingDue = item.taskDueDate {
            hasDueDate = true
            dueDate = existingDue
        } else {
            hasDueDate = false
            dueDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        }
        isCompleted = item.taskIsCompleted
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            return
        }

        item.taskTitle = trimmedTitle
        item.taskNotes = notes
        item.taskCategory = category
        item.taskPriority = priority
        item.taskIsCompleted = isCompleted
        item.createdAt = item.createdAt // ensure timestamp exists
        item.taskID = item.taskID

        if hasDueDate {
            item.taskDueDate = dueDate
        } else {
            item.taskDueDate = nil
        }

        do {
            try viewContext.save()
            if hapticsEnabled {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
            dismiss()
        } catch {
            print("Failed to save task: \(error)")
        }
    }

    private func cancel() {
        if mode == .create {
            viewContext.delete(item)
        } else {
            viewContext.refresh(item, mergeChanges: false)
        }
        dismiss()
    }

    private func deleteTask() {
        viewContext.delete(item)
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Failed to delete task: \(error)")
        }
    }
}

struct TaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let controller = PersistenceController.preview
        let context = controller.container.viewContext
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        let items = (try? context.fetch(request)) ?? []
        let sample = items.first ?? Item(context: context)

        return NavigationStack {
            TaskDetailView(mode: .edit, item: sample, hapticsEnabled: true)
        }
        .environment(\.managedObjectContext, context)
    }
}
