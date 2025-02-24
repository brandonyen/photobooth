//
//  PhotoboothViewController.swift
//  photobooth
//
//  Created by Brandon Yen on 2/4/24.
//

import UIKit

class PhotoboothViewController: UIViewController {
    // Outlet Variables
    @IBOutlet var startButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var liveViewImage: UIImageView!
    @IBOutlet var liveViewImage2: UIImageView!
    @IBOutlet var liveViewImage3: UIImageView!
    @IBOutlet var liveViewImage4: UIImageView!
    @IBOutlet var previewView: UIImageView!
    @IBOutlet var countdownLabel: UILabel!
    
    // Variables
    var liveViewImageArray: [UIImageView]!
    var currentTask: Task<(), Never>!
    var photoboothSessionInProgress: Bool = false
    var finishedPhotoboothSession: Bool = false
    private var isStreaming = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        previewView.contentMode = UIView.ContentMode.scaleAspectFit
        view.addSubview(previewView) // Add the camera live view to subview
        view.addSubview(countdownLabel) // Add countdown label to subview
        self.startLiveView() // Start camera live view
        liveViewImageArray = [liveViewImage, liveViewImage2, liveViewImage3, liveViewImage4] // Add the four (empty) UIImages to array
    }
    
    private func startLiveView() {
        guard let url = URL(string: "http://\(cameraIP)/ccapi/ver100/shooting/liveview") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["liveviewsize": "small", "cameradisplay": "on"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Failed to start live view:", error.localizedDescription)
                return
            }
            print("Live view started successfully:", response ?? "No response")
            self.isStreaming = true
            self.fetchFrame()
        }.resume()
    }

    private func fetchFrame() {
        guard isStreaming else { return }

        let timestamp = Int(Date().timeIntervalSince1970 * 1000) // Prevent caching
        let urlString = "http://\(cameraIP)/ccapi/ver100/shooting/liveview/flip?\(timestamp)"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                print("Error fetching frame:", error?.localizedDescription ?? "Unknown error")
                return
            }

            DispatchQueue.main.async {
                self.previewView.image = image
                
                self.previewView.transform = CGAffineTransform(rotationAngle: -.pi / 2)

                // 🔹 Change refresh rate (adjust delay in milliseconds)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.025) {
                    self.fetchFrame()
                }
            }
        }.resume()
    }
    
    @IBAction func photoboothEventHandler(_ sender: Any) { // Start button for photobooth
        if !photoboothSessionInProgress && !finishedPhotoboothSession { // If photobooth session is not in progress and photobooth session is not finished
            photoboothSessionInProgress = true
            for i in 0...3 { // Clear all preview images
                liveViewImageArray[i].image = nil
            }
            startButton.tintColor = UIColor.systemGray
            cancelButton.tintColor = UIColor.systemRed
            currentTask = Task { // Set current task so task can be cancelled by other functions
                do {
                    try await startPhotoboothSequence() // Start photobooth session
                }
                catch {
                    print(error)
                }
            }
        }
        else if !photoboothSessionInProgress && finishedPhotoboothSession { // If photobooth session is finished (user pressed retake button)
            photoboothSessionInProgress = true
            finishedPhotoboothSession = false
            nextButton.tintColor = UIColor.systemGray
            for i in 0...3 {
                liveViewImageArray[i].image = nil // Clear all preview images
            }
            startButton.setTitle("Start", for: .normal)
            startButton.tintColor = UIColor.systemGray
            cancelButton.tintColor = UIColor.systemRed
            currentTask = Task { // Set current task so task can be cancelled by other functions
                do {
                    try await startPhotoboothSequence() // Start photobooth session
                }
                catch {
                    print(error)
                }
            }
        }
    }
    
    @IBAction func cancelEventHandler(_ sender: Any) { // Cancel button for photobooth
            if photoboothSessionInProgress { // If photobooth is running
                currentTask.cancel() // Cancel photobooth task
                photoboothSessionInProgress = false
                startButton.tintColor = UIColor.systemGreen
                cancelButton.tintColor = UIColor.systemGray
                countdownLabel.text = ""
            }
    }

    @IBAction func nextEventHandler(_ sender: Any) {
        if finishedPhotoboothSession { // If photobooth session is finished (all four pictures taken)
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "didFinishPhotoboothSession", sender: nil) // Segue to preview viewcontroller
            }
        }
    }
    
    func getLatestImagePathFromCamera() async throws -> String { // Get the url of the latest image stored on the camera
        var folderHTTPPath: String!
        var returnedValue: String!
        let url = URL(string: "http://\(cameraIP)/ccapi/ver100/contents/sd")!
        let (data, _) = try await URLSession.shared.data(from: url)
            do {
                let tasks = try JSONDecoder().decode(urlStruct.self, from: data)
                folderHTTPPath = tasks.url[tasks.url.count - 1]
                let url = URL(string: folderHTTPPath + "?kind=number")! // Get the last page of the list of images
                 let (data, _) = try await URLSession.shared.data(from: url)
                 do {
                     let tasks = try JSONDecoder().decode(pageNumberStruct.self, from: data)
                     let url = URL(string: folderHTTPPath + "?page=" + String(tasks.pagenumber!))! // Get last image from the last page
                     let (data, _) = try await URLSession.shared.data(from: url)
                     do {
                         let tasks = try JSONDecoder().decode(urlStruct.self, from: data)
                         returnedValue = tasks.url[tasks.url.count - 1] // set return value to the url of the last image
                     } catch {
                         print(error)
                     }
                 } catch {
                     print(error)
                 }
            } catch {
                print(error)
            }
        return returnedValue
    }
    
    func takePicture() async throws { // Take picture on camera
        let url = URL(string: "http://\(cameraIP)/ccapi/ver100/shooting/control/shutterbutton")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let message = Message(af:true)
        let data = try! JSONEncoder().encode(message)
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200 {
                    let tasks = try JSONDecoder().decode(responseMessage.self, from: data)
                    if tasks.message! == "Out of focus" {
                        try await takePicture()
                    } else {
                        countdownLabel.text = "Error"
                        photoboothSessionInProgress = false
                        startButton.tintColor = UIColor.systemGreen
                        cancelButton.tintColor = UIColor.systemGray
                        currentTask.cancel()
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    
    func startPhotoboothSequence() async throws { // Start photobooth function
        for i in 0...3 { // Take four pictures
            countdownLabel.font = countdownLabel.font.withSize(90)
            for i in 1...5 { // Count down from 5
                countdownLabel.text = String(abs(i-6))
                try await Task.sleep(nanoseconds: UInt64(1000000000))
            }
            countdownLabel.font = countdownLabel.font.withSize(50)
            countdownLabel.text = "Taking photo " + String(i+1) + "/4..."
            try await takePicture()
            countdownLabel.text = "Please wait..."
            let cameraDelay = 1
            try await Task.sleep(nanoseconds: UInt64(1000000000 * cameraDelay))
            let url = URL(string: try await getLatestImagePathFromCamera() + "?kind=display")!
            let (data, _) = try await URLSession.shared.data(from: url)
            liveViewImageArray[i].image = UIImage(cgImage: (UIImage(data: data)?.cgImage!)!, scale: 1.0, orientation: .left) // set preview image to the image taken
            self.startLiveView()
        }
        countdownLabel.text = ""
        photoboothSessionInProgress = false
        finishedPhotoboothSession = true
        startButton.setTitle("Retake", for: .normal)
        startButton.tintColor = UIColor.systemGreen
        cancelButton.tintColor = UIColor.systemGray
        nextButton.tintColor = UIColor.systemBlue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PreviewViewController { // If segue destination is preview view controller
            let destinationVC = segue.destination as! PreviewViewController
            let imageArray: [UIImage] = [liveViewImageArray[0].image!,liveViewImageArray[1].image!,liveViewImageArray[2].image!,liveViewImageArray[3].image!]
            destinationVC.imageArray = imageArray // Send the four images to the view controller
        }
    }
    
    deinit {
        isStreaming = false
    }
}
