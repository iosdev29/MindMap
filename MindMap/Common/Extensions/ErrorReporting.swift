import UIKit

class ErrorReporting {
    
    static func showMessage(title: String, message: String) {
        DispatchQueue.main.async {
            let errorAlert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertController.Style.alert)
            errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            UIApplication.topViewController()?.present(errorAlert, animated: true, completion: nil)
        }
    }
}
