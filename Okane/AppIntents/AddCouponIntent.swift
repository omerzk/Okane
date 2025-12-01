import AppIntents

struct AddCouponIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Coupon from SMS"
    static var description = IntentDescription("Automatically add a coupon from an SMS message")
    
    @Parameter(title: "SMS Message")
    var messageText: String
    
    func perform() async throws -> some IntentResult {
        let store = CouponStore()
        
        do {
            try await store.addCouponFromIntent(message: messageText)
            return .result(dialog: "Coupon successfully added to Okane!")
        } catch CouponError.duplicateCoupon {
            // Duplicate is not really a failure - the coupon exists
            return .result(dialog: "This coupon was already in your wallet.")
        } catch CouponError.invalidURL {
            throw $messageText.needsValueError("No valid coupon URL found in the message.")
        } catch {
            throw $messageText.needsValueError("Failed to add coupon: \(error.localizedDescription)")
        }
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