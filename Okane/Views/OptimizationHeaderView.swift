import SwiftUI

struct OptimizationHeaderView: View {
    let target: Double
    let suggestions: [Coupon]
    
    var totalValue: Double {
        suggestions.reduce(0) { $0 + $1.value }
    }
    
    var coverage: Double {
        guard target > 0 else { return 0 }
        return (totalValue / target) * 100
    }
    
    var remaining: Double {
        target - totalValue
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if suggestions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass.circle")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.textSecondary)
                    
                    Text("No combination found")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    Text("No unused coupons can fit under ₪\(String(format: "%.0f", target))")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.backgroundSecondary)
                        .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1)
                )
            } else {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Target: ₪\(String(format: "%.0f", target))")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.textSecondary)
                            
                            Text("Best match: ₪\(String(format: "%.0f", totalValue))")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.textPrimary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(String(format: "%.1f", coverage))%")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(coverage >= 80 ? .warmOrange : .warmAmber)
                            
                            Text("coverage")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    if remaining > 0 {
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.warmBlue)
                            
                            Text("₪\(String(format: "%.0f", remaining)) remaining to pay")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.textSecondary)
                            
                            Spacer()
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.warmAmber.opacity(0.1), Color.warmOrange.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .stroke(Color.warmOrange.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}