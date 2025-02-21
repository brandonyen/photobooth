//
//  DropboxViewController.swift
//  photobooth
//
//  Created by Brandon Yen on 2/10/24.
//

import Foundation
import UIKit

class DropboxViewController: UIViewController {
    // Outlet variables
    @IBOutlet var QRCode: UIImageView!
    @IBOutlet var uploadStatusLabel: UILabel!
    
    // Variables
    var pickupName: String!
    var imageArray: [UIImage] = []
    var compiledImages: [UIImage] = []
    var compiledPreviewImages: [UIImage] = []
    var numberToPrintArray: [Int]!
    var accessToken = config.api_key
    var folderName: String!
    var isCompleted = false
    
    var imagePrintQueue: [UIImage] = [] // Would use if there was only one printer
    
    override func viewDidLoad() {
        super.viewDidLoad()

        uploadStatusLabel.text = "Uploading..."
        folderName = pickupName + " " + generateDate()
        Task { // Upload images to dropbox, get url of the folder, and convert url into QR code
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
        if isCompleted { // Can only return back to the photobooth once the images are uploaded to dropbox
            performSegue(withIdentifier: "backToPhotobooth", sender: nil)
        }
    }
    
    func generateQRCode(from string: String) async throws -> UIImage? { // Generate QR code given a string
        let data = string.data(using: String.Encoding.ascii)
      
        if let QRFilter = CIFilter(name: "CIQRCodeGenerator") {
            QRFilter.setValue(data, forKey: "inputMessage")
            guard let QRImage = QRFilter.outputImage else { return nil }
            return UIImage(ciImage: QRImage)
        }
      
        return nil
    }
    
    func generateDate() -> String { // Generate the current date and time to name the folder
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss"
        let formattedDate = dateFormatter.string(from: Date())
        return formattedDate
    }
    
    func upload() async throws { // Upload files into folder with the name set to the date/time
        let url = URL(string: "https://content.dropboxapi.com/2/files/upload")!
        for i in 0...5 { // upload each compiled image
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
        for i in 0...5 { // upload each compiled image
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
        var request = URLRequest(url: url) // Upload the amount of each compiled image to print (to verify if the amount actually printed is correct)
                request.httpMethod = "POST"
                request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
                request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
                request.setValue("{\"autorename\":false,\"mode\":\"add\",\"mute\":false,\"path\":\"/Print/" + folderName + ".txt" +
                                 "\",\"strict_conflict\":false}", forHTTPHeaderField: "Dropbox-API-Arg")
                var str = ""
                for i in 0...5 {
                    str.append(String(numberToPrintArray[i]))
                }
                let strData = try! JSONEncoder().encode(str)
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
    
    func getFolderShareURL() async throws -> String { // Set the sharing mode of the folder to public and return the URL
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
    
    /*
    func addImagesToQueue() { // Add images to print queue
        for i in 0...5 {
            for _ in 0..<numberToPrintArray[i] {
                imagePrintQueue.append(compiledImages[i])
            }
        }
    }
    
    func printImages(pos: Int, imageQueue: [UIImage]) { // Print out images
        let printCompletionHandler: UIPrintInteractionController.CompletionHandler = { (controller, success, error) -> Void in
            if success && pos + 1 < imageQueue.count { // If printing was successful and queue is not empty
                self.printImages(pos: pos+1, imageQueue: imageQueue) // print next image in queue
                    }
                }
        
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .photo
        printInfo.jobName = "Printing"
        printController.printInfo = printInfo
        printController.printingItem = imageQueue[pos]
        
        printController.print(to: currentPrinter, completionHandler: printCompletionHandler)
    }
    */
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PreviewViewController { // If segue destination is back to preview
            let destinationVC = segue.destination as! PreviewViewController
            destinationVC.imageArray = imageArray // Send the four images taken back to the preview (so compiled images can be redone)
        }
    }
}
