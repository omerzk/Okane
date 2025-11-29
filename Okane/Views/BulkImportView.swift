import SwiftUI
import UniformTypeIdentifiers

struct BulkImportView: View {
    @ObservedObject var store: CouponStore
    @Environment(\.dismiss) private var dismiss
    @State private var importText = ""
    @State private var showingFilePicker = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Bulk Import to Okane")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.buttonTextOnColor)
                        
                        Text("Import coupons from text or file. Format: 'YYYY-MM-DD HH:MM:SS|message|USED' or plain messages.")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.textSecondary)
                            .lineSpacing(4)
                        
                        Button(action: {
                            showingFilePicker = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 18))
                                Text("Import from File")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.buttonTextOnColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.warmOrange, Color.warmAmber],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                        
                        HStack {
                            Rectangle()
                                .fill(Color.textSecondary.opacity(0.3))
                                .frame(height: 1)
                            Text("or paste manually")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal, 16)
                            Rectangle()
                                .fill(Color.textSecondary.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 8)
                        
                        // Enhanced bulk text input area
                        VStack(spacing: 12) {
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.cardBackground)
                                    .stroke(isTextFieldFocused ? Color.warmOrange : Color.warmOrange.opacity(0.3), lineWidth: isTextFieldFocused ? 2 : 1)
                                    .shadow(color: .warmOrange.opacity(isTextFieldFocused ? 0.2 : 0.1), radius: isTextFieldFocused ? 8 : 4, x: 0, y: 2)
                                
                                if importText.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Paste your coupon data here...")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.textSecondary.opacity(0.6))
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Supported formats:")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.textSecondary.opacity(0.7))
                                            
                                            Text("• Plain SMS messages (one per line)")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.textSecondary.opacity(0.6))
                                            
                                            Text("• Formatted: DATE|message|STATUS")
                                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                                .foregroundColor(.textSecondary.opacity(0.6))
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 20)
                                }
                                
                                TextField("", text: $importText, axis: .vertical)
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(.buttonTextOnColor)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 20)
                                    .lineLimit(8...25)
                                    .focused($isTextFieldFocused)
                                    .textSelection(.enabled)
                            }
                            .frame(minHeight: 200)
                            
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
                                if !importText.isEmpty {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            importText = ""
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
                                
                                // Line and character count
                                if !importText.isEmpty {
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(importText.components(separatedBy: .newlines).count) lines")
                                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                                            .foregroundColor(.textSecondary)
                                        Text("\(importText.count) chars")
                                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                                            .foregroundColor(.textSecondary)
                                    }
                                    .transition(.opacity)
                                }
                            }
                            .animation(.easeInOut(duration: 0.2), value: importText.isEmpty)
                        }
                        
                        Button("Import Coupons") {
                            Task {
                                await store.bulkImport(from: importText.trimmingCharacters(in: .whitespacesAndNewlines))
                                if store.errorMessage == nil {
                                    dismiss()
                                }
                            }
                        }
                        .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isLoading)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.buttonTextOnColor)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isLoading
                                        ? [Color.textSecondary, Color.textSecondary]
                                        : [Color.warmOrange, Color.warmAmber],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        
                        Spacer(minLength: 50)
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.okamiRed)
                    .fontWeight(.semibold)
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [UTType.text],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
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
                importText = clipboardContent
            }
            // Auto-focus after pasting
            isTextFieldFocused = true
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            guard url.startAccessingSecurityScopedResource() else {
                store.errorMessage = "Failed to access file permissions"
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                let fileContent = try String(contentsOf: url, encoding: .utf8)
                withAnimation(.easeInOut(duration: 0.3)) {
                    importText = fileContent
                }
                
                Task {
                    await store.bulkImport(from: fileContent)
                    if store.errorMessage == nil {
                        await MainActor.run {
                            dismiss()
                        }
                    }
                }
            } catch {
                store.errorMessage = "Failed to read file: \(error.localizedDescription)"
            }
        case .failure(let error):
            store.errorMessage = "File selection failed: \(error.localizedDescription)"
        }
    }
}