import AppIntents

struct AddCouponIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Coupon from SMS"
    static var description = IntentDescription("Automatically add a coupon from an SMS message")
    
    @Parameter(title: "SMS Message")
    var messageText: String
    
    func perform() async throws -> some IntentResult {
            let store = CouponStore()
            
            await store.addCoupon(from: messageText)
            
//            if store.errorMessage != nil {
//                throw $messageText.needsValueError("Failed to add coupon: \(store.errorMessage ?? "Unknown error")")
//            }
            
            return .result(dialog: "Coupon added successfully!")
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