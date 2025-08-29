import SwiftUI

struct CouponRowView: View {
    let coupon: Coupon
    let store: CouponStore
    let onToggleUsed: () -> Void // Add this callback
    @State private var showingBarcode = false
    
    var body: some View {
        HStack(spacing: 25) {
            VStack(spacing: 6) {
                Text(String(format: "₪%.0f", coupon.value))
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(coupon.isUsed ? .textSecondary : .textPrimary)
                    .overlay {
                        // Strikethrough effect for used coupons
                        if coupon.isUsed {
                            Rectangle()
                                .fill(Color.textSecondary)
                                .frame(height: 2)
                                .rotationEffect(.degrees(-5))
                        }
                    }
                
                Text(coupon.dateAdded, style: .date)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .tracking(0.5)
            }
            .frame(width: 90)
            .padding(.vertical, 12)
            
            Spacer()
            
            Image(systemName: coupon.isUsed ? "checkmark.seal.fill" : "qrcode.viewfinder")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(
                    coupon.isUsed
                    ? Color.warmGreen
                    : Color.warmOrange
                )
                .frame(width: 50, height: 50)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 28)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .shadow(color: .warmOrange.opacity(0.1), radius: 6, x: 0, y: 2)
                
                if !coupon.isUsed {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.warmAmber.opacity(0.08), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
        )
        // Keep used coupons clickable and visually distinct with subtle effects
        .saturation(coupon.isUsed ? 0.8 : 1.0) // Increased from 0.5 to 0.8 for better touch recognition
        .opacity(coupon.isUsed ? 0.9 : 1.0)    // Increased from 0.8 to 0.9 for better touch recognition
        .scaleEffect(coupon.isUsed ? 0.98 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            showingBarcode = true
        }
        .swipeActions(edge: .trailing) {
            Button(coupon.isUsed ? "Mark Unused" : "Mark Used") {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    store.toggleUsed(coupon)
                    onToggleUsed() // Call the callback
                }
            }
            .tint(coupon.isUsed ? Color.warmOrange : Color.warmGreen)
            
            Button("Delete") {
                withAnimation(.easeInOut(duration: 0.4)) {
                    store.deleteCoupon(coupon)
                    onToggleUsed() // Also call on delete
                }
            }
            .tint(.warmRed)
        }
        .sheet(isPresented: $showingBarcode) {
            BarcodeView(coupon: coupon, store: store, onToggleUsed: onToggleUsed)
        }
    }
}