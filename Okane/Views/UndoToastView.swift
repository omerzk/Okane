import SwiftUI

struct UndoToastView: View {
    @ObservedObject var store: CouponStore
    @State private var showToast = false
    
    var body: some View {
        Group {
            if !store.recentlyDeleted.isEmpty && showToast {
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Coupon deleted")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Undo") {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                store.undoDelete()
                                showToast = false
                            }
                        }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.warmAmber)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.textPrimary.opacity(0.9))
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100) // Above tab bar area
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
                .zIndex(1000)
            }
        }
        .onChange(of: store.recentlyDeleted.count) { oldValue, newValue in
            if newValue > oldValue {
                // New item deleted
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showToast = true
                }
                
                // Auto-hide after 8 seconds (before cleanup)
                Task {
                    try await Task.sleep(nanoseconds: 8_000_000_000) // 8 seconds
                    await MainActor.run {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showToast = false
                        }
                    }
                }
            } else if newValue == 0 {
                // All items cleared
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showToast = false
                }
            }
        }
    }
}