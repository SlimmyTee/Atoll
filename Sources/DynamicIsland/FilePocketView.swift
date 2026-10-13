import SwiftUI

public struct FilePocketView: View {
    @ObservedObject var vm: IslandViewModel
    
    public var body: some View {
        VStack(spacing: 10) {
            if vm.droppedFiles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray.and.arrow.down")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text("Drag & drop files onto the notch")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Temporary pocket to hold files or share easily")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                )
            } else {
                HStack {
                    Text("\(vm.droppedFiles.count) item\(vm.droppedFiles.count == 1 ? "" : "s") in pocket")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    Button(action: { vm.clearShelf() }) {
                        Text("Clear All")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(vm.droppedFiles) { item in
                            HStack(spacing: 8) {
                                Image(nsImage: item.icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 28, height: 28)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    Text(item.sizeFormatted)
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                
                                HStack(spacing: 4) {
                                    Button(action: { item.open() }) {
                                        Image(systemName: "arrow.up.forward.app")
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button(action: { item.revealInFinder() }) {
                                        Image(systemName: "folder")
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button(action: { vm.removeFile(item) }) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 10))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }
                .frame(height: 56)
            }
        }
    }
}
