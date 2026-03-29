import SwiftUI
import Charts

struct BeforeAfterChartView: View {
    let beforeDiskInfo: DiskInfo?
    let afterDiskInfo: DiskInfo?
    let totalFreed: Int64
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Cleanup Impact")
                    .font(.headline)
                Spacer()
                if totalFreed > 0 {
                    Text("Freed: \(CleanupUtilities.formatBytes(totalFreed))")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.15), in: Capsule())
                }
            }
            
            if let before = beforeDiskInfo, let after = afterDiskInfo {
                HStack(spacing: 24) {
                    // Before Chart
                    VStack(spacing: 8) {
                        Text("Before")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Chart {
                            SectorMark(
                                angle: .value("Used", before.used),
                                innerRadius: .ratio(0.618),
                                angularInset: 1.5
                            )
                            .foregroundStyle(.red.gradient)
                            
                            SectorMark(
                                angle: .value("Free", before.free),
                                innerRadius: .ratio(0.618),
                                angularInset: 1.5
                            )
                            .foregroundStyle(.gray.opacity(0.3).gradient)
                        }
                        .frame(height: 120)
                        .chartLegend(.hidden)
                        
                        VStack(spacing: 2) {
                            Text("\(Int(before.usedFraction * 100))% Used")
                                .font(.caption.bold())
                            Text(before.freeFormatted + " free")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Arrow
                    Image(systemName: "arrow.right")
                        .font(.title2)
                        .foregroundStyle(.green)
                    
                    // After Chart
                    VStack(spacing: 8) {
                        Text("After")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Chart {
                            SectorMark(
                                angle: .value("Used", after.used),
                                innerRadius: .ratio(0.618),
                                angularInset: 1.5
                            )
                            .foregroundStyle(.orange.gradient)
                            
                            SectorMark(
                                angle: .value("Free", after.free),
                                innerRadius: .ratio(0.618),
                                angularInset: 1.5
                            )
                            .foregroundStyle(.green.opacity(0.8).gradient)
                        }
                        .frame(height: 120)
                        .chartLegend(.hidden)
                        
                        VStack(spacing: 2) {
                            Text("\(Int(after.usedFraction * 100))% Used")
                                .font(.caption.bold())
                            Text(after.freeFormatted + " free")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Stats
                HStack(spacing: 16) {
                    StatBadge(
                        icon: "arrow.down.circle.fill",
                        label: "Space Freed",
                        value: CleanupUtilities.formatBytes(totalFreed),
                        color: .green
                    )
                    
                    let percentageFreed = before.total > 0 ? (Double(totalFreed) / Double(before.total)) * 100 : 0
                    StatBadge(
                        icon: "percent",
                        label: "Improvement",
                        value: String(format: "%.1f%%", percentageFreed),
                        color: .blue
                    )
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Run cleanup operations to see impact")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct StatBadge: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.callout.bold())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    BeforeAfterChartView(
        beforeDiskInfo: DiskInfo(total: 500_000_000_000, free: 150_000_000_000),
        afterDiskInfo: DiskInfo(total: 500_000_000_000, free: 200_000_000_000),
        totalFreed: 50_000_000_000
    )
    .frame(width: 600)
    .padding()
}
