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
    
    var uploadStartTime: Date!
    var totalUploads: Int!
    var completedUploads: Int = 0
    var timer: Timer? // To track the progress and remaining time
    var isUploading: Bool = false
    var timeEstimates: [TimeInterval] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        uploadStatusLabel.text = "Uploading..."
        folderName = pickupName + " " + generateDate()
        Task { // Upload images to dropbox, get url of the folder, and convert url into QR code
            do {
                try await upload()
                let folderURL = try await getFolderShareURL()
                QRCode.layer.magnificationFilter = .nearest
                QRCode.image = try await generateQRCode(from: folderURL)
                isUploading = false
                isCompleted = true
                uploadStatusLabel.text = "Upload Complete! Printing Images."
                stopTimer()
            } catch {
                print("Error: \(error.localizedDescription)")
                uploadStatusLabel.text = "Upload Failed"
            }
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
    
    func generateQRCode(from string: String) async throws -> UIImage? {
        guard let data = string.data(using: .ascii),
              let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        
        qrFilter.setValue(data, forKey: "inputMessage")
        
        guard let qrImage = qrFilter.outputImage else { return nil }
        
        return UIImage(ciImage: qrImage)
    }
    
    func generateDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss"
        return dateFormatter.string(from: Date())
    }
    
    func upload() async throws { // Upload files into folder with the name set to the date/time
        let url = URL(string: "https://content.dropboxapi.com/2/files/upload")!
        
        uploadStartTime = Date()
        totalUploads = compiledPreviewImages.count + compiledImages.count // Total uploads (images and quantity file)
        
        isUploading = true
        Task {
            while isUploading {
                await updateTimeRemaining()
                try? await Task.sleep(nanoseconds: 1_000_000_000) // Sleep for 1 second
            }
        }
        
        // Upload preview images
        try await uploadImages(to: url, images: compiledPreviewImages, folder: folderName)
        
        // Upload compiled images
        try await uploadImages(to: url, images: compiledImages, folder: "Print/\(folderName!)")
        
        // Upload number of images to print
        try await uploadPrintQuantities(to: url)
    }
    
    func uploadImages(to url: URL, images: [UIImage], folder: String) async throws {
        for (index, image) in images.enumerated() {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
            request.setValue("{\"autorename\":false,\"mode\":\"add\",\"mute\":false,\"path\":\"/\(folder)/\(index).png\",\"strict_conflict\":false}", forHTTPHeaderField: "Dropbox-API-Arg")
            
            guard let imageData = image.pngData() else { continue }
            request.httpBody = imageData
            
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let response = response as? HTTPURLResponse, response.statusCode != 200 {
                    print("Error uploading to Dropbox: \(response)")
                }
            } catch {
                print("Upload error: \(error)")
            }
            
            completedUploads += 1
        }
    }
    
    func uploadPrintQuantities(to url: URL) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue("{\"autorename\":false,\"mode\":\"add\",\"mute\":false,\"path\":\"/Print/\(folderName!).txt\",\"strict_conflict\":false}", forHTTPHeaderField: "Dropbox-API-Arg")
        
        let printQuantities = try JSONEncoder().encode(numberToPrintArray)
        request.httpBody = printQuantities
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let response = response as? HTTPURLResponse, response.statusCode != 200 {
                print("Error uploading print quantities to Dropbox: \(response)")
            }
        } catch {
            print("Upload error: \(error)")
        }
    }
    
    func getFolderShareURL() async throws -> String { // Set the sharing mode of the folder to public and return the URL
        var message = FolderShareURLStruct()
        message.path = "/\(folderName!)"
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
        } catch {
            throw error
        }
    }

    func updateTimeRemaining() async {
        guard completedUploads > 0 else { return }
        
        let elapsedTime = Date().timeIntervalSince(uploadStartTime)
        let estimatedTotalTime = elapsedTime / Double(completedUploads) * Double(totalUploads)
        let remainingTime = estimatedTotalTime - elapsedTime
        
        // Add the new estimate to the list
        timeEstimates.append(remainingTime)
        
        // Limit the array size to smooth over the last few updates
        if timeEstimates.count > 10 {
            timeEstimates.removeFirst()
        }
        
        // Calculate the moving average
        let smoothedTime = timeEstimates.reduce(0, +) / Double(timeEstimates.count)
        
        let minutes = Int(smoothedTime) / 60
        let seconds = Int(smoothedTime) % 60
        
        // Update the label on the main thread
        DispatchQueue.main.async {
            self.uploadStatusLabel.text = String(format: "Uploading... Time Remaining: %02d:%02d (%d/%d)", minutes, seconds, self.completedUploads, self.totalUploads)
        }
    }
    
    // Method to stop the timer once the upload is complete
    func stopTimer() {
        if let timer = timer {
            timer.invalidate()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PreviewViewController { // If segue destination is back to preview
            let destinationVC = segue.destination as! PreviewViewController
            destinationVC.imageArray = imageArray // Send the four images taken back to the preview (so compiled images can be redone)
        }
    }
}
