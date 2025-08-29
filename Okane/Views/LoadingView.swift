import SwiftUI

struct LoadingView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Color.textPrimary.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.warmOrange)
                    .rotationEffect(.degrees(rotation))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: rotation)
                    .onAppear {
                        rotation = 360
                    }
                
                Text("Processing coupons...")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.cardBackground)
                    .shadow(color: .warmOrange.opacity(0.15), radius: 20, x: 0, y: 8)
            )
        }
    }
}