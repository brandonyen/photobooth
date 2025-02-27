import UIKit

class ViewController: UIViewController {
    // Outlet Variables
    @IBOutlet var ipAddressField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Connect to camera with inputted IP address and port number
    @IBAction func connnectToCamera(_ sender: UIButton) {
        let url = URL(string: "http://" + ipAddressField.text! + "/ccapi")!
        let task = URLSession.shared.dataTask(with: url) {
            data, response, error in
            
            if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    DispatchQueue.main.async {
                        cameraIP = self.ipAddressField.text!
                        self.performSegue(withIdentifier: "didConnectToCamera", sender: nil)
                    }
                }
            }
        }
        task.resume()
    }
}
    
