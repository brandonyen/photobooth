//
//  DropboxViewController.swift
//  photobooth
//
//  Created by Brandon Yen on 2/10/24.
//

import Foundation
import UIKit

struct FolderShareURLStruct: Codable {
    var path: String!
    var settings = FolderShareURLSettingsStruct()
}

struct FolderShareURLSettingsStruct: Codable {
    var access: String!
    var allow_download: Bool!
    var audience: String!
    var requested_visibility: String!
}

struct FolderShareURLResponseStruct: Codable {
    var url: String!
}

class DropboxViewController: UIViewController {
    var imageArray: [UIImage] = []
    var compiledImages: [UIImage] = []
    var compiledPreviewImages: [UIImage] = []
    var numberToPrintArray: [Int]!
    var accessToken = "sl.BvanNvbyago-LRdI-8Q3S5-1HTwnDkzAw13yBDNpyNYVkRPsikww0z2XpvipN9CbHEG1PObtQis7kuZYwOwXrBxVIszSgmqjtBFvVrU05KKmRZ_EPTBmTzZKbOC8mwHXv_H526FchQA-5hY"
    var folderName: String!
    @IBOutlet var QRCode: UIImageView!
    @IBOutlet var uploadStatusLabel: UILabel!
    var isCompleted = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        uploadStatusLabel.text = "Uploading..."
        folderName = generateDate()
        Task {
            try await upload()
            let string = try await getFolderShareURL()
            QRCode.layer.magnificationFilter = CALayerContentsFilter.nearest
            QRCode.image = try await generateQRCode(from: string)
            uploadStatusLabel.text = "Upload Complete! Printing Images."
            isCompleted = true
        }
    }
    
    @IBAction func backToPreview(_ sender: Any) {
        performSegue(withIdentifier: "backToPreview", sender: nil)
    }
    
    @IBAction func backToPhotobooth(_ sender: Any) {
        if isCompleted {
            performSegue(withIdentifier: "backToPhotobooth", sender: nil)
        }
    }
    
    func generateQRCode(from string: String) async throws -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
      
        if let QRFilter = CIFilter(name: "CIQRCodeGenerator") {
            QRFilter.setValue(data, forKey: "inputMessage")
            guard let QRImage = QRFilter.outputImage else { return nil }
            return UIImage(ciImage: QRImage)
        }
      
        return nil
    }
    
    func generateDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss"
        let formattedDate = dateFormatter.string(from: Date())
        return formattedDate
    }
    
    func upload() async throws {
        let url = URL(string: "https://content.dropboxapi.com/2/files/upload")!
        for i in 0...5 {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
            request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
            request.setValue("{\"autorename\":false,\"mode\":\"add\",\"mute\":false,\"path\":\"/"
                             + folderName + "/" + String(i) + ".png" +
                             "\",\"strict_conflict\":false}", forHTTPHeaderField: "Dropbox-API-Arg")
            let imageData = compiledPreviewImages[i].pngData()
            request.httpBody = imageData
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let response = response as? HTTPURLResponse {
                    if response.statusCode != 200 {
                        print("error uploading to dropbox")
                        print(response)
                    }
                }
            } catch {
                print(error)
            }
        }
        for i in 0...5 {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
            request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
            request.setValue("{\"autorename\":false,\"mode\":\"add\",\"mute\":false,\"path\":\"/Print/"
                             + folderName + "/" + String(i) + ".png" +
                             "\",\"strict_conflict\":false}", forHTTPHeaderField: "Dropbox-API-Arg")
            let imageData = compiledImages[i].pngData()
            request.httpBody = imageData
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let response = response as? HTTPURLResponse {
                    if response.statusCode != 200 {
                        print("error uploading to dropbox")
                        print(response)
                    }
                }
            } catch {
                print(error)
            }
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue("{\"autorename\":false,\"mode\":\"add\",\"mute\":false,\"path\":\"/Print/"
                         + folderName + "/printInfo.txt" +
                         "\",\"strict_conflict\":false}", forHTTPHeaderField: "Dropbox-API-Arg")
        var str = ""
        for i in 0...5 {
            str.append(String(numberToPrintArray[i]))
        }
        let strData = try! JSONEncoder().encode(Int(str))
        request.httpBody = strData
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200 {
                    print("error uploading to dropbox")
                    print(response)
                }
            }
        } catch {
            print(error)
        }
    }
    
    func getFolderShareURL() async throws -> String {
        var message = FolderShareURLStruct()
        message.path = "/" + folderName
        message.settings.access = "viewer"
        message.settings.allow_download = true
        message.settings.audience = "public"
        message.settings.requested_visibility = "public"
        let data = try! JSONEncoder().encode(message)
        let url = URL(string: "https://api.dropboxapi.com/2/sharing/create_shared_link_with_settings")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let tasks = try JSONDecoder().decode(FolderShareURLResponseStruct.self, from: data)
            return tasks.url
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PreviewViewController {
            let destinationVC = segue.destination as! PreviewViewController
            destinationVC.imageArray = imageArray
        }
    }
}
