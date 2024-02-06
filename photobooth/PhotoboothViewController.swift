//
//  PhotoboothViewController.swift
//  photobooth
//
//  Created by Brandon Yen on 2/4/24.
//

import UIKit
import Foundation
import AVFoundation

struct urlStruct: Codable {
    let url: [String]
}

struct pageNumberStruct: Codable {
    let contentsnumber: Int!
    let pagenumber: Int!
}

struct Message: Encodable {
    let af: Bool
}

class PhotoboothViewController: UIViewController {
    @IBOutlet var startButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var liveViewImage: UIImageView!
    @IBOutlet var liveViewImage2: UIImageView!
    @IBOutlet var liveViewImage3: UIImageView!
    @IBOutlet var liveViewImage4: UIImageView!
    @IBOutlet var previewView: UIView!
    @IBOutlet var countdownLabel: UILabel!
    var ipAddress: String!
    var portNumber: String!
    var videoDataOutput: AVCaptureVideoDataOutput!
    var videoDataOutputQueue: DispatchQueue!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var captureDevice: AVCaptureDevice!
    let session = AVCaptureSession()
    var liveViewImageArray: [UIImageView]!
    var countdownTimer: Timer!
    var currentTask: Task<(), Never>!
    var photoboothSessionInProgress: Bool = false
    var finishedPhotoboothSession: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        previewView.contentMode = UIView.ContentMode.scaleAspectFill
        view.addSubview(previewView)
        view.addSubview(countdownLabel)
        self.setupAVCapture()
        liveViewImageArray = [liveViewImage, liveViewImage2, liveViewImage3, liveViewImage4]
    }
    
    @IBAction func photoboothEventHandler(_ sender: Any) {
        if !photoboothSessionInProgress && !finishedPhotoboothSession {
            photoboothSessionInProgress = true
            for i in 0...3 {
                liveViewImageArray[i].image = nil
            }
            startButton.tintColor = UIColor.systemGray
            cancelButton.tintColor = UIColor.systemRed
            currentTask = Task {
                do {
                    try await startPhotoboothSequence()
                }
                catch {
                    print(error)
                }
            }
        }
        else if !photoboothSessionInProgress && finishedPhotoboothSession {
            photoboothSessionInProgress = true
            finishedPhotoboothSession = false
            nextButton.tintColor = UIColor.systemGray
            for i in 0...3 {
                liveViewImageArray[i].image = nil
            }
            startButton.setTitle("Start", for: .normal)
            startButton.tintColor = UIColor.systemGray
            cancelButton.tintColor = UIColor.systemRed
            currentTask = Task {
                do {
                    try await startPhotoboothSequence()
                }
                catch {
                    print(error)
                }
            }
        } else {
            
        }
    }
    
    @IBAction func cancelEventHandler(_ sender: Any) {
            if photoboothSessionInProgress {
                currentTask.cancel()
                photoboothSessionInProgress = false
                startButton.tintColor = UIColor.systemGreen
                cancelButton.tintColor = UIColor.systemGray
                countdownLabel.text = ""
            } else {
                
            }
    }

    @IBAction func nextEventHandler(_ sender: Any) {
        if finishedPhotoboothSession {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "didFinishPhotoboothSession", sender: nil)
            }
        } else {
            
        }
    }
    
    func getLatestImagePathFromCamera() async throws -> String {
        var folderHTTPPath: String!
        var returnedValue: String!
        let url = URL(string: "http://" + ipAddress + ":" + portNumber + "/ccapi/ver100/contents/sd")!
        let (data, _) = try await URLSession.shared.data(from: url)
            do {
                let tasks = try JSONDecoder().decode(urlStruct.self, from: data)
                folderHTTPPath = tasks.url[tasks.url.count - 1]
                let url2 = URL(string: folderHTTPPath + "?kind=number")!
                 let (data2, _) = try await URLSession.shared.data(from: url2)
                 do {
                     let tasks2 = try JSONDecoder().decode(pageNumberStruct.self, from: data2)
                     let url3 = URL(string: folderHTTPPath + "?page=" + String(tasks2.pagenumber!))!
                     let (data3, _) = try await URLSession.shared.data(from: url3)
                     do {
                         let tasks3 = try JSONDecoder().decode(urlStruct.self, from: data3)
                         returnedValue = tasks3.url[tasks3.url.count - 1]
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
    
    func startPhotoboothSequence() async throws {
        for i in 0...3 {
            countdownLabel.font = countdownLabel.font.withSize(90)
            for i in 1...5 {
                countdownLabel.text = String(abs(i-6))
                try await Task.sleep(nanoseconds: UInt64(1000000000))
            }
            countdownLabel.font = countdownLabel.font.withSize(50)
            countdownLabel.text = "Taking photo " + String(i+1) + "/4..."
            try await takePicture()
            let cameraDelay = 1
            try await Task.sleep(nanoseconds: UInt64(1000000000 * cameraDelay))
            let url = URL(string: try await getLatestImagePathFromCamera() + "?kind=display")!
            let (data, _) = try await URLSession.shared.data(from: url)
            liveViewImageArray[i].image = UIImage(cgImage: (UIImage(data: data)?.cgImage!)!, scale: 1.0, orientation: .left)
        }
        countdownLabel.text = ""
        photoboothSessionInProgress = false
        finishedPhotoboothSession = true
        startButton.setTitle("Retake", for: .normal)
        startButton.tintColor = UIColor.systemGreen
        cancelButton.tintColor = UIColor.systemGray
        nextButton.tintColor = UIColor.systemBlue
    }

    func takePicture() async throws {
        let url = URL(string: "http://" + ipAddress + ":" + portNumber + "/ccapi/ver100/shooting/control/shutterbutton")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let message = Message(af:true)
        let data = try! JSONEncoder().encode(message)
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let (_, _) = try await URLSession.shared.data(for: request)
        } catch {
            print(error)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PreviewViewController {
            let destinationVC = segue.destination as! PreviewViewController
            destinationVC.ipAddress = ipAddress
            destinationVC.portNumber = portNumber
            let imageArray: [UIImage] = [liveViewImageArray[0].image!,liveViewImageArray[1].image!,liveViewImageArray[2].image!,liveViewImageArray[3].image!]
            destinationVC.imageArray = imageArray
        }
    }
}

extension PhotoboothViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func setupAVCapture() {
        session.sessionPreset = AVCaptureSession.Preset.vga640x480
        guard let device = AVCaptureDevice
            .default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: .video, position: AVCaptureDevice.Position.front) else {
            return
        }
        captureDevice = device
        beginSession()
    }
    
    func beginSession() {
        var deviceInput: AVCaptureDeviceInput!
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            guard deviceInput != nil else {
                print("Error: Can't get deviceInput")
                return
            }

            if self.session.canAddInput(deviceInput){
                self.session.addInput(deviceInput)
            }

            videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.alwaysDiscardsLateVideoFrames=true
            videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
            videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue)

            if session.canAddOutput(self.videoDataOutput){
                session.addOutput(self.videoDataOutput)
            }
                    
            videoDataOutput.connection(with: .video)?.isEnabled = true

            previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect

            let rootLayer :CALayer = self.previewView.layer
            rootLayer.masksToBounds=true
            previewLayer.frame = rootLayer.bounds
            rootLayer.addSublayer(self.previewLayer)
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        } catch let error as NSError {
            deviceInput = nil
            print("error: \(error.localizedDescription)")
        }
    }
}
