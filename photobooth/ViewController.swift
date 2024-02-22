//
//  ViewController.swift
//  photobooth
//
//  Created by Brandon Yen on 2/2/24.
//

import UIKit
import Foundation

class ViewController: UIViewController {
    // Outlet Variables
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet var ipAddressField: UITextField!
    @IBOutlet var portNumberField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Connect to camera with inputted IP address and port number
    @IBAction func connnectToCamera(_ sender: UIButton) {
        let url = URL(string: "http://" + ipAddressField.text! + ":" + portNumberField.text! + "/ccapi")!
        let task = URLSession.shared.dataTask(with: url) {
            data, response, error in
            
            if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 { // If HTTP response from camera is 200 (no errors)
                    DispatchQueue.main.async {
                        ipAddress = self.ipAddressField.text! // Set global variables to inputted variables
                        portNumber = self.portNumberField.text!
                        self.performSegue(withIdentifier: "didConnectToCamera", sender: nil) // Move to photobooth viewcontroller
                    }
                }
            }
        }
        task.resume()
    }
}
