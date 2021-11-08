//
//  HomeViewController.swift
//  MindMap
//
//  Created by Alina on 06.11.2021.
//

import UIKit

class HomeViewController: UIViewController {
    // MARK: Stored properties

    // MARK: Outlet properties

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()


    }

    // MARK: Functions
    @IBAction private func addButtonDidTap(_ sender: Any) {
        let alertController = UIAlertController(title: "Add New Map", message: "", preferredStyle: .alert)

        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter main topic"
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { alert -> Void in
            // validating name
            if let mapNameTextField = alertController.textFields?.first, let mapName = mapNameTextField.text, !mapName.isEmpty {
                // presenting Map View Controller
                guard let mapVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "MapViewController") as? MapViewController else {
                    return
                }
                mapVC.rootNodeName = mapName
                self.navigationController?.pushViewController(mapVC, animated: true)
            } else {
                // TODO: show error
                print("MustNotBeEMPTY")
            }            
        })

        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil )

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        alertController.preferredAction = saveAction

        self.present(alertController, animated: true, completion: nil)
    }
    
}
