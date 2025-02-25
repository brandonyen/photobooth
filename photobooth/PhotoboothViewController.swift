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
    var photoboothSessionInProgress = false
    var finishedPhotoboothSession = false
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
                self.fetchFrame()
                return
            }
            
            DispatchQueue.main.async {
                self.previewView.image = image
                
                self.previewView.transform = CGAffineTransform(rotationAngle: -.pi / 2)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.fetchFrame()
                }
            }
        }.resume()
    }
    
    @IBAction func photoboothEventHandler(_ sender: Any) {
        if !photoboothSessionInProgress {
            if finishedPhotoboothSession {
                resetPhotoboothSession()
            } else {
                startPhotoboothSession()
            }
        }
    }
    
    private func startPhotoboothSession() {
        photoboothSessionInProgress = true
        clearPreviewImages()
        startButton.tintColor = .systemGray
        cancelButton.tintColor = .systemRed
        
        currentTask = Task {
            do {
                try await startPhotoboothSequence()
            } catch {
                print(error)
            }
        }
    }

    private func resetPhotoboothSession() {
        photoboothSessionInProgress = true
        finishedPhotoboothSession = false
        nextButton.tintColor = .systemGray
        clearPreviewImages()
        startButton.setTitle("Start", for: .normal)
        startButton.tintColor = .systemGray
        cancelButton.tintColor = .systemRed
        
        currentTask = Task {
            do {
                try await startPhotoboothSequence()
            } catch {
                print(error)
            }
        }
    }
    
    private func clearPreviewImages() {
        liveViewImageArray.forEach { $0.image = nil }
    }

    @IBAction func cancelEventHandler(_ sender: Any) {
        if photoboothSessionInProgress {
            currentTask.cancel()
            photoboothSessionInProgress = false
            resetUIAfterCancel()
        }
    }

    private func resetUIAfterCancel() {
        startButton.tintColor = .systemGreen
        cancelButton.tintColor = .systemGray
        countdownLabel.text = ""
    }

    @IBAction func nextEventHandler(_ sender: Any) {
        if finishedPhotoboothSession {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "didFinishPhotoboothSession", sender: nil)
            }
        }
    }

    func getLatestImagePathFromCamera() async throws -> String {
        let url = URL(string: "http://\(cameraIP)/ccapi/ver100/contents/sd")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let tasks = try JSONDecoder().decode(urlStruct.self, from: data)
        let folderHTTPPath = tasks.url.last!
        
        let pageURL = URL(string: folderHTTPPath + "?kind=number")!
        let (pageData, _) = try await URLSession.shared.data(from: pageURL)
        let pageInfo = try JSONDecoder().decode(pageNumberStruct.self, from: pageData)
        
        let lastPageURL = URL(string: folderHTTPPath + "?page=\(pageInfo.pagenumber!)")!
        let (lastPageData, _) = try await URLSession.shared.data(from: lastPageURL)
        let lastImageInfo = try JSONDecoder().decode(urlStruct.self, from: lastPageData)
        
        return lastImageInfo.url.last!
    }

    func takePicture() async throws {
        let url = URL(string: "http://\(cameraIP)/ccapi/ver100/shooting/control/shutterbutton")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let message = Message(af: true)
        let data = try JSONEncoder().encode(message)
        request.httpBody = data
        
        let (data2, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse, response.statusCode != 200 {
            let responseMessage = try JSONDecoder().decode(responseMessage.self, from: data2)
            if responseMessage.message == "Out of focus" {
                try await takePicture()
            } else {
                handleError()
            }
        }
    }

    private func handleError() {
        countdownLabel.text = "Error"
        photoboothSessionInProgress = false
        resetUIAfterCancel()
        currentTask.cancel()
    }

    func startPhotoboothSequence() async throws {
        for i in 0...3 {
            try await countdownAndTakePicture(for: i)
        }
        
        countdownLabel.text = ""
        photoboothSessionInProgress = false
        finishedPhotoboothSession = true
        updateUIForFinishedSession()
    }

    private func countdownAndTakePicture(for index: Int) async throws {
        countdownLabel.font = countdownLabel.font.withSize(90)
        for i in 1...5 {
            countdownLabel.text = String(abs(i - 6))
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        countdownLabel.font = countdownLabel.font.withSize(50)
        countdownLabel.text = "Taking photo \(index + 1)/4..."
        try await takePicture()
        
        countdownLabel.text = "Please wait..."
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let imageURL = try await getLatestImagePathFromCamera() + "?kind=display"
        let (data, _) = try await URLSession.shared.data(from: URL(string: imageURL)!)
        
        liveViewImageArray[index].image = UIImage(cgImage: (UIImage(data: data)?.cgImage!)!, scale: 1.0, orientation: .left)
        startLiveView()
    }

    private func updateUIForFinishedSession() {
        startButton.setTitle("Retake", for: .normal)
        startButton.tintColor = .systemGreen
        cancelButton.tintColor = .systemGray
        nextButton.tintColor = .systemBlue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? PreviewViewController {
            let imageArray = liveViewImageArray.compactMap { $0.image }
            destinationVC.imageArray = imageArray
        }
    }

    deinit {
        isStreaming = false
    }
}
