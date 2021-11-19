import UIKit

class CustomRoundedTextField: UITextField {
    
    // MARK: Initialize
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    // MARK: Functions
    private func sharedInit() {
        borderStyle = .none
        
        backgroundColor = UIColor.regularLight.withAlphaComponent(0.1)
        layer.borderColor = UIColor.regularLight.cgColor
        layer.borderWidth = 0.5
        layer.cornerRadius = 4
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 50)
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return super.textRect(forBounds: bounds).insetBy(dx: 8, dy: 0)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return super.editingRect(forBounds: bounds).insetBy(dx: 8, dy: 0)
    }
    
}
