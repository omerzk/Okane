import SwiftUI

struct BarcodeView: View {
    let coupon: Coupon
    let store: CouponStore
    let onToggleUsed: () -> Void // Add this line
    @Environment(\.dismiss) private var dismiss
    @State private var showingMarkAsUsedConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Value and details
                    VStack(spacing: 12) {
                        Text(coupon.formattedValue)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        
                        Text(coupon.barcodeNumber)
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.textSecondary)
                            .tracking(1)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.cardBackground)
                            .shadow(color: .warmOrange.opacity(0.1), radius: 12, x: 0, y: 4)
                    )
                    
                    // Barcode
                    if let image = coupon.barcodeImage {
                        Image(uiImage: image)
                            .interpolation(.none)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 300, maxHeight: 120)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.cardBackground)
                                    .shadow(color: .warmOrange.opacity(0.08), radius: 8, x: 0, y: 2)
                            )
                    }
                    
                    // Original message if available
                    if let message = coupon.originalMessage {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Original SMS")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.textAccent)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            
                            Text(message)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.textPrimary)
                                .textSelection(.enabled)
                                .lineSpacing(2)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.backgroundSecondary)
                        )
                    }
                    
                    Spacer()
                }
                .padding(24)
                
                // Bottom center checkmark button
                VStack {
                    Spacer()
                    
                    Button(action: {
                        showingMarkAsUsedConfirmation = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: coupon.isUsed ? "arrow.counterclockwise.circle.fill" : "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                            
                            Text(coupon.isUsed ? "Mark as Unused" : "Mark as Used")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.warmOrange, Color.warmAmber],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .warmOrange.opacity(0.4), radius: 8, x: 0, y: 4)
                        )
                    }
                    .scaleEffect(showingMarkAsUsedConfirmation ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: showingMarkAsUsedConfirmation)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Coupon Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.okamiEarth)
                    .fontWeight(.semibold)
                }
            }
            .alert(coupon.isUsed ? "Mark as Unused" : "Mark as Used", isPresented: $showingMarkAsUsedConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button(coupon.isUsed ? "Mark Unused" : "Mark Used") {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            store.toggleUsed(coupon)
                            onToggleUsed() // Add this line
                        }
                        dismiss()
                    }
            } message: {
                Text(coupon.isUsed ?
                     "Mark this ₪\(String(format: "%.0f", coupon.value)) coupon as unused?" :
                     "Mark this ₪\(String(format: "%.0f", coupon.value)) coupon as used?")
            }
        }
    }
}