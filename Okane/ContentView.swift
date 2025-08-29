import SwiftUI
import Foundation
import Combine
import UniformTypeIdentifiers
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

// MARK: - Helper Functions
func generateBarcode(from text: String, scale: CGFloat = 3.0) -> UIImage? {
    let data = text.data(using: String.Encoding.ascii)
    
    if let filter = CIFilter(name: "CICode128BarcodeGenerator") {
        filter.setValue(data, forKey: "inputMessage")
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        
        if let output = filter.outputImage?.transformed(by: transform) {
            let context = CIContext()
            let cgImage = context.createCGImage(output, from: output.extent)!
            return UIImage(cgImage: cgImage)
        }
    }
    
    return nil
}

// MARK: - Network Retry Helper
class NetworkRetryHelper {
    static func performWithRetry<T>(
        maxRetries: Int = 3,
        delay: TimeInterval = 1.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                if attempt < maxRetries - 1 {
                    let backoffDelay = delay * pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? CouponError.networkError
    }
}

// MARK: - Custom Shapes for Okami Style
struct OrganiqueShape: Shape {
    let variant: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        switch variant {
        case 0: // Flowing rectangle
            path.move(to: CGPoint(x: width * 0.05, y: height * 0.1))
            path.addCurve(
                to: CGPoint(x: width * 0.95, y: height * 0.05),
                control1: CGPoint(x: width * 0.3, y: height * -0.02),
                control2: CGPoint(x: width * 0.7, y: height * 0.12)
            )
            path.addCurve(
                to: CGPoint(x: width * 0.98, y: height * 0.85),
                control1: CGPoint(x: width * 1.02, y: height * 0.3),
                control2: CGPoint(x: width * 1.01, y: height * 0.6)
            )
            path.addCurve(
                to: CGPoint(x: width * 0.05, y: height * 0.95),
                control1: CGPoint(x: width * 0.7, y: height * 1.02),
                control2: CGPoint(x: width * 0.3, y: height * 0.88)
            )
            path.addCurve(
                to: CGPoint(x: width * 0.05, y: height * 0.1),
                control1: CGPoint(x: width * -0.02, y: height * 0.7),
                control2: CGPoint(x: width * 0.02, y: height * 0.4)
            )
            
        case 1: // Brush stroke background
            path.move(to: CGPoint(x: 0, y: height * 0.3))
            path.addCurve(
                to: CGPoint(x: width, y: height * 0.2),
                control1: CGPoint(x: width * 0.3, y: height * 0.1),
                control2: CGPoint(x: width * 0.7, y: height * 0.4)
            )
            path.addCurve(
                to: CGPoint(x: width, y: height * 0.8),
                control1: CGPoint(x: width * 1.1, y: height * 0.5),
                control2: CGPoint(x: width * 0.9, y: height * 0.6)
            )
            path.addCurve(
                to: CGPoint(x: 0, y: height * 0.7),
                control1: CGPoint(x: width * 0.7, y: height * 0.9),
                control2: CGPoint(x: width * 0.3, y: height * 0.6)
            )
            path.closeSubpath()
            
        default: // Ink splash
            let centerX = width * 0.5
            let centerY = height * 0.5
            path.addEllipse(in: CGRect(x: centerX - width * 0.4, y: centerY - height * 0.3, width: width * 0.8, height: height * 0.6))
        }
        
        return path
    }
}

struct InkSplatterShape: Shape {
    let drops: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        for i in 0..<drops {
            let angle = Double(i) * 2 * .pi / Double(drops)
            let radius = rect.width * 0.1 * Double.random(in: 0.3...1.0)
            let centerX = rect.width * 0.5 + CGFloat(cos(angle) * radius)
            let centerY = rect.height * 0.5 + CGFloat(sin(angle) * radius)
            let size = CGFloat.random(in: 2...8)
            
            path.addEllipse(in: CGRect(x: centerX - size/2, y: centerY - size/2, width: size, height: size))
        }
        
        return path
    }
}

// MARK: - Models
struct Coupon: Identifiable, Codable {
    let id: UUID
    let url: String
    let barcodeNumber: String
    let barcodeImageData: Data
    let dateAdded: Date
    let value: Double // In NIS
    let originalMessage: String? // Full SMS text
    var isUsed: Bool = false
    
    init(url: String, barcodeNumber: String, barcodeImageData: Data, dateAdded: Date, value: Double, originalMessage: String?, isUsed: Bool = false) {
        self.id = UUID()
        self.url = url
        self.barcodeNumber = barcodeNumber
        self.barcodeImageData = barcodeImageData
        self.dateAdded = dateAdded
        self.value = value
        self.originalMessage = originalMessage
        self.isUsed = isUsed
    }
    
    var barcodeImage: UIImage? {
        return UIImage(data: barcodeImageData)
    }
    
    var formattedValue: String {
        return String(format: "₪%.2f", value)
    }
}

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
    
    private let userDefaults = UserDefaults.standard
    private let couponsKey = "saved_coupons"
    
    var filteredCoupons: [Coupon] {
            let baseFiltered = showUsedCoupons ? coupons : coupons.filter { !$0.isUsed }
            return baseFiltered
        }
    
    var totalValue: Double {
        return filteredCoupons.reduce(0) { $0 + $1.value }
    }
    
    var unusedValue: Double {
        return filteredCoupons.filter { !$0.isUsed }.reduce(0) { $0 + $1.value }
    }
    
    var usedValue: Double {
        return coupons.filter { $0.isUsed }.reduce(0) { $0 + $1.value }
    }
    
    init() {
        if userDefaults.object(forKey: "structure_version") == nil {
            userDefaults.removeObject(forKey: couponsKey)
            userDefaults.set("v2", forKey: "structure_version")
        }
        loadCoupons()
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
        coupons.removeAll { $0.id == coupon.id }
        saveCoupons()
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
}

enum CouponError: LocalizedError {
    case invalidURL
    case invalidHTML
    case barcodeNotFound
    case networkError
    case duplicateCoupon
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidHTML:
            return "Could not read webpage"
        case .barcodeNotFound:
            return "Could not find barcode on page"
        case .networkError:
            return "Network connection failed"
        case .duplicateCoupon:
            return "Coupon already exists"
        }
    }
}

// MARK: - Warm Modern Color Palette
extension Color {
    static let warmOrange = Color(red: 0.95, green: 0.6, blue: 0.2)
    static let warmAmber = Color(red: 0.98, green: 0.7, blue: 0.3)
    static let warmRed = Color(red: 0.9, green: 0.3, blue: 0.2)
    static let warmGreen = Color(red: 0.4, green: 0.7, blue: 0.3)
    static let warmBlue = Color(red: 0.3, green: 0.5, blue: 0.8)
    
    // Backgrounds
    static let backgroundPrimary = Color(red: 0.99, green: 0.98, blue: 0.96)
    static let backgroundSecondary = Color(red: 0.97, green: 0.95, blue: 0.92)
    static let cardBackground = Color.white
    
    // Text colors
    static let textPrimary = Color(red: 0.2, green: 0.2, blue: 0.2)
    static let textSecondary = Color(red: 0.5, green: 0.5, blue: 0.5)
    static let textAccent = Color(red: 0.6, green: 0.4, blue: 0.2)
    
    static let okamiGold = Color(red: 0.92, green: 0.7, blue: 0.15)
    static let okamiRed = Color(red: 0.85, green: 0.2, blue: 0.1)
    static let okamiEarth = Color(red: 0.45, green: 0.25, blue: 0.1)
    static let okamiParchment = Color(red: 0.98, green: 0.96, blue: 0.92)
    static let okamiAmber = Color(red: 0.95, green: 0.75, blue: 0.2)
}

// MARK: - Enhanced Views with Okami Aesthetics
struct ContentView: View {
    @StateObject private var store = CouponStore()
    @State private var showingAddCoupon = false
    @State private var showingBulkImport = false
    @State private var searchText = ""
    @State private var optimizationResults: [Coupon] = []
    @State private var optimizationTarget: Double = 0
    @State private var sortAscending = false
    @State private var scrollOffset: CGFloat = 0
    
    private func performOptimization() {
            // Clear previous results
            optimizationResults = []
            optimizationTarget = 0
            
            // Validate and clean input
            let cleanedInput = searchText.replacingOccurrences(of: "₪", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let searchValue = Double(cleanedInput), searchValue > 0 else {
                return
            }
            
            optimizationTarget = searchValue
            optimizationResults = findOptimalCouponCombination(target: searchValue, availableCoupons: store.filteredCoupons)
        }
        
        private func clearOptimization() {
            optimizationResults = []
            optimizationTarget = 0
        }
    
    var filteredCoupons: [Coupon] {
        let baseCoupons = store.filteredCoupons
        
        // If we have optimization results, show them
        if !optimizationResults.isEmpty {
            return optimizationResults.filter { !$0.isUsed }
        }
        
        // Otherwise show all coupons with date sorting
        return baseCoupons.sorted { coupon1, coupon2 in
            if sortAscending {
                return coupon1.dateAdded < coupon2.dateAdded
            } else {
                return coupon1.dateAdded > coupon2.dateAdded
            }
        }
    }
    
    private func findOptimalCouponCombination(target: Double, availableCoupons: [Coupon]) -> [Coupon] {
        // Filter only unused coupons for optimization
        let unusedCoupons = availableCoupons.filter { !$0.isUsed }
        
        // Sort coupons: by value ASC, then by date ASC (older first for ties)
        let sortedCoupons = unusedCoupons.sorted { coupon1, coupon2 in
            if coupon1.value == coupon2.value {
                return coupon1.dateAdded < coupon2.dateAdded
            }
            return coupon1.value < coupon2.value
        }
        
        let targetCents = Int(target * 100) // Work with cents to avoid floating point issues
        let n = sortedCoupons.count
        
        if n == 0 || targetCents <= 0 {
            return []
        }
        
        // DP with item tracking: dp[i][w] = max value achievable using first i items with weight limit w
        var dp = Array(repeating: Array(repeating: 0, count: targetCents + 1), count: n + 1)
        
        // Fill DP table
        for i in 1...n {
            let couponValue = Int(sortedCoupons[i-1].value * 100)
            
            for w in 0...targetCents {
                // Don't take current coupon
                dp[i][w] = dp[i-1][w]
                
                // Take current coupon if it fits
                if couponValue <= w {
                    let valueWithCoupon = dp[i-1][w - couponValue] + couponValue
                    dp[i][w] = max(dp[i][w], valueWithCoupon)
                }
            }
        }
        
        // Find the maximum value achieved
        let maxValue = dp[n][targetCents]
        
        if maxValue == 0 {
            return []
        }
        
        // Backtrack to find which coupons were selected
        var result: [Coupon] = []
        var w = targetCents
        
        for i in stride(from: n, through: 1, by: -1) {
            // If dp[i][w] != dp[i-1][w], then coupon i-1 was included
            if dp[i][w] != dp[i-1][w] {
                result.append(sortedCoupons[i-1])
                w -= Int(sortedCoupons[i-1].value * 100)
            }
        }
        
        // Sort result by date (older first)
        return result.sorted { $0.dateAdded < $1.dateAdded }
    }
    
    var headerHeight: CGFloat {
        let baseHeight: CGFloat = 400
        let minHeight: CGFloat = 140
        let scrollThreshold: CGFloat = 200
        
        if scrollOffset <= 0 {
            return baseHeight
        } else if scrollOffset >= scrollThreshold {
            return minHeight
        } else {
            let progress = scrollOffset / scrollThreshold
            return baseHeight - (baseHeight - minHeight) * progress
        }
    }
    
    private func updateOptimizationResults() {
        // Remove used coupons from optimization results
        optimizationResults = optimizationResults.filter { !$0.isUsed }
        
        // If all coupons in the optimization are now used, clear the results
        if optimizationResults.isEmpty && optimizationTarget > 0 {
            clearOptimization()
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Okami-style textured background
                ZStack {
                    Color.okamiParchment
                        .ignoresSafeArea()

                    OrganiqueShape(variant: 1)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.okamiGold.opacity(0.08),
                                    Color.okamiAmber.opacity(0.06),
                                    Color.okamiEarth.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(-15))
                        .scaleEffect(1.2)
                }

                VStack(spacing: 0) {
                    if store.coupons.isEmpty {
                        Spacer()
                        EmptyStateView()
                        Spacer()
                    } else {
                        VStack(spacing: 0) {
                            // Main scrollable content
                            ScrollView {
                                VStack(spacing: 0) {
                                    // Full header
                                    CollapsibleStatsHeaderView(
                                        store: store,
                                        displayedCoupons: filteredCoupons,
                                        height: headerHeight,
                                        scrollOffset: scrollOffset
                                    )
                                    .padding(.horizontal, 20)

                                    // Optimization header when showing search results
                                    if !optimizationResults.isEmpty {
                                        OptimizationHeaderView(
                                            target: optimizationTarget,
                                            suggestions: optimizationResults
                                        )
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 16)
                                    }

                                    // Scroll offset tracking GeometryReader
                                    GeometryReader { geometry in
                                        Color.clear
                                            .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                                    }
                                    .frame(height: 0)

                                    // Coupons list with smooth filtering transitions
                                    LazyVStack(spacing: 12) {
                                        ForEach(filteredCoupons.indices, id: \.self) { index in
                                            CouponRowView(coupon: filteredCoupons[index], store: store) {
                                                // Remove used coupons from optimization results
                                                optimizationResults = optimizationResults.filter { !$0.isUsed }

                                                // If all coupons in the optimization are now used, clear the results
                                                if optimizationResults.isEmpty && optimizationTarget > 0 {
                                                    clearOptimization()
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                            .transition(.asymmetric(
                                                insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .bottom)),
                                                removal: .scale(scale: 0.9).combined(with: .opacity).combined(with: .move(edge: .leading))
                                            ))
                                        }

                                        Color.clear
                                            .frame(height: 80)
                                    }
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: store.showUsedCoupons)
                                }
                            }
                            .coordinateSpace(name: "scroll")
                            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                                scrollOffset = max(0, -value + 100.0)
                            }
                        }
                        .searchable(text: $searchText, prompt: "How much?")
                        .onSubmit(of: .search) {
                            performOptimization()
                        }
                        .onChange(of: searchText) { oldValue, newValue in
                            // If search text becomes empty (cancel pressed), clear optimization
                            if newValue.isEmpty {
                                clearOptimization()
                                return
                            }

                            // Clear results when user starts typing again
                            if !newValue.isEmpty && newValue != oldValue {
                                clearOptimization()
                            }

                            // Filter input to only allow positive numbers and ₪ symbol
                            let filtered = newValue.filter { char in
                                char.isNumber || char == "." || char == "₪"
                            }

                            if filtered != newValue {
                                searchText = filtered
                            }
                        }
                    }
                }
            }
            .navigationTitle("Okane")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(
                LinearGradient(
                    colors: [Color.warmOrange, Color.warmAmber],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                for: .navigationBar
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation(.spring()) {
                            sortAscending.toggle()
                        }
                    }) {
                        Image(systemName: sortAscending ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0.9)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                            .shadow(color: .okamiGold.opacity(0.3), radius: 4, x: 0, y: 0)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAddCoupon = true }) {
                            Label("Add Single Coupon", systemImage: "plus.circle")
                        }
                        
                        Button(action: { showingBulkImport = true }) {
                            Label("Bulk Import", systemImage: "square.and.arrow.down.on.square")
                        }
                        
                        Divider()
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                store.showUsedCoupons.toggle()
                            }
                        }) {
                            Label(
                                store.showUsedCoupons ? "Hide Used" : "Show Used",
                                systemImage: store.showUsedCoupons ? "eye.slash.fill" : "eye.fill"
                            )
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0.9)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                            .shadow(color: .okamiGold.opacity(0.3), radius: 4, x: 0, y: 0)
                    }
                    .disabled(store.isLoading)
                }
            }
            .sheet(isPresented: $showingAddCoupon) {
                AddCouponView(store: store)
            }
            .sheet(isPresented: $showingBulkImport) {
                BulkImportView(store: store)
            }
            .overlay {
                if store.isLoading {
                    LoadingView()
                }
            }
            .alert("Error", isPresented: .constant(store.errorMessage != nil)) {
                Button("OK") {
                    store.errorMessage = nil
                }
            } message: {
                Text(store.errorMessage ?? "")
            }
            .alert("Network Error", isPresented: .constant(store.retryableError != nil)) {
                Button("Retry") {
                    Task {
                        await store.retryCoupon()
                    }
                }
                Button("Cancel") {
                    store.dismissRetryError()
                }
            } message: {
                Text(store.retryableError ?? "")
            }
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct CollapsibleStatsHeaderView: View {
    @ObservedObject var store: CouponStore
    let displayedCoupons: [Coupon]
    let height: CGFloat
    let scrollOffset: CGFloat
    @State private var shimmerOffset: CGFloat = -200
    
    var isCollapsed: Bool {
        height <= 200
    }
    
    var body: some View {
        VStack(spacing: isCollapsed ? 12 : 25) {
            // Main value display with warm accent
            VStack(spacing: isCollapsed ? 6 : 12) {
                if !isCollapsed {
                    Text("Available")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.textAccent)
                        .textCase(.uppercase)
                        .tracking(2.5)
                }
                
                Text(String(format: "₪%.0f", store.unusedValue))
                    .font(.system(size: isCollapsed ? 28 : 48, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.warmOrange, Color.warmAmber],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .white, radius: 1, x: 0, y: 1)
            }
            .padding(.vertical, isCollapsed ? 16 : 32)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cardBackground)
                        .shadow(color: .warmOrange.opacity(0.15), radius: 8, x: 0, y: 4)
                    
                    // Subtle warm accent
                    if !isCollapsed {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color.warmAmber.opacity(0.1), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            )
            
            if !isCollapsed {
                // Clean stats grid
                HStack(spacing: 0) {
                    VStack(spacing: 8) {
                        Text(String(format: "₪%.0f", store.totalValue))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Text("Total")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Rectangle()
                        .fill(Color.warmOrange.opacity(0.3))
                        .frame(width: 1, height: 40)
                    
                    VStack(spacing: 8) {
                        Text(String(format: "₪%.0f", store.usedValue))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.textSecondary)
                        Text("Used")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Rectangle()
                        .fill(Color.warmOrange.opacity(0.3))
                        .frame(width: 1, height: 40)
                    
                    VStack(spacing: 8) {
                        Text("\(displayedCoupons.count)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.warmBlue)
                        Text("Coupons")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.backgroundSecondary)
                        .shadow(color: .warmOrange.opacity(0.08), radius: 4, x: 0, y: 2)
                )
                .opacity(max(0, 1.0 - (scrollOffset / 150.0)))
                
                // Very subtle hide used controls
                HStack {
                    Spacer()
                    
                    if store.coupons.contains(where: { $0.isUsed }) {
                        Button(action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                store.showUsedCoupons.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: store.showUsedCoupons ? "eye.slash" : "eye")
                                    .font(.system(size: 11, weight: .medium))
                                if !store.showUsedCoupons {
                                    Text("Show")
                                        .font(.system(size: 11, weight: .medium))
                                }
                            }
                            .foregroundColor(.warmOrange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.warmAmber.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                }
                .opacity(max(0.3, 1.0 - (scrollOffset / 80.0)))
            }
        }
        .frame(height: height)
        .clipped()
        .animation(.easeInOut(duration: 0.3), value: height)
        .padding(.bottom, 16)
    }
}

struct CouponRowView: View {
    let coupon: Coupon
    let store: CouponStore
    let onToggleUsed: () -> Void // Add this callback
    @State private var showingBarcode = false
    
    var body: some View {
        HStack(spacing: 25) {
            VStack(spacing: 6) {
                Text(String(format: "₪%.0f", coupon.value))
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(coupon.isUsed ? .textSecondary : .textPrimary)
                    .overlay {
                        // Strikethrough effect for used coupons
                        if coupon.isUsed {
                            Rectangle()
                                .fill(Color.textSecondary)
                                .frame(height: 2)
                                .rotationEffect(.degrees(-5))
                        }
                    }
                
                Text(coupon.dateAdded, style: .date)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .tracking(0.5)
            }
            .frame(width: 90)
            .padding(.vertical, 12)
            
            Spacer()
            
            Image(systemName: coupon.isUsed ? "checkmark.seal.fill" : "qrcode.viewfinder")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(
                    coupon.isUsed
                    ? Color.warmGreen
                    : Color.warmOrange
                )
                .frame(width: 50, height: 50)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 28)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .shadow(color: .warmOrange.opacity(0.1), radius: 6, x: 0, y: 2)
                
                if !coupon.isUsed {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.warmAmber.opacity(0.08), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
        )
        // Keep used coupons clickable and visually distinct with subtle effects
        .saturation(coupon.isUsed ? 0.8 : 1.0) // Increased from 0.5 to 0.8 for better touch recognition
        .opacity(coupon.isUsed ? 0.9 : 1.0)    // Increased from 0.8 to 0.9 for better touch recognition
        .scaleEffect(coupon.isUsed ? 0.98 : 1.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: coupon.isUsed)
        .contentShape(Rectangle())
        .onTapGesture {
            showingBarcode = true
        }
        .swipeActions(edge: .trailing) {
            Button(coupon.isUsed ? "Mark Unused" : "Mark Used") {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    store.toggleUsed(coupon)
                    onToggleUsed() // Call the callback
                }
            }
            .tint(coupon.isUsed ? Color.warmOrange : Color.warmGreen)
            
            Button("Delete") {
                withAnimation(.easeInOut(duration: 0.4)) {
                    store.deleteCoupon(coupon)
                    onToggleUsed() // Also call on delete
                }
            }
            .tint(.warmRed)
        }
        .sheet(isPresented: $showingBarcode) {
            BarcodeView(coupon: coupon, store: store, onToggleUsed: onToggleUsed)
        }
    }
}

struct OptimizationHeaderView: View {
    let target: Double
    let suggestions: [Coupon]
    
    var totalValue: Double {
        suggestions.reduce(0) { $0 + $1.value }
    }
    
    var coverage: Double {
        guard target > 0 else { return 0 }
        return (totalValue / target) * 100
    }
    
    var remaining: Double {
        target - totalValue
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if suggestions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass.circle")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.textSecondary)
                    
                    Text("No combination found")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    Text("No unused coupons can fit under ₪\(String(format: "%.0f", target))")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.backgroundSecondary)
                        .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1)
                )
            } else {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Target: ₪\(String(format: "%.0f", target))")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.textSecondary)
                            
                            Text("Best match: ₪\(String(format: "%.0f", totalValue))")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.textPrimary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(String(format: "%.1f", coverage))%")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(coverage >= 80 ? .warmOrange : .warmAmber)
                            
                            Text("coverage")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    if remaining > 0 {
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.warmBlue)
                            
                            Text("₪\(String(format: "%.0f", remaining)) remaining to pay")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.textSecondary)
                            
                            Spacer()
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.warmAmber.opacity(0.1), Color.warmOrange.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .stroke(Color.warmOrange.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}

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
                            .foregroundColor(.textPrimary)
                        
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
                            .foregroundColor(.white)
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
                                    .foregroundColor(.textPrimary)
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
                        .foregroundColor(.white)
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

@main
struct OkaneApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    init() {
        AddCouponShortcuts.updateAppShortcutParameters()
    }
}
