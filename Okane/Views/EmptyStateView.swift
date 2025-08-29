import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 32) {
            // Clean icon with warm accent
            ZStack {
                Circle()
                    .fill(Color.warmAmber.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.warmOrange)
            }
            
            VStack(spacing: 16) {
                Text("Welcome to Okane")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Text("Your digital coupon wallet\nAdd your first Shufersal coupon to get started")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            VStack(spacing: 16) {
                Text("Get started by tapping the **+** button")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.textSecondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Label("Add single coupon", systemImage: "plus.circle")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.warmOrange)
                    
                    Label("Bulk import from file", systemImage: "square.and.arrow.down.on.square")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.warmOrange)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.cardBackground)
                        .shadow(color: .warmOrange.opacity(0.08), radius: 8, x: 0, y: 2)
                )
            }
        }
        .padding(40)
    }
}