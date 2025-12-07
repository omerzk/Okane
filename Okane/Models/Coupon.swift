import Foundation
import UIKit

struct Coupon: Identifiable, Codable, Equatable {
    let id: UUID
    let url: String
    let barcodeNumber: String
    let barcodeImageData: Data
    let dateAdded: Date
    let value: Double // In NIS
    let originalMessage: String? // Full SMS text
    var isUsed: Bool = false
    let storeName: String? // Normalized store name for filtering
    let storeDisplayName: String? // Original capitalization for display

    init(url: String, barcodeNumber: String, barcodeImageData: Data, dateAdded: Date, value: Double, originalMessage: String?, isUsed: Bool = false, storeName: String? = nil, storeDisplayName: String? = nil) {
        self.id = UUID()
        self.url = url
        self.barcodeNumber = barcodeNumber
        self.barcodeImageData = barcodeImageData
        self.dateAdded = dateAdded
        self.value = value
        self.originalMessage = originalMessage
        self.isUsed = isUsed
        self.storeName = storeName
        self.storeDisplayName = storeDisplayName
    }

    var barcodeImage: UIImage? {
        return UIImage(data: barcodeImageData)
    }

    var formattedValue: String {
        return String(format: "₪%.2f", value)
    }

    var displayStore: String {
        return storeDisplayName ?? "Unknown"
    }
}