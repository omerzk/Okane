import SwiftUI

struct CollapsibleStatsHeaderView: View {
    @ObservedObject var store: CouponStore
    let displayedCoupons: [Coupon]
    let height: CGFloat
    let scrollOffset: CGFloat
    @State private var shimmerOffset: CGFloat = -200
    
    var isCollapsed: Bool {
        height <= 200
    }
    
    var body: some View {
        VStack(spacing: isCollapsed ? 12 : 25) {
            // Main value display with warm accent
            VStack(spacing: isCollapsed ? 6 : 12) {
                if !isCollapsed {
                    Text("Available")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.textAccent)
                        .textCase(.uppercase)
                        .tracking(2.5)
                }
                
                Text(store.showTotals ? String(format: "₪%.0f", store.unusedValue) : "₪∞")
                    .font(.system(size: isCollapsed ? 28 : 48, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.warmOrange, Color.warmAmber],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .white, radius: 1, x: 0, y: 1)
            }
            .padding(.vertical, isCollapsed ? 16 : 32)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cardBackground)
                        .shadow(color: .warmOrange.opacity(0.15), radius: 8, x: 0, y: 4)
                    
                    // Subtle warm accent
                    if !isCollapsed {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color.warmAmber.opacity(0.1), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            )
            
            if !isCollapsed {
                // Clean stats grid
                HStack(spacing: 0) {
                    VStack(spacing: 8) {
                        Text(store.showTotals ? String(format: "₪%.0f", store.totalValue) : "₪∞")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Text("Total")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Rectangle()
                        .fill(Color.warmOrange.opacity(0.3))
                        .frame(width: 1, height: 40)
                    
                    VStack(spacing: 8) {
                        Text(store.showTotals ? String(format: "₪%.0f", store.usedValue) : "₪∞")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.textSecondary)
                        Text("Used")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Rectangle()
                        .fill(Color.warmOrange.opacity(0.3))
                        .frame(width: 1, height: 40)
                    
                    VStack(spacing: 8) {
                        Text(store.showTotals ? "\(displayedCoupons.count)" : "∞")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.warmBlue)
                        Text("Coupons")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.backgroundSecondary)
                        .shadow(color: .warmOrange.opacity(0.08), radius: 4, x: 0, y: 2)
                )
                .opacity(max(0, 1.0 - (scrollOffset / 150.0)))
                
                // Very subtle hide used controls
                HStack {
                    Spacer()
                    
                    if store.coupons.contains(where: { $0.isUsed }) {
                        Button(action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                store.showUsedCoupons.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: store.showUsedCoupons ? "eye.slash" : "eye")
                                    .font(.system(size: 11, weight: .medium))
                                if !store.showUsedCoupons {
                                    Text("Show")
                                        .font(.system(size: 11, weight: .medium))
                                }
                            }
                            .foregroundColor(.warmOrange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.warmAmber.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                }
                .opacity(max(0.3, 1.0 - (scrollOffset / 80.0)))
            }
        }
        .frame(height: height)
        .clipped()
        .animation(.easeInOut(duration: 0.3), value: height)
        .padding(.bottom, 16)
    }
}