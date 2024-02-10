//
//  DropboxViewController.swift
//  photobooth
//
//  Created by Brandon Yen on 2/10/24.
//

import Foundation
import UIKit

class DropboxViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            try await test()
        }
    }
    
    func test() async throws {
        let url = URL(string: "https://content.dropboxapi.com/2/files/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let imageData = UIImage(named: "PhotoboothTemplateKakao.png")?.pngData()
        request.httpBody = imageData
        request.setValue("Bearer sl.BvVzYhNgCeKfIrooXPHP2esPykK0G0knxVGLPwpIvIemkqrqC1ggNFsubO4lGEuKP3N1QyPmey0L6F9T1p8uuXMkBXL0EToUJ0FAnbg9kDiF8AphjNHnTmTSB1p1NZNLiAgcxS9VymUt", forHTTPHeaderField: "Authorization")
        request.setValue("{\"autorename\":false,\"mode\":\"add\",\"mute\":false,\"path\":\"/Homework/math/Matrices.png\",\"strict_conflict\":false}", forHTTPHeaderField: "Dropbox-API-Arg")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200 {
                    let tasks = try JSONDecoder().decode(responseMessage.self, from: data)
                    print(tasks)
                }
            }
        } catch {
            print(error)
        }
    }
}
