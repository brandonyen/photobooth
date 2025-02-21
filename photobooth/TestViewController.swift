import UIKit

class TestViewController: UIViewController {
    private let imageView = UIImageView()
    private let cameraIP = "192.168.1.241:8080" // Replace with your actual IP
    private var isStreaming = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startLiveView()
    }

    private func setupUI() {
        view.backgroundColor = .black
        imageView.contentMode = .scaleAspectFit
        imageView.frame = view.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(imageView)
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
                self.imageView.image = image

                // 🔹 Change refresh rate (adjust delay in milliseconds)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.025) {
                    self.fetchFrame()
                }
            }
        }.resume()
    }


    deinit {
        isStreaming = false
    }
}
