import Foundation
import CoreImage
import UIKit

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