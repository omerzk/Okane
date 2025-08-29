import SwiftUI

struct AddCouponView: View {
    @ObservedObject var store: CouponStore
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 24) {
                    Text("Paste SMS Message:")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    Text("Copy the entire SMS from Messages and paste here. The app will automatically extract the URL and value.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.textSecondary)
                        .lineSpacing(4)
                    
                    // Enhanced text input area
                    VStack(spacing: 12) {
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cardBackground)
                                .stroke(isTextFieldFocused ? Color.warmOrange : Color.warmOrange.opacity(0.3), lineWidth: isTextFieldFocused ? 2 : 1)
                                .shadow(color: .warmOrange.opacity(isTextFieldFocused ? 0.2 : 0.1), radius: isTextFieldFocused ? 8 : 4, x: 0, y: 2)
                            
                            if messageText.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Paste your SMS message here...")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.textSecondary.opacity(0.6))
                                    
                                    Text("Example: לצפיה בשובר שופרסל בסך ₪50.00: https://...")
                                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                                        .foregroundColor(.textSecondary.opacity(0.5))
                                        .lineLimit(2)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 20)
                            }
                            
                            TextField("", text: $messageText, axis: .vertical)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 20)
                                .lineLimit(3...10)
                                .focused($isTextFieldFocused)
                                .textSelection(.enabled)
                        }
                        .frame(minHeight: 120)
                        
                        // Action buttons row
                        HStack(spacing: 12) {
                            // Paste button
                            Button(action: {
                                pasteFromClipboard()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.on.clipboard")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Paste")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.warmOrange)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.warmAmber.opacity(0.15))
                                        .stroke(Color.warmOrange.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // Clear button
                            if !messageText.isEmpty {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        messageText = ""
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "xmark.circle")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("Clear")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.warmRed)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.warmRed.opacity(0.1))
                                            .stroke(Color.warmRed.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                            
                            Spacer()
                            
                            // Character count
                            if !messageText.isEmpty {
                                Text("\(messageText.count) chars")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(.textSecondary)
                                    .transition(.opacity)
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: messageText.isEmpty)
                    }
                    
                    Button("Add Coupon") {
                        Task {
                            await store.addCoupon(from: messageText.trimmingCharacters(in: .whitespacesAndNewlines))
                            // Dismiss on success (no errors) or on duplicate error (since it's handled)
                            if store.retryableError == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isLoading)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isLoading
                                    ? [Color.textSecondary, Color.textSecondary]
                                    : [Color.warmOrange, Color.warmAmber],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Add to Okane")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.warmRed)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Auto-focus the text field when view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
        }
    }
    
    private func pasteFromClipboard() {
        if let clipboardContent = UIPasteboard.general.string {
            withAnimation(.easeInOut(duration: 0.3)) {
                messageText = clipboardContent
            }
            // Auto-focus after pasting
            isTextFieldFocused = true
        }
    }
}