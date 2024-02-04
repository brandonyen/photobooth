//
//  mainPhotoboothUI.swift
//  photobooth
//
//  Created by Brandon Yen on 2/4/24.
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

class mainPhotoboothUI: UIViewController {
    
    var ipAddress: String!
    var portNumber: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = URL(string: "http://" + ipAddress + ":" + portNumber + "/ccapi/ver100/devicestatus/storage")!
        let task = URLSession.shared.dataTask(with: url) {
            data, response, error in
            
            if let data = data {
                do {
                    let tasks = try JSONDecoder().decode(Wrapper.self, from: data)
                    print(tasks.storagelist[0].url)
                } catch {
                    print(error)
                }
            }
        }
        task.resume()
    }
}
