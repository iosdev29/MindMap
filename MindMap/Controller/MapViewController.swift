import UIKit
import LocalAuthentication

class MapViewController: UIViewController {
    
    // MARK: Stored properties
    var rootNodeName: String?
    
    var mapFile: MapFile?
    var state: MapState?
    var deleteMap = false
    
    private let fileStorage = FileStorage()
    
    // MARK: Outlet properties
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var lockButton: UIBarButtonItem!

    var mapScrollView: MapScrollView!
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapScrollView = MapScrollView(frame: view.bounds)
        view.addSubview(mapScrollView)
        setupMapScrollView()
        mapScrollView.mapDelegate = self
        view.backgroundColor = UIColor.backgroundLight
        configureLockButton()
        
        if let rootNodeName = rootNodeName {
            //create new map
            mapScrollView.configureUI(rootNodeName: rootNodeName)
        } else if let mapFile = mapFile {
            //open old map
            let size = CGSize(width: mapFile.contentViewSize.width, height: mapFile.contentViewSize.height)
            mapScrollView.configureUI(viewSize: size, mapFile: mapFile)
            UserDefaults.standard.set(mapFile.state == .locked ? true : false, forKey: String.isFileLocked)
        }
    }
    
    func setupMapScrollView() {
        mapScrollView.translatesAutoresizingMaskIntoConstraints = false
        mapScrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        mapScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        mapScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        mapScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.topItem?.title = " "
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UserDefaults.standard.set(false, forKey: String.isFileLocked)
        
        if self.isMovingFromParent, deleteMap == false {
            self.mapScrollView.saveMap()
        }
    }

    @IBAction func exportButtonDidTap(_ sender: Any) {
        if let rootNodeName = mapScrollView.rootNode?.name {
            // adding file to share
            var filesToShare = [Any]()
            filesToShare.append(fileStorage.documentDirectoryPath("\(rootNodeName)\(String.mmdExtension)"))
            
            let activity = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
            activity.excludedActivityTypes = [.airDrop]
            if UIDevice.current.userInterfaceIdiom == .pad {
                activity.modalPresentationStyle = .popover
                activity.popoverPresentationController?.barButtonItem = shareButton
            }
            self.present(activity, animated: true, completion: nil)
        }
    }
    
    @IBAction func lockButtonDidTap(_ sender: Any) {
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Protect with Touch ID") { success, error in
            if success {
                //lock file
                DispatchQueue.main.async {
                    self.state = self.state == .regular ? .locked : .regular
                    self.mapScrollView.state = self.state
                    self.mapScrollView.saveMap()
                    UserDefaults.standard.set(self.state == .locked ? true : false, forKey: String.isFileLocked)
                    self.configureLockButton()
                }
            } else {
                ErrorReporting.showMessage(title: "Error", message: "Wasn't able to lock your map!")
            }
        }
    }
    
    func configureLockButton() {
        lockButton.image = UIImage(systemName: state == .regular ? "lock.open" : "lock")
    }
    
}

extension MapViewController: MapScrollViewDelegate {
    func presentAlert(mapFile: MapFile) {
        let alert = UIAlertController(title: "Do you want to delete map? 🤯", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
            self.deleteMap = true
            let rootName = mapFile.rootNode.name
            do {
                try self.fileStorage.deleteFile(atPath: "\(rootName)\(String.pngExtension)")
                try self.fileStorage.deleteFile(atPath: "\(rootName)\(String.mmdExtension)")
                self.navigationController?.popViewController(animated: true)
            } catch  {
                ErrorReporting.showMessage(title: "Error", message: "Wasn't able to delete your map!")
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
}
