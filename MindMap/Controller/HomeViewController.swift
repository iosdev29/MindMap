import UIKit
import LocalAuthentication

class HomeViewController: UIViewController {
    // MARK: Stored properties
    
    var sections = Section.allCases
    private let fileStorage = FileStorage()
    
    // MARK: Outlet properties
    let alert = AlertView(frame: .zero)
    lazy var searchBar = UISearchBar(frame: .zero)
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var arrowImage: UIImageView!
    @IBOutlet weak var logoImage: UIImageView!
    
    var recentFiles = [MapFile]()
    var allFiles = [MapFile]()
    
    // MARK: Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureUI()
    }
    
    func configureUI() {
        reloadData()
        
        searchBar.delegate = self
        let textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = .white
        textFieldInsideSearchBar?.leftView?.tintColor = .white
        
        searchBar.tintColor = .white
        
        if allFiles.isEmpty {
            collectionView.isHidden = true
            logoImage.isHidden = false
            arrowImage.isHidden = false
            navigationItem.titleView = nil
        } else {
            // configuring searchBar
            searchBar.placeholder = "Search"
            searchBar.sizeToFit()
            navigationItem.titleView = searchBar
            collectionView.isHidden = false
            logoImage.isHidden = true
            arrowImage.isHidden = true
        }
    }
    
    func reloadData() {
        // fetch all files
        allFiles = fetchAllDocs()

        //fetch recent files
        recentFiles = fetchRecentDocs()
        
        collectionView.reloadData()
    }
    
    func fetchAllDocs() -> [MapFile] {
        var mapFiles = [MapFile]()
        let filesPath = fileStorage.getAllFiles(with: String.mmdExtension)
        filesPath.forEach { path in
            do {
                let encodedMapFile = try self.fileStorage.getFile(atPath: path)
                let mapData = try JSONDecoder().decode(MapFile.self, from: encodedMapFile)
                if let imageData = try? fileStorage.getFile(atPath: "\(mapData.rootNode.name)\(String.pngExtension)"), let image = UIImage(data: imageData, scale: 1.0) {
                    mapFiles.append(MapFile(image: image, rootNode: mapData.rootNode, contentViewSize: mapData.contentViewSize, state: mapData.state))
                } else {
                    mapFiles.append(MapFile(image: UIImage(named: "folder")!, rootNode: mapData.rootNode, contentViewSize: mapData.contentViewSize, state: mapData.state))
                }
            } catch {
                print(error)
            }
        }
        return mapFiles
    }
    
    func fetchRecentDocs() -> [MapFile] {
        var mapFiles = [MapFile]()
        let filesPath = fileStorage.getRecentFiles(with: String.mmdExtension).prefix(4)
        filesPath.forEach { path in
            do {
                let encodedMapFile = try self.fileStorage.getFile(atPath: path)
                let mapData = try JSONDecoder().decode(MapFile.self, from: encodedMapFile)
                if let imageData = try? fileStorage.getFile(atPath: "\(mapData.rootNode.name)\(String.pngExtension)"), let image = UIImage(data: imageData, scale: 1.0) {
                    mapFiles.append(MapFile(image: image, rootNode: mapData.rootNode, contentViewSize: mapData.contentViewSize, state: mapData.state))
                } else {
                    mapFiles.append(MapFile(image: UIImage(named: "folder")!, rootNode: mapData.rootNode, contentViewSize: mapData.contentViewSize, state: mapData.state))
                }
            }  catch {
                print(error)
            }
        }
        return mapFiles
    }
    
    func openMap(mapFile: MapFile) {
        guard let mapVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "MapViewController") as? MapViewController else { return }
        let state = mapFile.state
        mapVC.mapFile = mapFile
        mapVC.state = state
        
        if state == .locked {
            let context = LAContext()
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Protect with Touch ID") { success, error in
                if success {
                    //show locked file
                    DispatchQueue.main.async {
                        self.navigationController?.pushViewController(mapVC, animated: true)
                    }
                } else {
                    ErrorReporting.showMessage(title: "Error", message:  "This file is private! ❌")
                }
            }
        } else {
            DispatchQueue.main.async {
            self.navigationController?.pushViewController(mapVC, animated: true)
            }
        }
    }
    
    // MARK: Functions
    @IBAction private func addButtonDidTap(_ sender: Any) {
        arrowImage.isHidden = true
        // configure alert
        alert.translatesAutoresizingMaskIntoConstraints = false
        alert.delegate = self
        
        view.addSubview(alert)
        alert.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        alert.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        alert.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        alert.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    // MARK: CollectionView Helpers
    enum Section: Int, CaseIterable {
        case recent
        case all
    }
    
    func sectionAt(_ indexPath: Int) -> Section {
        return sections[indexPath]
    }
    
    private func indexPath(for section: Section) -> IndexPath? {
        return IndexPath(row: section.rawValue, section: 0)
    }
    
    func reloadRow(_ section: Section) {
        guard let indexPath = self.indexPath(for: section) else { return }
        self.collectionView.reloadSections([indexPath.section])
    }
}

//MARK: - AlertView Delegate
extension HomeViewController: AlertViewDelegate {
    
    func closeAlert() {
        alert.removeFromSuperview()
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func addNode(name: String) {
        // presenting Map View Controller
        closeAlert()
        guard let mapVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "MapViewController") as? MapViewController else { return }
        mapVC.rootNodeName = name
        mapVC.state = .regular
        self.navigationController?.pushViewController(mapVC, animated: true)
    }
    
}

//MARK: - UICollectionViewDelegate
extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sectionAt(section) == .all ? allFiles.count : recentFiles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FileCollectionViewCell",for: indexPath) as? FileCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        cell.delegate = self
        switch sectionAt(indexPath.section) {
        case .all:
            cell.configureUI(name: allFiles[indexPath.item].rootNode.name, image: allFiles[indexPath.item].image, state: allFiles[indexPath.item].state)
        case .recent:
            cell.configureUI(name: recentFiles[indexPath.item].rootNode.name, image: recentFiles[indexPath.item].image, state: recentFiles[indexPath.item].state)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let noOfCellsInRow = UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let totalSpace = flowLayout.sectionInset.left + flowLayout.sectionInset.right + (flowLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))
        let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(noOfCellsInRow))
        
        return CGSize(width: size, height: size * 2 / 3)
    }
    
    // sections inset
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: sectionAt(section) == .recent ? 64 : 0, right: 0)
    }
    
    // configure header view
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "HCollectionReusableView", for: indexPath) as! HeaderCollectionView
            header.configure(title: sectionAt(indexPath.section) == .recent ? "Recent" : "All")
            return header
        } else {
            return UICollectionReusableView()
        }
    }
    
    // configure header height
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let mapFile = sectionAt(indexPath.section) == .all ? allFiles[indexPath.item] : recentFiles[indexPath.item]
        openMap(mapFile: mapFile)
    }
}

//MARK: - FileCollectionViewCellDelegate
extension HomeViewController: FileCollectionViewCellDelegate {
    func deleteMap(with name: String) {
        do {
            try fileStorage.deleteFile(atPath: "\(name)\(String.pngExtension)")
            try fileStorage.deleteFile(atPath: "\(name)\(String.mmdExtension)")
            configureUI()
        } catch {
            ErrorReporting.showMessage(title: "Error", message: "Wasn't able to delete your map!")
        }
    }
    
    func lockMap(state: MapState, with name: String) {
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Protect with Touch ID") { success, error in
            if success {
                //lock file
                do {
                    // getting old file
                    let encodedMapFile = try self.fileStorage.getFile(atPath: "\(name)\(String.mmdExtension)")
                    let mapData = try JSONDecoder().decode(MapFile.self, from: encodedMapFile)
                    
                    // re-writing old file with a new state
                    let mapFile = MapFile(image: mapData.image, rootNode: mapData.rootNode, contentViewSize: mapData.contentViewSize, state: state)
                    let encodedFile = try JSONEncoder().encode(mapFile)
                    try self.fileStorage.writeFile(encodedFile, atPath: "\(name)\(String.mmdExtension)")
                    
                    DispatchQueue.main.async {
                        self.reloadData()
                    }
                } catch {
                    ErrorReporting.showMessage(title: "Error", message: "Wasn't able to lock your map!")
                }
            } else {
                ErrorReporting.showMessage(title: "Error", message: "Wasn't able to lock your map!")
            }
        }
    }
}

//MARK: - UISearchBarDelegate
extension HomeViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        guard let searchVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "SearchViewController") as? SearchViewController else {
            return
        }
        self.navigationController?.pushViewController(searchVC, animated: true)
    }
}
