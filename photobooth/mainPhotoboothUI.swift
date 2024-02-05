//
//  mainPhotoboothUI.swift
//  photobooth
//
//  Created by Brandon Yen on 2/4/24.
//

import UIKit
import Foundation
import AVFoundation

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
    @IBOutlet var previewView: UIView!
    var ipAddress: String!
    var portNumber: String!
    var videoDataOutput: AVCaptureVideoDataOutput!
    var videoDataOutputQueue: DispatchQueue!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var captureDevice: AVCaptureDevice!
    let session = AVCaptureSession()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        previewView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
        previewView.contentMode = UIView.ContentMode.scaleAspectFill
        view.addSubview(previewView)
        self.setupAVCapture()
    }
    
    func startPhotoboothSequence() {
        let url = URL(string: "http://" + ipAddress + ":" + portNumber + "/ccapi/ver100/shooting/liveview/flip")!
        let task = URLSession.shared.dataTask(with: url) {
            data, response, error in
            
            if let data = data {
                DispatchQueue.main.async {
//                    self.liveViewImage.image = UIImage(data: data)
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
