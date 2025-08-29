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