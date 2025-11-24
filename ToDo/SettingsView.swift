import SwiftUI

struct SettingsView: View {
    @Binding var sortOptionRaw: String
    @Binding var defaultCategory: String
    @Binding var hapticsEnabled: Bool

    var body: some View {
        Form {
            Section("Tasks") {
                Picker("Sort by", selection: $sortOptionRaw) {
                    ForEach(TaskSortOption.allCases) { option in
                        Label(option.title, systemImage: option.systemImageName)
                            .tag(option.rawValue)
                    }
                }

                Picker("Default category", selection: $defaultCategory) {
                    ForEach(TaskCategories.all, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
            }

            Section("Feedback") {
                Toggle(isOn: $hapticsEnabled) {
                    Label("Haptics", systemImage: "hand.tap.fill")
                }
            }

            Section("About") {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .imageScale(.large)
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("To-Do")
                            .font(.headline)
                        Text("A simple, focused task manager built with SwiftUI and Core Data.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Image(systemName: "paintpalette")
                        .imageScale(.medium)
                        .foregroundColor(.accentColor)
                    Text("Follows system Light/Dark Mode and Dynamic Type settings.")
                        .font(.footnote)
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    @State static var sortOptionRaw: String = TaskSortOption.dueDate.rawValue
    @State static var defaultCategory: String = "All"
    @State static var hapticsEnabled: Bool = true

    static var previews: some View {
        NavigationStack {
            SettingsView(
                sortOptionRaw: $sortOptionRaw,
                defaultCategory: $defaultCategory,
                hapticsEnabled: $hapticsEnabled
            )
        }
    }
}
