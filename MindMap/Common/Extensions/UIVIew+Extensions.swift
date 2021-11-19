import UIKit

extension UIView {
    func rotate() {
        let rotation : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi)
        rotation.duration = 0.3
        rotation.isCumulative = true
        rotation.repeatCount = 1
        self.layer.add(rotation, forKey: "rotationAnimation")
    }
    
    func screenshot() -> UIImage {
       return UIGraphicsImageRenderer(size: bounds.size).image { _ in
         drawHierarchy(in: CGRect(origin: .zero, size: bounds.size), afterScreenUpdates: true)
       }
     }
}

