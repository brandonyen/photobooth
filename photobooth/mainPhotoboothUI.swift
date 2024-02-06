//
//  mainPhotoboothUI.swift
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

class mainPhotoboothUI: UIViewController {
    @IBOutlet var liveViewImage: UIImageView!
    @IBOutlet var liveViewImage2: UIImageView!
    @IBOutlet var liveViewImage3: UIImageView!
    @IBOutlet var liveViewImage4: UIImageView!
    @IBOutlet var previewView: UIView!
    @IBOutlet var startButton: UIButton!
    var ipAddress: String!
    var portNumber: String!
    var videoDataOutput: AVCaptureVideoDataOutput!
    var videoDataOutputQueue: DispatchQueue!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var captureDevice: AVCaptureDevice!
    let session = AVCaptureSession()
    var didStartPhotoboothSession: Bool = false
    var liveViewImageArray: [UIImageView] = []
    var countdownTimer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        previewView.contentMode = UIView.ContentMode.scaleAspectFill
        view.addSubview(previewView)
        self.setupAVCapture()
        Task {
            do {
                try await print(getLatestImagePathFromCamera())
            }
            catch {
                print(error)
            }
        }
    }
    
    @IBAction func photoboothEventHandler(_ sender: Any) {
        if !didStartPhotoboothSession {
            didStartPhotoboothSession = true
            startButton.setTitle("Cancel", for: .normal)
            startButton.setTitleColor(.systemRed, for: .normal)
            startPhotoboothSequence()
        }
        else {
            didStartPhotoboothSession = false
            startButton.setTitle("Start", for: .normal)
            startButton.setTitleColor(.systemGreen, for: .normal)
            // pause timer
            // clear timer label text
            // clear uiimageview array
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
            let url = URL(string: folderHTTPPath + "?kind=number")!
            let (data, _) = try await URLSession.shared.data(from: url)
            do {
                let tasks = try JSONDecoder().decode(pageNumberStruct.self, from: data)
                let url = URL(string: folderHTTPPath + "?page=" + String(tasks.pagenumber!))!
                let (data, _) = try await URLSession.shared.data(from: url)
                do {
                    let tasks = try JSONDecoder().decode(urlStruct.self, from: data)
                    returnedValue = tasks.url[tasks.url.count - 1]
                }
                catch {
                    print(error)
                }
            }
            catch {
                print(error)
            }
        }
        catch {
            print(error)
        }
        
        return returnedValue
    }
    
    func startPhotoboothSequence() {
        let url = URL(string: "http://" + ipAddress + ":" + portNumber + "/ccapi/ver100/shooting/liveview/flip")!
        let task = URLSession.shared.dataTask(with: url) {
            data, response, error in
            
            if let data = data {
                DispatchQueue.main.async {
                    self.liveViewImage.image = UIImage(cgImage: (UIImage(data: data)?.cgImage!)!, scale: 1.0, orientation: .left)
                    self.liveViewImage2.image = UIImage(cgImage: (UIImage(data: data)?.cgImage!)!, scale: 1.0, orientation: .left)
                    self.liveViewImage3.image = UIImage(cgImage: (UIImage(data: data)?.cgImage!)!, scale: 1.0, orientation: .left)
                    self.liveViewImage4.image = UIImage(cgImage: (UIImage(data: data)?.cgImage!)!, scale: 1.0, orientation: .left)
                }
            }
        }
        task.resume()
    }
}

extension mainPhotoboothUI: AVCaptureVideoDataOutputSampleBufferDelegate {
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
