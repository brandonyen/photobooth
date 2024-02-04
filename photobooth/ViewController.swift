//
//  ViewController.swift
//  photobooth
//
//  Created by Brandon Yen on 2/2/24.
//

import UIKit
import Foundation

struct Wrapper: Codable {
    let storagelist: [storagelist]
}

struct storagelist: Codable {
    let name: String
    let url: String
    let accesscapability: String
    let maxsize: Int
    let spacesize: Int
    let contentsnumber: Int
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBOutlet weak var ipAddress: UITextField!
    @IBOutlet weak var portNumber: UITextField!
    
    @IBAction func connnectToCamera(_ sender: UIButton) {
        let url = URL(string: "http://" + ipAddress.text! + ":" + portNumber.text! + "/ccapi/ver100/devicestatus/storage")!
        let task = URLSession.shared.dataTask(with: url) {
            data, response, error in
            
            let decoder = JSONDecoder()
            
            if let data = data {
                do {
                    let tasks = try decoder.decode(Wrapper.self, from: data)
                    print(tasks.storagelist[0].url)
                } catch {
                    print(error)
                }
            }
        }
        task.resume()
    }
}
