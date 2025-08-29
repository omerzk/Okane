import SwiftUI

struct StatsView: View {
    @ObservedObject var store: CouponStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.okamiParchment
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with total savings
                        VStack(spacing: 16) {
                            VStack(spacing: 8) {
                                Text("Total Savings")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.textAccent)
                                    .textCase(.uppercase)
                                    .tracking(2)
                                
                                Text(String(format: "₪%.0f", store.totalSavings))
                                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.warmOrange, Color.warmAmber],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: .white, radius: 1, x: 0, y: 1)
                            }
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.cardBackground)
                                    .shadow(color: .warmOrange.opacity(0.15), radius: 12, x: 0, y: 4)
                            )
                        }
                        
                        // This Month Stats
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "calendar.circle.fill")
                                    .foregroundColor(.warmOrange)
                                    .font(.system(size: 20, weight: .medium))
                                
                                Text("This Month")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)
                                
                                Spacer()
                            }
                            
                            HStack(spacing: 0) {
                                StatCard(
                                    title: "Saved",
                                    value: String(format: "₪%.0f", store.savingsThisMonth),
                                    color: .warmGreen
                                )
                                
                                Rectangle()
                                    .fill(Color.warmOrange.opacity(0.3))
                                    .frame(width: 1)
                                
                                StatCard(
                                    title: "Used",
                                    value: "\(store.couponsUsedThisMonth)",
                                    color: .warmBlue
                                )
                                
                                Rectangle()
                                    .fill(Color.warmOrange.opacity(0.3))
                                    .frame(width: 1)
                                
                                StatCard(
                                    title: "Added",
                                    value: "\(store.couponsAddedThisMonth)",
                                    color: .warmAmber
                                )
                            }
                            .frame(height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.cardBackground)
                                    .shadow(color: .warmOrange.opacity(0.08), radius: 6, x: 0, y: 2)
                            )
                        }
                        
                        // Overall Analytics
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "chart.pie.fill")
                                    .foregroundColor(.warmOrange)
                                    .font(.system(size: 20, weight: .medium))
                                
                                Text("Analytics")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)
                                
                                Spacer()
                            }
                            
                            VStack(spacing: 16) {
                                // Usage Efficiency
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Usage Efficiency")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundColor(.textPrimary)
                                        Spacer()
                                        Text(String(format: "%.1f%%", store.usageEfficiency))
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundColor(.warmOrange)
                                    }
                                    
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.warmOrange.opacity(0.2))
                                                .frame(height: 8)
                                            
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color.warmOrange, Color.warmAmber],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .frame(width: geometry.size.width * CGFloat(store.usageEfficiency / 100), height: 8)
                                        }
                                    }
                                    .frame(height: 8)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.backgroundSecondary)
                                )
                                
                                // Average Coupon Value & Most Active Day
                                HStack(spacing: 12) {
                                    VStack(spacing: 8) {
                                        Text("Avg Value")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundColor(.textSecondary)
                                        Text(String(format: "₪%.0f", store.averageCouponValue))
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundColor(.warmBlue)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.backgroundSecondary)
                                    )
                                    
                                    VStack(spacing: 8) {
                                        Text("Most Active")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundColor(.textSecondary)
                                        Text(store.mostActiveDay)
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundColor(.warmGreen)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.backgroundSecondary)
                                    )
                                }
                            }
                        }
                        
                        // Total Counts
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "number.circle.fill")
                                    .foregroundColor(.warmOrange)
                                    .font(.system(size: 20, weight: .medium))
                                
                                Text("Totals")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)
                                
                                Spacer()
                            }
                            
                            HStack(spacing: 0) {
                                StatCard(
                                    title: "Total",
                                    value: "\(store.coupons.count)",
                                    color: .textPrimary
                                )
                                
                                Rectangle()
                                    .fill(Color.warmOrange.opacity(0.3))
                                    .frame(width: 1)
                                
                                StatCard(
                                    title: "Used",
                                    value: "\(store.coupons.filter { $0.isUsed }.count)",
                                    color: .warmGreen
                                )
                                
                                Rectangle()
                                    .fill(Color.warmOrange.opacity(0.3))
                                    .frame(width: 1)
                                
                                StatCard(
                                    title: "Available",
                                    value: "\(store.coupons.filter { !$0.isUsed }.count)",
                                    color: .warmAmber
                                )
                            }
                            .frame(height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.cardBackground)
                                    .shadow(color: .warmOrange.opacity(0.08), radius: 6, x: 0, y: 2)
                            )
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(
                LinearGradient(
                    colors: [Color.warmOrange, Color.warmAmber],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                for: .navigationBar
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.textSecondary)
                .textCase(.uppercase)
                .tracking(1.2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}