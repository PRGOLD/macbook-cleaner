import SwiftUI
import Charts

struct ContentView: View {
    @StateObject private var vm = DashboardViewModel()
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // Demo Mode Banner
            if CleanupSettings.shared.dryRunMode {
                HStack {
                    Image(systemName: "eye.fill")
                    Text("Demo Mode - No files will be deleted")
                        .font(.callout.bold())
                    Spacer()
                    Button("Disable") {
                        CleanupSettings.shared.dryRunMode = false
                        CleanupSettings.shared.save()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.orange.gradient)
            }
            
            HeaderView(diskInfo: vm.diskInfo)
                .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 16)
            Divider()
            ScrollView {
                VStack(spacing: 16) {
                    // Side-by-side disk charts
                    HStack(spacing: 24) {
                        // Left: Current Disk State
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Current Disk Usage")
                                .font(.headline)
                            
                            if let disk = vm.diskInfo {
                                Chart {
                                    SectorMark(
                                        angle: .value("Used", disk.used),
                                        innerRadius: .ratio(0.618),
                                        angularInset: 1.5
                                    )
                                    .foregroundStyle(.blue.gradient)
                                    
                                    SectorMark(
                                        angle: .value("Free", disk.free),
                                        innerRadius: .ratio(0.618),
                                        angularInset: 1.5
                                    )
                                    .foregroundStyle(.green.gradient)
                                }
                                .frame(height: 180)
                                .chartLegend(.hidden)
                                
                                VStack(spacing: 4) {
                                    Text("\(Int(disk.usedFraction * 100))% Used")
                                        .font(.title3.bold())
                                    Text(disk.freeFormatted + " free")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                // Labels
                                HStack(spacing: 16) {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(.blue.gradient)
                                            .frame(width: 8, height: 8)
                                        Text("Used")
                                            .font(.caption2)
                                    }
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(.green.gradient)
                                            .frame(width: 8, height: 8)
                                        Text("Free")
                                            .font(.caption2)
                                    }
                                }
                            } else {
                                ProgressView()
                                    .frame(height: 180)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        
                        // Right: After Cleanup State
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("After Cleanup")
                                    .font(.headline)
                                if vm.totalFreed > 0 {
                                    Spacer()
                                    Text("↑ \(CleanupUtilities.formatBytes(vm.totalFreed))")
                                        .font(.caption.bold())
                                        .foregroundStyle(.green)
                                }
                            }
                            
                            if vm.totalFreed > 0, let after = vm.diskInfo {
                                // Show actual after state with colors
                                Chart {
                                    SectorMark(
                                        angle: .value("Used", after.used),
                                        innerRadius: .ratio(0.618),
                                        angularInset: 1.5
                                    )
                                    .foregroundStyle(.blue.gradient)
                                    
                                    SectorMark(
                                        angle: .value("Free", after.free),
                                        innerRadius: .ratio(0.618),
                                        angularInset: 1.5
                                    )
                                    .foregroundStyle(.green.gradient)
                                }
                                .frame(height: 180)
                                .chartLegend(.hidden)
                                
                                VStack(spacing: 4) {
                                    Text("\(Int(after.usedFraction * 100))% Used")
                                        .font(.title3.bold())
                                    Text(after.freeFormatted + " free")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                // Labels
                                HStack(spacing: 16) {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(.blue.gradient)
                                            .frame(width: 8, height: 8)
                                        Text("Used")
                                            .font(.caption2)
                                    }
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(.green.gradient)
                                            .frame(width: 8, height: 8)
                                        Text("Free")
                                            .font(.caption2)
                                    }
                                }
                            } else if vm.diskInfoBeforeCleanup != nil, let after = vm.diskInfo {
                                // Show after chart even if nothing was freed (0 bytes)
                                Chart {
                                    SectorMark(
                                        angle: .value("Used", after.used),
                                        innerRadius: .ratio(0.618),
                                        angularInset: 1.5
                                    )
                                    .foregroundStyle(.blue.gradient)
                                    
                                    SectorMark(
                                        angle: .value("Free", after.free),
                                        innerRadius: .ratio(0.618),
                                        angularInset: 1.5
                                    )
                                    .foregroundStyle(.green.gradient)
                                }
                                .frame(height: 180)
                                .chartLegend(.hidden)
                                
                                VStack(spacing: 4) {
                                    Text("\(Int(after.usedFraction * 100))% Used")
                                        .font(.title3.bold())
                                    Text(after.freeFormatted + " free")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                // Labels
                                HStack(spacing: 16) {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(.blue.gradient)
                                            .frame(width: 8, height: 8)
                                        Text("Used")
                                            .font(.caption2)
                                    }
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(.green.gradient)
                                            .frame(width: 8, height: 8)
                                        Text("Free")
                                            .font(.caption2)
                                    }
                                }
                            } else {
                                // Show grey placeholder before cleanup
                                Chart {
                                    SectorMark(
                                        angle: .value("Empty", 1),
                                        innerRadius: .ratio(0.618),
                                        angularInset: 1.5
                                    )
                                    .foregroundStyle(.gray.opacity(0.2))
                                }
                                .frame(height: 180)
                                .chartLegend(.hidden)
                                
                                VStack(spacing: 4) {
                                    Text("—")
                                        .font(.title3.bold())
                                        .foregroundStyle(.secondary)
                                    Text("Run cleanup to see results")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)
                    
                    // Cleanup Operations Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(vm.sections) { section in 
                            SectionCard(section: section, viewModel: vm)
                        }
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
    @ObservedObject var viewModel: DashboardViewModel
    
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
            HStack(spacing: 8) {
                // Evaluate button (Dry run)
                Button {
                    Task {
                        // Capture before state if not already captured
                        if viewModel.diskInfoBeforeCleanup == nil {
                            viewModel.diskInfoBeforeCleanup = viewModel.diskInfo
                        }
                        
                        // Save current dry run state
                        let originalDryRun = CleanupSettings.shared.dryRunMode
                        // Enable dry run for evaluation
                        CleanupSettings.shared.dryRunMode = true
                        await section.run()
                        // Restore original state
                        CleanupSettings.shared.dryRunMode = originalDryRun
                        
                        // Refresh disk info
                        await viewModel.refreshDiskInfo()
                    }
                } label: {
                    Label("Evaluate", systemImage: "eye")
                        .frame(maxWidth: .infinity)
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .disabled(section.status == .running)
                .controlSize(.small)
                
                // Execute button (Real run)
                Button {
                    Task {
                        // Capture before state if not already captured
                        if viewModel.diskInfoBeforeCleanup == nil {
                            viewModel.diskInfoBeforeCleanup = viewModel.diskInfo
                        }
                        
                        // Save current dry run state
                        let originalDryRun = CleanupSettings.shared.dryRunMode
                        // Disable dry run for execution
                        CleanupSettings.shared.dryRunMode = false
                        await section.run()
                        // Restore original state
                        CleanupSettings.shared.dryRunMode = originalDryRun
                        
                        // Refresh disk info
                        await viewModel.refreshDiskInfo()
                    }
                } label: {
                    Label("Execute", systemImage: "bolt.fill")
                        .frame(maxWidth: .infinity)
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .disabled(section.status == .running)
                .controlSize(.small)
            }
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
