import UIKit

enum MapState: Codable {
    case locked
    case regular
}

protocol FileCollectionViewCellDelegate: AnyObject {
    func deleteMap(with name: String)
    func lockMap(state: MapState, with name: String)
}

class FileCollectionViewCell: UICollectionViewCell {
    
    var mapName: String?
    var state: MapState?
    weak var delegate: FileCollectionViewCellDelegate?
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var nameButton: UIButton!
    @IBOutlet weak var editView: UIView!
    @IBOutlet weak var lockButton: UIButton!
    @IBOutlet weak var stateImageView: UIImageView!
    
    func configureUI(name: String, image: UIImage, state: MapState) {
        mapName = name
        self.state = state
        containerView.backgroundColor = UIColor.backgroundLight
        
        // adding shadow
        containerView.layer.shadowColor = UIColor.white.cgColor
        containerView.layer.shadowOpacity = 0.5
        containerView.layer.shadowOffset = .zero
        containerView.layer.shadowRadius = 4
        
        nameButton.setTitle(name, for: .normal)
        editView.isHidden = true
        
        stateImageView.isHidden = state == .regular ? true : false
        previewImageView.image = state == .regular ? image : UIImage(named: "folder")
        lockButton.setTitle(state == .regular ? "Lock map" : "Unlock map", for: .normal)
    }
    
    @IBAction func editDidTap(_ sender: Any) {
        UIView.transition(with: self.editView, duration: 0.4, options: .transitionCrossDissolve, animations: {
            self.editView.isHidden = !self.editView.isHidden
        })
    }
    
    @IBAction func deleteDidTap(_ sender: Any) {
        if let mapName = mapName {
            delegate?.deleteMap(with: mapName)
            editView.isHidden = !editView.isHidden
        }
    }
    
    @IBAction func lockDidTap(_ sender: Any) {
        state = state == .regular ? .locked : .regular
        if let mapName = mapName, let state = state {
            delegate?.lockMap(state: state, with: mapName)
            editView.isHidden = !editView.isHidden
        }
    }
    
}
