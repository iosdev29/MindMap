import UIKit
import LocalAuthentication

class SearchViewController: UIViewController {
    
    // MARK: Stored properties
    private let fileStorage = FileStorage()
    var searchedFiles = [MapFile]()
    
    lazy var searchBar = UISearchBar(frame: .zero)
    
    // MARK: Outlet properties
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noResultsLabel: UILabel!
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.topItem?.title = " "
    }
    
    func configureUI() {
        navigationItem.titleView = searchBar
        searchBar.delegate = self
        let textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = .white
        textFieldInsideSearchBar?.leftView?.tintColor = .white
        searchBar.becomeFirstResponder()
    }
    
    func reloadData() {
        //fetch searched files
        if let searchText = searchBar.text {
            searchedFiles = fetchSearchedDocuments(search: searchText)
            noResultsLabel.isHidden = !searchedFiles.isEmpty
            collectionView.reloadData()
        }
    }
    
    func fetchSearchedDocuments(search: String) -> [MapFile] {
        var mapFiles = [MapFile]()
        let filesPath = fileStorage.getAllFiles(with: String.mmdExtension)
        filesPath.filter({$0.contains("\(search)")}).forEach { path in
            do {
                let encodedMapFile = try self.fileStorage.getFile(atPath: path)
                let mapData = try JSONDecoder().decode(MapFile.self, from: encodedMapFile)
                let imageData = try fileStorage.getFile(atPath: "\(mapData.rootNode.name)\(String.pngExtension)")
                if let image = UIImage(data: imageData, scale: 1.0) {
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
    
}

//MARK: - UICollectionView Delegate
extension SearchViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchedFiles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FileCollectionViewCell",for: indexPath) as? FileCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.delegate = self
        cell.configureUI(name: searchedFiles[indexPath.item].rootNode.name, image: searchedFiles[indexPath.item].image, state: searchedFiles[indexPath.item].state)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let noOfCellsInRow = UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let totalSpace = flowLayout.sectionInset.left + flowLayout.sectionInset.right + (flowLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))
        let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(noOfCellsInRow))
        
        return CGSize(width: size, height: size * 2 / 3)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let mapVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "MapViewController") as? MapViewController else {
            return
        }
        
        let state = searchedFiles[indexPath.item].state
        
        mapVC.mapFile = searchedFiles[indexPath.item]
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
                    ErrorReporting.showMessage(title: "Error", message: "This file is private! ❌")
                }
            }
        } else {
            self.navigationController?.pushViewController(mapVC, animated: true)
        }
    }
}

//MARK: - FileCollectionViewCellDelegate
extension SearchViewController: FileCollectionViewCellDelegate {
    func deleteMap(with name: String) {
        do {
            try fileStorage.deleteFile(atPath: "\(name)\(String.pngExtension)")
            try fileStorage.deleteFile(atPath: "\(name)\(String.mmdExtension)")
            reloadData()
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
extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        reloadData()
    }
}
