//
//  ViewController.swift
//  photobooth
//
//  Created by Brandon Yen on 2/2/24.
//

import UIKit
import Foundation



class ViewController: UIViewController {
    
    @IBOutlet weak var ipAddress: UITextField!
    @IBOutlet weak var portNumber: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func connnectToCamera(_ sender: UIButton) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! mainPhotoboothUI
        destinationVC.ipAddress = ipAddress.text!
        destinationVC.portNumber = portNumber.text!
    }
}
