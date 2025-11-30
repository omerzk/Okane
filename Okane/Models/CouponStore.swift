import Foundation
import SwiftUI

// MARK: - Helper Actor for Thread-Safe Counting
actor ActorCounter {
    private var count = 0
    
    func increment() {
        count += 1
    }
    
    var value: Int {
        count
    }
}

// MARK: - Coupon Store
class CouponStore: ObservableObject {
    @Published var coupons: [Coupon] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showUsedCoupons = false // Default to hiding used coupons
    @Published var retryableError: String?
    @Published var retryingCoupon: String?
    @Published var recentlyDeleted: [(coupon: Coupon, deletedAt: Date)] = []
    
    // UI state management
    @Published var isDarkMode = false
    @Published var showTotals = true // Default to showing values (not censored)
    
    private let userDefaults = UserDefaults.standard
    private let couponsKey = "saved_coupons"
    private let darkModeKey = "dark_mode_preference"
    private let showTotalsKey = "show_totals_preference"
    
    var filteredCoupons: [Coupon] {
            let baseFiltered = showUsedCoupons ? coupons : coupons.filter { !$0.isUsed }
            return baseFiltered
        }
    
    var totalValue: Double {
        return coupons.reduce(0) { $0 + $1.value }
    }
    
    var unusedValue: Double {
        return coupons.filter { !$0.isUsed }.reduce(0) { $0 + $1.value }
    }
    
    var usedValue: Double {
        return coupons.filter { $0.isUsed }.reduce(0) { $0 + $1.value }
    }
    
    // Analytics properties
    var totalSavings: Double {
        return usedValue // Money saved by using coupons
    }
    
    var averageCouponValue: Double {
        guard !coupons.isEmpty else { return 0 }
        return totalValue / Double(coupons.count)
    }
    
    var usageEfficiency: Double {
        guard totalValue > 0 else { return 0 }
        return (usedValue / totalValue) * 100 // Percentage of coupons used
    }
    
    var couponsUsedThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return coupons.filter { coupon in
            coupon.isUsed && coupon.dateAdded >= startOfMonth
        }.count
    }
    
    var couponsAddedThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return coupons.filter { $0.dateAdded >= startOfMonth }.count
    }
    
    var savingsThisMonth: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return coupons.filter { coupon in
            coupon.isUsed && coupon.dateAdded >= startOfMonth
        }.reduce(0) { $0 + $1.value }
    }
    
    var mostActiveDay: String {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE" // Full day name
        
        // Group coupons by day of week
        let dayGroups = Dictionary(grouping: coupons) { coupon in
            dayFormatter.string(from: coupon.dateAdded)
        }
        
        // Find day with most coupons
        guard let mostActiveDay = dayGroups.max(by: { $0.value.count < $1.value.count })?.key else {
            return "No data"
        }
        
        return mostActiveDay
    }
    
    init() {
        if userDefaults.object(forKey: "structure_version") == nil {
            userDefaults.removeObject(forKey: couponsKey)
            userDefaults.set("v2", forKey: "structure_version")
        }
        loadCoupons()
        loadDarkModePreference()
        loadShowTotalsPreference()
    }
    
    func addCoupon(from message: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            retryableError = nil
        }
        
        do {
            guard let url = extractURL(from: message) else {
                throw CouponError.invalidURL
            }
            
            // Check for duplicate URL
            if coupons.contains(where: { $0.url == url }) {
                throw CouponError.duplicateCoupon
            }
            
            let coupon = try await NetworkRetryHelper.performWithRetry {
                try await self.fetchCouponData(from: url, originalMessage: message)
            }
            
            // Double-check for duplicate barcode after fetching
            if coupons.contains(where: { $0.barcodeNumber == coupon.barcodeNumber }) {
                throw CouponError.duplicateCoupon
            }
            
            await MainActor.run {
                coupons.append(coupon)
                saveCoupons()
                isLoading = false
            }
        } catch {
            await MainActor.run {
                if case CouponError.duplicateCoupon = error {
                    errorMessage = "This coupon has already been added to your wallet."
                } else {
                    retryableError = "Failed to fetch coupon: \(error.localizedDescription)"
                    retryingCoupon = message
                }
                isLoading = false
            }
        }
    }
    
    /// Used by App Intents - throws errors directly instead of setting @Published properties.
    /// Uses MainActor.run for all @Published property access to ensure thread safety in background execution.
    func addCouponFromIntent(message: String) async throws {
        guard let url = extractURL(from: message) else {
            throw CouponError.invalidURL
        }
        
        // Check for duplicate URL (MainActor.run for thread-safe @Published access)
        let isDuplicate = await MainActor.run {
            coupons.contains(where: { $0.url == url })
        }
        if isDuplicate {
            throw CouponError.duplicateCoupon
        }
        
        let coupon = try await NetworkRetryHelper.performWithRetry {
            try await self.fetchCouponData(from: url, originalMessage: message)
        }
        
        // Double-check for duplicate barcode after fetching (MainActor.run for thread-safe @Published access)
        let isDuplicateBarcode = await MainActor.run {
            coupons.contains(where: { $0.barcodeNumber == coupon.barcodeNumber })
        }
        if isDuplicateBarcode {
            throw CouponError.duplicateCoupon
        }
        
        await MainActor.run {
            coupons.append(coupon)
            saveCoupons()
        }
    }
    
    func retryCoupon() async {
        guard let message = retryingCoupon else { return }
        await addCoupon(from: message)
    }
    
    func dismissRetryError() {
        retryableError = nil
        retryingCoupon = nil
    }
    
    func bulkImport(from text: String) async {
        let entries = parseBulkImportText(text)
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        await withTaskGroup(of: Void.self) { group in
            let successCount = ActorCounter()
            let failCount = ActorCounter()
            let duplicateCount = ActorCounter()
            
            for entry in entries {
                group.addTask {
                    do {
                        // Check for duplicate URL first
                        let isDuplicateURL = await MainActor.run {
                            self.coupons.contains(where: { $0.url == entry.url })
                        }
                        
                        if isDuplicateURL {
                            await duplicateCount.increment()
                            return
                        }
                        
                        let baseCoupon = try await NetworkRetryHelper.performWithRetry {
                            try await self.fetchCouponData(from: entry.url, originalMessage: entry.message)
                        }
                        
                        // Check for duplicate barcode
                        let isDuplicateBarcode = await MainActor.run {
                            self.coupons.contains(where: { $0.barcodeNumber == baseCoupon.barcodeNumber })
                        }
                        
                        if isDuplicateBarcode {
                            await duplicateCount.increment()
                            return
                        }
                        
                        let coupon = Coupon(
                            url: baseCoupon.url,
                            barcodeNumber: baseCoupon.barcodeNumber,
                            barcodeImageData: baseCoupon.barcodeImageData,
                            dateAdded: entry.date ?? baseCoupon.dateAdded,
                            value: baseCoupon.value,
                            originalMessage: baseCoupon.originalMessage,
                            isUsed: entry.isUsed
                        )
                        
                        await MainActor.run {
                            self.coupons.append(coupon)
                        }
                        await successCount.increment()
                    } catch {
                        await failCount.increment()
                        print("Failed to import coupon: \(entry.url) - \(error)")
                    }
                }
            }
            
            await group.waitForAll()
            
            let successTotal = await successCount.value
            let failTotal = await failCount.value
            let duplicateTotal = await duplicateCount.value
            
            await MainActor.run {
                saveCoupons()
                isLoading = false
                if failTotal > 0 || duplicateTotal > 0 {
                    var messages: [String] = []
                    if successTotal > 0 {
                        messages.append("Imported \(successTotal) coupons")
                    }
                    if duplicateTotal > 0 {
                        messages.append("skipped \(duplicateTotal) duplicates")
                    }
                    if failTotal > 0 {
                        messages.append("failed \(failTotal)")
                    }
                    errorMessage = messages.joined(separator: ", ")
                }
            }
        }
    }
    
    private func parseBulkImportText(_ text: String) -> [(url: String, message: String, date: Date?, isUsed: Bool)] {
        var results: [(url: String, message: String, date: Date?, isUsed: Bool)] = []
        
        let entries = text.components(separatedBy: .newlines)
            .flatMap { $0.components(separatedBy: "---") }
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for entry in entries {
            let trimmedEntry = entry.trimmingCharacters(in: .whitespacesAndNewlines)
            let components = trimmedEntry.components(separatedBy: "|")
            
            let messageText: String
            let parsedDate: Date?
            let isUsed: Bool
            
            if components.count >= 3 {
                let dateString = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                messageText = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                let usedFlag = components[2].trimmingCharacters(in: .whitespacesAndNewlines)
                
                parsedDate = dateFormatter.date(from: dateString)
                isUsed = usedFlag.uppercased() == "USED"
            } else {
                messageText = trimmedEntry
                parsedDate = nil
                isUsed = false
            }
            
            if let url = extractURL(from: messageText) {
                results.append((url: url, message: messageText, date: parsedDate, isUsed: isUsed))
            }
        }
        
        return results
    }
    
    private func extractURL(from text: String) -> String? {
        let pattern = #"https://[^\s]+"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }
        
        let range = Range(match.range, in: text)!
        return String(text[range])
    }
    
    private func extractValue(from message: String) -> Double {
        let patterns = [
            #"₪(\d+\.?\d*)"#,
            #"בסך\s*₪(\d+\.?\d*)"#,
            #"(\d+\.?\d*)\s*₪"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: message, range: NSRange(message.startIndex..., in: message)) {
                let valueRange = Range(match.range(at: 1), in: message)!
                let valueString = String(message[valueRange])
                return Double(valueString) ?? 0.0
            }
        }
        
        return 0.0
    }
    
    private func fetchCouponData(from urlString: String, originalMessage: String) async throws -> Coupon {
        guard let url = URL(string: urlString) else {
            throw CouponError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw CouponError.invalidHTML
        }
        
        guard let barcodeInfo = extractBarcodeInfo(from: html) else {
            throw CouponError.barcodeNotFound
        }
        
        guard let generatedBarcode = generateBarcode(from: barcodeInfo.number, scale: 3.0) else {
            throw CouponError.barcodeNotFound
        }
        
        guard let barcodeImageData = generatedBarcode.pngData() else {
            throw CouponError.barcodeNotFound
        }
        
        let value = extractValue(from: originalMessage)
        
        return Coupon(
            url: urlString,
            barcodeNumber: barcodeInfo.number,
            barcodeImageData: barcodeImageData,
            dateAdded: Date(),
            value: value,
            originalMessage: originalMessage.isEmpty ? nil : originalMessage
        )
    }
    
    private func extractBarcodeInfo(from html: String) -> (number: String, imagePath: String)? {
        let pattern = #"<img alt="(\d+)" src="(bar\.ashx\?[^"]+)""#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)) else {
            return nil
        }
        
        let numberRange = Range(match.range(at: 1), in: html)!
        let imagePathRange = Range(match.range(at: 2), in: html)!
        
        let number = String(html[numberRange])
        let imagePath = String(html[imagePathRange])
        
        return (number: number, imagePath: imagePath)
    }
    
    func toggleUsed(_ coupon: Coupon) {
        if let index = coupons.firstIndex(where: { $0.id == coupon.id }) {
            coupons[index].isUsed.toggle()
            saveCoupons()
        }
    }
    
    func deleteCoupon(_ coupon: Coupon) {
        // Add to recently deleted with timestamp
        recentlyDeleted.append((coupon: coupon, deletedAt: Date()))
        
        // Remove from main list
        coupons.removeAll { $0.id == coupon.id }
        saveCoupons()
        
        // Auto-cleanup after 10 seconds
        Task {
            try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
            await MainActor.run {
                cleanupRecentlyDeleted()
            }
        }
    }
    
    func undoDelete() {
        guard let lastDeleted = recentlyDeleted.popLast() else { return }
        coupons.append(lastDeleted.coupon)
        saveCoupons()
    }
    
    private func cleanupRecentlyDeleted() {
        let cutoff = Date().addingTimeInterval(-10) // 10 seconds ago
        recentlyDeleted.removeAll { $0.deletedAt < cutoff }
    }
    
    private func saveCoupons() {
        if let data = try? JSONEncoder().encode(coupons) {
            userDefaults.set(data, forKey: couponsKey)
        }
    }
    
    private func loadCoupons() {
        guard let data = userDefaults.data(forKey: couponsKey) else { return }
        
        do {
            let decoded = try JSONDecoder().decode([Coupon].self, from: data)
            coupons = decoded
        } catch {
            print("Failed to decode saved coupons, starting fresh: \(error)")
            coupons = []
        }
    }
    
    // MARK: - Dark Mode Management
    private func loadDarkModePreference() {
        isDarkMode = userDefaults.bool(forKey: darkModeKey)
    }
    
    private func saveDarkModePreference() {
        userDefaults.set(isDarkMode, forKey: darkModeKey)
    }
    
    func toggleDarkMode() {
        isDarkMode.toggle()
        saveDarkModePreference()
    }
    
    // MARK: - Show Totals Management
    private func loadShowTotalsPreference() {
        // Default to true if no preference is saved
        if userDefaults.object(forKey: showTotalsKey) != nil {
            showTotals = userDefaults.bool(forKey: showTotalsKey)
        }
    }
    
    private func saveShowTotalsPreference() {
        userDefaults.set(showTotals, forKey: showTotalsKey)
    }
    
    func toggleShowTotals() {
        showTotals.toggle()
        saveShowTotalsPreference()
    }
}