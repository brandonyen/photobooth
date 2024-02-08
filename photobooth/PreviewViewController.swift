//
//  PreviewViewController.swift
//  photobooth
//
//  Created by Brandon Yen on 2/6/24.
//

import UIKit
import Foundation

class PreviewViewController: UIViewController {
    var ipAddress: String!
    var portNumber: String!
    var imageArray: [UIImage]!
    @IBOutlet var previewImageView: UIImageView!
    var topImage =  UIImage(named: "PhotoboothTemplatePhotocards.png")
    var areaSizeSketch: [CGRect] = [CGRect(x: 174, y: 204, width: 716, height: 1075), CGRect(x: 174, y: 204, width: 716, height: 1075), CGRect(x: 174, y: 204, width: 716, height: 1075), CGRect(x: 174, y: 204, width: 716, height: 1075)]
    var areaSizeWatercolor: [CGRect] = [CGRect(x: 173, y: 265, width: 716, height: 1074), CGRect(x: 909, y: 265, width: 716, height: 1074), CGRect(x: 173, y: 1360, width: 716, height: 1074), CGRect(x: 909, y: 1360, width: 716, height: 1074)]
    var areaSizeKakao: [CGRect] = [CGRect(x: 220.75, y: 181.84, width: 671, height: 1006), CGRect(x: 909.94, y: 181.84, width: 671, height: 1006), CGRect(x: 220.75, y: 1206.72, width: 671, height: 1006), CGRect(x: 909.94, y: 1206.72, width: 671, height: 1006)]
    var areaSizePhotocards: [CGRect] = [CGRect(x: 160, y: 366, width: 618, height: 928), CGRect(x: 1020, y: 366, width: 618, height: 928), CGRect(x: 160, y: 1495, width: 618, height: 928), CGRect(x: 1020, y: 1495, width: 618, height: 928)]

    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            try await compileImage()
        }
    }
    
    @IBAction func backToPhotobooth(_ sender: Any) {
        performSegue(withIdentifier: "cancelPreview", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PhotoboothViewController {
            let destinationVC = segue.destination as! PhotoboothViewController
            destinationVC.ipAddress = ipAddress
            destinationVC.portNumber = portNumber
        }
    }
    
    func compileImage() async throws {
        let firstImage = imageArray[0]
        let secondImage = imageArray[1]
        let thirdImage = imageArray[2]
        let fourthImage = imageArray[3]
        let size = CGSize(width: 1800, height: 2700)
        UIGraphicsBeginImageContext(size)
        let areaSizeTopImage = CGRect(x: 0, y: 0, width: 1800, height: 2700)
        firstImage.draw(in: areaSizePhotocards[0])
        secondImage.draw(in: areaSizePhotocards[1])
        thirdImage.draw(in: areaSizePhotocards[2])
        fourthImage.draw(in: areaSizePhotocards[3])
        topImage!.draw(in: areaSizeTopImage, blendMode: .normal, alpha: 1)
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        previewImageView.image = newImage
    }
}
