import SwiftUI

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