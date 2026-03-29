import SwiftUI
import Charts

struct DiskUsageChartView: View {
    let diskInfo: DiskInfo?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Disk Usage")
                .font(.headline)
            
            if let disk = diskInfo {
                Chart {
                    SectorMark(
                        angle: .value("Used", disk.used),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(.red.gradient)
                    .annotation(position: .overlay) {
                        VStack(spacing: 2) {
                            Text("\(Int(disk.usedFraction * 100))%")
                                .font(.title2.bold())
                            Text("Used")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    SectorMark(
                        angle: .value("Free", disk.free),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(.green.gradient)
                }
                .frame(height: 200)
                .chartLegend(position: .bottom, spacing: 12)
                
                HStack(spacing: 20) {
                    LegendItem(color: .red, label: "Used", value: disk.usedFormatted)
                    LegendItem(color: .green, label: "Free", value: disk.freeFormatted)
                }
                .padding(.top, 8)
            } else {
                ProgressView()
                    .frame(height: 200)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color.gradient)
                .frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.callout.bold())
            }
        }
    }
}

#Preview {
    DiskUsageChartView(diskInfo: DiskInfo(total: 500_000_000_000, free: 200_000_000_000))
        .frame(width: 300)
}
