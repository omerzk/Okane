import Foundation

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