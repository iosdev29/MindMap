import UIKit
import LocalAuthentication

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContext = URLContexts.first else { return }
        do {
            let importedMap = try FileStorage().copyFile(at: urlContext.url)
            // present imported content
            guard let windowScene = (scene as? UIWindowScene) else { return }
            self.window = UIWindow(windowScene: windowScene)
            
            guard let rootVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(identifier: "HomeViewController") as? HomeViewController else { return }
            let rootNC = UINavigationController(rootViewController: rootVC)
            rootNC.navigationBar.topItem?.title = " "
            self.window?.rootViewController = rootNC
            self.window?.makeKeyAndVisible()
            
            guard let mapVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "MapViewController") as? MapViewController else { return }
            let state = importedMap.state
            mapVC.mapFile = importedMap
            mapVC.state = state
            
            if state == .locked {
                let context = LAContext()
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Protect with Touch ID") { success, error in
                    if success {
                        //show locked file
                        DispatchQueue.main.async {
                            rootNC.pushViewController(mapVC, animated: true)
                        }
                    } else {
                        ErrorReporting.showMessage(title: "Error", message:  "This file is private! ❌")
                    }
                }
            } else {
                rootNC.pushViewController(mapVC, animated: true)
            }
        } catch {
            ErrorReporting.showMessage(title: "Error", message: "Import unsuccessful")
        }
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        self.scene(scene, openURLContexts: connectionOptions.urlContexts)
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        hidePrivacyProtectionWindow()
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        if UserDefaults.standard.bool(forKey: String.isFileLocked) {
            showPrivacyProtectionWindow()
        }
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        hidePrivacyProtectionWindow()
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        if UserDefaults.standard.bool(forKey: String.isFileLocked) {
            showPrivacyProtectionWindow()
        }
    }
    
    // MARK: Privacy Protection
    private var privacyProtectionWindow: UIWindow?
    
    private func showPrivacyProtectionWindow() {
        guard let windowScene = self.window?.windowScene else {
            return
        }
        privacyProtectionWindow = UIWindow(windowScene: windowScene)
        privacyProtectionWindow?.windowLevel = .alert + 1
        privacyProtectionWindow?.makeKeyAndVisible()
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = window!.frame
        blurEffectView.tag = 1221
        privacyProtectionWindow?.addSubview(blurEffectView)
    }
    
    private func hidePrivacyProtectionWindow() {
        privacyProtectionWindow?.isHidden = true
        privacyProtectionWindow = nil
        privacyProtectionWindow?.viewWithTag(1221)?.removeFromSuperview()
    }
}

