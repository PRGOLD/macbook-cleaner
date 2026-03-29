import SwiftUI
import Combine

struct SettingsView: View {
    @StateObject private var viewModel = CleanupSettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            // Retention Periods Section
            Section {
                LabeledContent("Log Files") {
                    Stepper("\(viewModel.settings.logRetentionDays) days", value: $viewModel.settings.logRetentionDays, in: 7...365)
                }
                LabeledContent("Temp Files") {
                    Stepper("\(viewModel.settings.tempFileRetentionDays) days", value: $viewModel.settings.tempFileRetentionDays, in: 1...30)
                }
                LabeledContent("Cache Files") {
                    Stepper("\(viewModel.settings.cacheRetentionDays) days", value: $viewModel.settings.cacheRetentionDays, in: 1...30)
                }
                LabeledContent("Downloads") {
                    Stepper("\(viewModel.settings.downloadRetentionDays) days", value: $viewModel.settings.downloadRetentionDays, in: 30...365)
                }
            } header: {
                Text("Retention Periods")
            } footer: {
                Text("Files older than these thresholds will be considered for cleanup")
            }
            
            // Safety Options Section
            Section {
                Toggle("Dry Run Mode", isOn: $viewModel.settings.dryRunMode)
                    .help("Preview what would be deleted without actually deleting")
                
                Toggle("Confirm Before Delete", isOn: $viewModel.settings.confirmBeforeDelete)
                    .help("Show confirmation dialog before running cleanup operations")
                
                Toggle("Auto-Backup Before Delete", isOn: $viewModel.settings.autoBackupBeforeDelete)
                    .help("Create temporary backups of deleted files (undo capability)")
                    .disabled(true) // Coming soon
                
                if viewModel.settings.autoBackupBeforeDelete {
                    LabeledContent("Max Backup Size") {
                        Text(CleanupUtilities.formatBytes(viewModel.settings.maxBackupSize))
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Safety Options")
            } footer: {
                if viewModel.settings.dryRunMode {
                    Label("Dry run mode is enabled - operations will only preview results", systemImage: "info.circle")
                        .foregroundStyle(.orange)
                }
            }
            
            // Browser Cleanup Section
            Section {
                Toggle("Clear Safari Cache", isOn: $viewModel.settings.clearSafariCache)
                Toggle("Clear Safari Cookies", isOn: $viewModel.settings.clearSafariCookies)
                    .help("⚠️ This will log you out of websites")
                Toggle("Clear Safari History", isOn: $viewModel.settings.clearSafariHistory)
                    .help("⚠️ This will delete your browsing history")
            } header: {
                Text("Browser Cleanup")
            } footer: {
                Text("Select what Safari data to include in cleanup operations")
            }
            
            // Developer Tools Section
            Section {
                Toggle("npm", isOn: $viewModel.settings.clearNpmCache)
                Toggle("Homebrew", isOn: $viewModel.settings.clearHomebrewCache)
                Toggle("CocoaPods", isOn: $viewModel.settings.clearCocoaPodsCache)
            } header: {
                Text("Developer Caches")
            } footer: {
                Text("Select which developer tool caches to clear")
            }
            
            // Advanced Section
            Section {
                LabeledContent("Skip Recently Accessed") {
                    Stepper("\(viewModel.settings.skipRecentlyAccessedDays) days", value: $viewModel.settings.skipRecentlyAccessedDays, in: 0...30)
                }
                LabeledContent("Minimum File Size") {
                    Picker(CleanupUtilities.formatBytes(viewModel.settings.minimumFileSize), selection: $viewModel.settings.minimumFileSize) {
                        Text("Any size").tag(Int64(0))
                        Text("1 MB").tag(Int64(1024 * 1024))
                        Text("10 MB").tag(Int64(10 * 1024 * 1024))
                        Text("100 MB").tag(Int64(100 * 1024 * 1024))
                    }
                }
            } header: {
                Text("Advanced")
            } footer: {
                Text("Files accessed recently or below the minimum size will be skipped")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .frame(width: 500, height: 600)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Reset to Defaults") {
                    viewModel.reset()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    viewModel.save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
}
