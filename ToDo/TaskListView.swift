import SwiftUI
import CoreData

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
        animation: .spring())
    private var fetchedItems: FetchedResults<Item>

    let sortOption: TaskSortOption
    let defaultCategory: String
    let hapticsEnabled: Bool

    @State private var searchText: String = ""
    @State private var activeCategory: String = "All"
    @State private var showCompleted: Bool = true
    @State private var showingAddSheet: Bool = false
    @State private var draftNewItem: Item?

    init(sortOption: TaskSortOption, defaultCategory: String, hapticsEnabled: Bool) {
        self.sortOption = sortOption
        self.defaultCategory = defaultCategory
        self.hapticsEnabled = hapticsEnabled
        _activeCategory = State(initialValue: defaultCategory)
    }

    private var filteredItems: [Item] {
        var items = fetchedItems.filter { item in
            if !showCompleted && item.taskIsCompleted { return false }
            if activeCategory != "All" && item.taskCategory != activeCategory { return false }
            if searchText.isEmpty { return true }
            let token = searchText.lowercased()
            return item.taskTitle.lowercased().contains(token) || item.taskNotes.lowercased().contains(token)
        }

        switch sortOption {
        case .dueDate:
            items.sort { lhs, rhs in
                switch (lhs.taskDueDate, rhs.taskDueDate) {
                case let (l?, r?):
                    return l < r
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                default:
                    return lhs.createdAt < rhs.createdAt
                }
            }
        case .priority:
            items.sort { lhs, rhs in
                if lhs.taskPriority == rhs.taskPriority {
                    return lhs.createdAt < rhs.createdAt
                }
                return lhs.taskPriority.rawValue > rhs.taskPriority.rawValue
            }
        case .title:
            items.sort { lhs, rhs in
                lhs.taskTitle.localizedCaseInsensitiveCompare(rhs.taskTitle) == .orderedAscending
            }
        case .createdAt:
            items.sort { lhs, rhs in
                lhs.createdAt > rhs.createdAt
            }
        }

        return items
    }

    private var openItems: [Item] {
        filteredItems.filter { !$0.taskIsCompleted }
    }

    private var completedItems: [Item] {
        filteredItems.filter { $0.taskIsCompleted }
    }

    var body: some View {
        Group {
            if filteredItems.isEmpty {
                emptyState
            } else {
                listContent
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: filteredItems.count)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    presentNewTaskSheet()
                } label: {
                    Label("New Task", systemImage: "plus.circle.fill")
                }
                .accessibilityLabel("Add new task")

                Menu {
                    Picker("Category", selection: $activeCategory) {
                        ForEach(TaskCategories.all, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }

                    Toggle(isOn: $showCompleted) {
                        Label("Show completed", systemImage: "checkmark.circle")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                .accessibilityLabel("Filter tasks")
            }
        }
        .sheet(isPresented: $showingAddSheet, onDismiss: handleNewTaskDismissed) {
            if let draftItem = draftNewItem {
                NavigationStack {
                    TaskDetailView(mode: .create, item: draftItem, hapticsEnabled: hapticsEnabled)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 56, weight: .semibold, design: .rounded))
                .foregroundColor(.accentColor)

            Text("Stay on top of your day")
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            Text("Create your first task to get started. You can organize tasks by category, set priorities, and add due dates.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                presentNewTaskSheet()
            } label: {
                Label("Add a task", systemImage: "plus")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.accentColor))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var listContent: some View {
        List {
            if !openItems.isEmpty {
                Section(header: Text("Upcoming")) {
                    ForEach(openItems) { item in
                        NavigationLink {
                            TaskDetailView(mode: .edit, item: item, hapticsEnabled: hapticsEnabled)
                        } label: {
                            TaskRowView(item: item, hapticsEnabled: hapticsEnabled)
                        }
                        .listRowSeparator(.visible)
                    }
                    .onDelete { indexSet in
                        delete(items: openItems, offsets: indexSet)
                    }
                }
            }

            if showCompleted && !completedItems.isEmpty {
                Section(header: Text("Completed")) {
                    ForEach(completedItems) { item in
                        NavigationLink {
                            TaskDetailView(mode: .edit, item: item, hapticsEnabled: hapticsEnabled)
                        } label: {
                            TaskRowView(item: item, hapticsEnabled: hapticsEnabled)
                        }
                        .listRowSeparator(.visible)
                    }
                    .onDelete { indexSet in
                        delete(items: completedItems, offsets: indexSet)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func presentNewTaskSheet() {
        let newItem = Item(context: viewContext)
        newItem.taskID = UUID()
        newItem.taskTitle = "New Task"
        newItem.taskNotes = ""
        newItem.taskCategory = defaultCategory == "All" ? "General" : defaultCategory
        newItem.taskPriority = .medium
        newItem.taskDueDate = nil
        newItem.taskIsCompleted = false
        newItem.createdAt = Date()

        draftNewItem = newItem
        showingAddSheet = true
    }

    private func handleNewTaskDismissed() {
        guard let draft = draftNewItem else { return }
        if draft.managedObjectContext == nil {
            draftNewItem = nil
            return
        }

        if draft.isInserted && !draft.hasChanges {
            viewContext.delete(draft)
        }

        do {
            if viewContext.hasChanges {
                try viewContext.save()
            }
        } catch {
            print("Failed to save new task: \(error)")
        }

        draftNewItem = nil
    }

    private func delete(items: [Item], offsets: IndexSet) {
        let targets = offsets.compactMap { index in
            index < items.count ? items[index] : nil
        }
        for item in targets {
            viewContext.delete(item)
        }

        do {
            try viewContext.save()
        } catch {
            print("Failed to delete items: \(error)")
        }
    }
}
