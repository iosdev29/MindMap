import UIKit

class HeaderCollectionView: UICollectionReusableView {
    
    @IBOutlet weak var titleLabel: UILabel!
        
    func configure(title: String) {
        titleLabel.text = title
    }
    
}
