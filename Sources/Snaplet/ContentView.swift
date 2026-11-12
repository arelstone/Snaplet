import AppKit
import ApplicationServices
import SwiftUI

struct ContentView: View {
    @Bindable var store: PresetStore
    let controls: WindowControls
    @State private var name = ""
    @AppStorage("paletteHoverEnabled") private var paletteHoverEnabled = true
    @AppStorage("paletteHoverDelay") private var paletteHoverDelay = 0.45

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Snaplet").font(.title2.bold())
                    Text("Save and restore your workspace layouts.").foregroundStyle(.secondary)
                }
                Spacer()
                Button("Accessibility Settings") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
            }
            Label(controls.hasAccessibility ? "Accessibility access enabled" : "Accessibility access needed to arrange windows",
                  systemImage: controls.hasAccessibility ? "checkmark.shield" : "lock.shield")
                .font(.callout)
                .foregroundStyle(controls.hasAccessibility ? Color.green : Color.secondary)
            GroupBox("Popup Palette") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Show palette when hovering over a window’s green button", isOn: $paletteHoverEnabled)
                    HStack {
                        Text("Hover delay")
                        Slider(value: $paletteHoverDelay, in: 0.15...1.5, step: 0.05)
                            .accessibilityLabel("Palette hover delay")
                        Text("\(paletteHoverDelay, specifier: "%.2f") s").monospacedDigit().frame(width: 55)
                    }.disabled(!paletteHoverEnabled)
                    Text("macOS may also show its own window menu.").font(.caption).foregroundStyle(.secondary)
                }.padding(4)
            }
            HStack {
                TextField("Layout name, e.g. Development", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(save)
                Button("Save Current Layout", action: save).keyboardShortcut(.defaultAction)
            }
            Text(store.status).font(.callout).foregroundStyle(.secondary)
            if store.layouts.isEmpty {
                ContentUnavailableView("No layouts saved", systemImage: "rectangle.3.group", description: Text("Arrange your windows, name the layout, then save it here."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(store.layouts) { layout in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(layout.name).font(.headline)
                                Text("\(layout.windows.count) windows · \(layout.savedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Update") { store.update(layout) }
                                .help("Replace this preset with the current window arrangement")
                                .accessibilityLabel("Update \(layout.name)")
                            Button("Restore") { store.restore(layout) }
                            Button(role: .destructive) { store.delete(layout) } label: { Image(systemName: "trash") }
                                .help("Delete layout")
                        }.padding(.vertical, 4)
                    }
                }.listStyle(.inset)
            }
            Text("Apps need to be open before restoring. Window positions may vary across display setups.")
                .font(.caption).foregroundStyle(.tertiary)
        }
        .padding(20)
        .onAppear { controls.refreshPermission() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            controls.refreshPermission()
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.save(name: trimmed)
        name = ""
    }
}
