import UIKit

extension UIColor {
    static let accentViolet = UIColor(red: 73.0 / 256.0, green: 41.0 / 256.0, blue: 187.0 / 256.0, alpha: 1.0)
    static let backgroundViolet = UIColor(red: 28.0 / 256.0, green: 23.0 / 256.0, blue: 46.0 / 256.0, alpha: 1.0)
    static let backgroundLight = UIColor(red: 35.0 / 256.0, green: 30.0 / 256.0, blue: 54.0 / 256.0, alpha: 1.0)
    static let error = UIColor(red: 238.0 / 256.0, green: 112.0 / 256.0, blue: 157.0 / 256.0, alpha: 1.0)
    static let regularLight = UIColor(red: 188.0 / 256.0, green: 184.0 / 256.0, blue: 204.0 / 256.0, alpha: 1.0)
    
    
    func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}
