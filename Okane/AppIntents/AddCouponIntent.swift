import AppIntents

struct AddCouponIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Coupon from SMS"
    static var description = IntentDescription("Automatically add a coupon from an SMS message")
    
    @Parameter(title: "SMS Message")
    var messageText: String
    
    func perform() async throws -> some IntentResult {
        let store = CouponStore()
        
        // Clear any existing error state
        await MainActor.run {
            store.errorMessage = nil
            store.retryableError = nil
        }
        
        // Perform the coupon addition and wait for completion
        await store.addCoupon(from: messageText)
        
        // Wait a brief moment for any async operations to complete
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Check for any errors after operation completion
        let errorMessage = await MainActor.run {
            store.errorMessage ?? store.retryableError
        }
        
        if let error = errorMessage {
            throw $messageText.needsValueError("Failed to add coupon: \(error)")
        }
        
        return .result(dialog: "Coupon successfully added to Okane!")
    }
}

struct AddCouponShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddCouponIntent(),
            phrases: [
                "Add coupon with \(.applicationName)",
                "Add Shufersal coupon"
            ],
            shortTitle: "Add Coupon",
            systemImageName: "qrcode.viewfinder"
        )
    }
}