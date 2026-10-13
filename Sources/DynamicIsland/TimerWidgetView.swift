import SwiftUI

public struct TimerWidgetView: View {
    @ObservedObject var vm: IslandViewModel
    
    public var body: some View {
        HStack(spacing: 20) {
            // Large Timer Display
            VStack(alignment: .leading, spacing: 4) {
                Text(vm.formattedTimer)
                    .font(.system(size: 34, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                
                Text(vm.isTimerActive ? "Timer running" : "Focus Timer")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(width: 140, alignment: .leading)
            
            Divider()
                .background(Color.white.opacity(0.15))
                .frame(height: 50)
            
            // Presets and controls
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    PresetButton(label: "1m", minutes: 1, vm: vm)
                    PresetButton(label: "5m", minutes: 5, vm: vm)
                    PresetButton(label: "15m", minutes: 15, vm: vm)
                    PresetButton(label: "25m", minutes: 25, vm: vm)
                }
                
                HStack(spacing: 12) {
                    if vm.isTimerActive {
                        Button(action: { vm.stopTimer() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 10))
                                Text("Cancel")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.15))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: { vm.startTimer(minutes: 5) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 10))
                                Text("Start 5m")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Spacer()
        }
    }
}

struct PresetButton: View {
    let label: String
    let minutes: Int
    @ObservedObject var vm: IslandViewModel
    
    var isSelected: Bool {
        vm.timerInitialSeconds == minutes * 60 && vm.isTimerActive
    }
    
    var body: some View {
        Button(action: { vm.startTimer(minutes: minutes) }) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isSelected ? .black : .white.opacity(0.8))
                .frame(width: 36, height: 26)
                .background(isSelected ? Color.white : Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
