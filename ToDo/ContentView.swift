//
//  ContentView.swift
//  ToDo
//
//  Created by Sohan on 11/20/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @AppStorage("taskSortOption") private var sortOptionRaw: String = TaskSortOption.dueDate.rawValue
    @AppStorage("taskDefaultCategory") private var defaultCategory: String = "All"
    @AppStorage("taskHapticsEnabled") private var hapticsEnabled: Bool = true

    private var sortOption: TaskSortOption {
        TaskSortOption(rawValue: sortOptionRaw) ?? .dueDate
    }

    var body: some View {
        TabView {
            NavigationStack {
                TaskListView(
                    sortOption: sortOption,
                    defaultCategory: defaultCategory,
                    hapticsEnabled: hapticsEnabled
                )
                .navigationTitle("Tasks")
            }
            .tabItem {
                Label("Tasks", systemImage: "checklist")
            }

            NavigationStack {
                SettingsView(
                    sortOptionRaw: $sortOptionRaw,
                    defaultCategory: $defaultCategory,
                    hapticsEnabled: $hapticsEnabled
                )
                .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
