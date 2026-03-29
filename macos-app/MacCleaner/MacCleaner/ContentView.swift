import SwiftUI

struct ContentView: View {
    @StateObject private var vm = DashboardViewModel()
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(diskInfo: vm.diskInfo)
                .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 16)
            Divider()
            ScrollView {
                VStack(spacing: 16) {
                    // Disk Usage Chart
                    DiskUsageChartView(diskInfo: vm.diskInfo)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    
                    // Cleanup Operations Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(vm.sections) { section in SectionCard(section: section) }
                    }
                }
                .padding(24)
            }
            Divider()
            HStack {
                Text(vm.totalFreed > 0
                     ? "Total freed this session: \(ByteCountFormatter.string(fromByteCount: vm.totalFreed, countStyle: .file))"
                     : "Run individual sections or clean everything at once")
                    .font(.callout).foregroundStyle(.secondary)
                Spacer()
                Button {
                    showSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                Button { Task { await vm.runAll() } } label: {
                    Label("Clean Everything", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent).disabled(vm.isRunning).controlSize(.large)
            }
            .padding(.horizontal, 24).padding(.vertical, 14)
        }
        .frame(minWidth: 720, minHeight: 560)
        .task { await vm.refreshDiskInfo() }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

struct HeaderView: View {
    let diskInfo: DiskInfo?
    var body: some View {
        HStack(spacing: 16) {
            // Replace "apple.logo" with your logo image name
            // Option 1: Use your custom logo from Assets
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
            
            // Option 2: Keep SF Symbol (comment out the above, uncomment this)
            // Image(systemName: "apple.logo").font(.system(size: 32)).foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("MacBook Cleaner").font(.title2.bold())
                Text("Free up space \u{00B7} Stay organised \u{00B7} Stay secure").font(.callout).foregroundStyle(.secondary)
            }
            Spacer()
            if let disk = diskInfo {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(disk.usedFormatted) used of \(disk.totalFormatted)").font(.callout.monospacedDigit())
                    ProgressView(value: disk.usedFraction).frame(width: 160)
                        .tint(disk.usedFraction > 0.85 ? .red : disk.usedFraction > 0.65 ? .orange : .green)
                    Text("\(disk.freeFormatted) available").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct SectionCard: View {
    @ObservedObject var section: CleanupSection
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: section.icon).font(.title2).foregroundStyle(iconColor).frame(width: 32)
                VStack(alignment: .leading, spacing: 1) {
                    Text(section.title).font(.headline)
                    Text(section.description).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
                Spacer()
            }
            if section.status == .running {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: section.progress) {
                        Text("Processing...")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .controlSize(.small)
                }
            } else if let result = section.result {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: section.status == .done ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(section.status == .done ? .green : .red)
                        Text(result.message).font(.caption.weight(.medium)).lineLimit(2)
                    }
                    if !result.details.isEmpty {
                        DisclosureGroup("Details (\(result.details.count))") {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(result.details.prefix(20), id: \.self) {
                                    Text($0).font(.caption2).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                                }
                                if result.details.count > 20 {
                                    Text("\u{2026} and \(result.details.count - 20) more").font(.caption2).foregroundStyle(.tertiary)
                                }
                            }.padding(.top, 4)
                        }.font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(8).background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
            }
            Spacer(minLength: 0)
            Button { Task { await section.run() } } label: {
                Label(section.status == .running ? "Running\u{2026}" : "Run",
                      systemImage: section.status == .running ? "hourglass" : "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered).disabled(section.status == .running).controlSize(.small)
        }
        .padding(16).frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .background(.background).clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(borderColor, lineWidth: 1))
    }
    var iconColor: Color {
        switch section.status {
        case .idle: return .accentColor
        case .running: return .orange
        case .done: return .green
        case .failed: return .red
        }
    }
    var borderColor: Color {
        switch section.status {
        case .idle: return Color(nsColor: .separatorColor)
        case .running: return .orange.opacity(0.5)
        case .done: return .green.opacity(0.4)
        case .failed: return .red.opacity(0.4)
        }
    }
}

#Preview { ContentView() }
