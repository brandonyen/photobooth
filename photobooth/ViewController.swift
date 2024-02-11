//
//  ViewController.swift
//  photobooth
//
//  Created by Brandon Yen on 2/2/24.
//

import UIKit
import Foundation

var ipAddress = ""
var portNumber = ""

class ViewController: UIViewController {
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet var ipAddressField: UITextField!
    @IBOutlet var portNumberField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func connnectToCamera(_ sender: UIButton) {
        let url = URL(string: "http://" + ipAddressField.text! + ":" + portNumberField.text! + "/ccapi")!
        let task = URLSession.shared.dataTask(with: url) {
            data, response, error in
            
            if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    DispatchQueue.main.async {
                        ipAddress = self.ipAddressField.text!
                        portNumber = self.portNumberField.text!
                        self.performSegue(withIdentifier: "didConnectToCamera", sender: nil)
                    }
                }
            }
        }
        task.resume()
    }
}
