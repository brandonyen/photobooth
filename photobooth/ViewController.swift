//
//  ViewController.swift
//  photobooth
//
//  Created by Brandon Yen on 2/2/24.
//

import UIKit
import Foundation

class ViewController: UIViewController {
    
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var ipAddress: UITextField!
    @IBOutlet weak var portNumber: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func connnectToCamera(_ sender: UIButton) {
        let url = URL(string: "http://" + ipAddress.text! + ":" + portNumber.text! + "/ccapi")!
        let task = URLSession.shared.dataTask(with: url) {
            data, response, error in
            
            if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "didConnectToCamera", sender: nil)
                    }
                }
            }
        }
        task.resume()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! PhotoboothViewController
        destinationVC.ipAddress = ipAddress.text!
        destinationVC.portNumber = portNumber.text!
    }
}
