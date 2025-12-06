import AppIntents
import UserNotifications

struct AddCouponIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Coupon from SMS"
    static var description = IntentDescription("Automatically add a coupon from an SMS message")

    @Parameter(title: "SMS Message")
    var messageText: String

    @MainActor
    func perform() async throws -> some IntentResult {
        // Use shared store instance to ensure app sees updates immediately
        let store = CouponStore.shared

        // Quick validation before queuing
        guard store.extractURL(from: messageText) != nil else {
            throw $messageText.needsValueError("No valid coupon URL found in the message.")
        }

        // Queue the work in background to avoid timeout
        Task.detached(priority: .userInitiated) {
            await store.addCouponInBackground(message: messageText)
        }

        // Return silently - user will get notification when complete
        return .result()
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