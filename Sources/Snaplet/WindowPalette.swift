import AppKit
import SwiftUI

struct WindowActionGrid: View {
    let controls: WindowControls

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 5), spacing: 5) {
            ForEach(WindowAction.allCases) { action in
                Button {
                    controls.perform(action)
                } label: {
                    WindowActionIcon(action: action)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.bordered)
                .help(action.title)
                .accessibilityLabel(action.title)
                .disabled(!controls.hasAccessibility || !controls.hasTarget)
            }
        }
    }
}

private struct WindowActionIcon: View {
    let action: WindowAction

    var body: some View {
        if let region = action.region {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 2).strokeBorder(.secondary, lineWidth: 1)
                RoundedRectangle(cornerRadius: 1)
                    .fill(.tint)
                    .frame(width: 24 * region.width, height: 16 * region.height)
                    .offset(x: 24 * region.minX + 2, y: 16 * region.minY + 2)
            }
            .frame(width: 28, height: 20)
        } else {
            Image(systemName: symbol).font(.system(size: 16))
        }
    }

    private var symbol: String {
        switch action {
        case .center: "scope"
        case .previousDisplay: "arrow.left.square"
        case .nextDisplay: "arrow.right.square"
        case .fullScreen: "arrow.up.left.and.arrow.down.right"
        case .revert: "arrow.uturn.backward"
        default: "rectangle"
        }
    }
}

struct MenuPalette: View {
    let store: PresetStore
    let controls: WindowControls
    let showManager: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "rectangle.3.group").foregroundStyle(.tint)
                Text("Snaplet").font(.headline)
                Spacer()
            }
            Text(controls.targetName).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            WindowActionGrid(controls: controls)

            if !controls.hasAccessibility {
                Button("Enable Accessibility Access…", action: WindowControls.openAccessibilitySettings)
                    .font(.callout)
            }
            if !controls.status.isEmpty {
                Text(controls.status).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.updatesFrequently)
            }
            Divider()
            if store.layouts.isEmpty {
                Text("Save a layout in Manage Layouts to add it here.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("SAVED LAYOUTS").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(store.layouts) { layout in
                            Button {
                                store.restore(layout)
                            } label: {
                                HStack {
                                    Image(systemName: "rectangle.3.group")
                                    Text(layout.name).lineLimit(1)
                                    Spacer()
                                    Text("\(layout.windows.count)").foregroundStyle(.secondary)
                                }.frame(maxWidth: .infinity, alignment: .leading)
                            }.buttonStyle(.bordered)
                        }
                    }
                }
                .frame(height: min(CGFloat(store.layouts.count) * 32, 160))
                Text(store.status).font(.caption).foregroundStyle(.secondary)
            }
            Divider()
            HStack {
                Button("Manage Layouts…", action: showManager)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
            }.font(.callout)
        }
        .padding(16)
        .frame(width: 320)
        .onAppear { controls.selectFrontmostWindow() }
    }
}

struct HoverPalette: View {
    let controls: WindowControls

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(controls.targetName).font(.caption.weight(.medium)).lineLimit(1)
            WindowActionGrid(controls: controls)
            if !controls.status.isEmpty {
                Text(controls.status).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
            }
        }
        .padding(10)
        .frame(width: 280, height: 200, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary))
    }
}
