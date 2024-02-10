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
    var currentImagePos = 0
    @IBOutlet var previewImageView: UIImageView!
    @IBOutlet var numberToPrintLabel: UILabel!
    var numberToPrintArray = [0,0,0,0,0,0]
    var areaSizeSketch: [CGRect] = [
        CGRect(x: 174, y: 204, width: 716, height: 1075),
        CGRect(x: 910, y: 204, width: 716, height: 1075),
        CGRect(x: 174, y: 1298.66, width: 716, height: 1075),
        CGRect(x: 910, y: 1298.66, width: 716, height: 1075)
    ]
    var areaSizeKakao: [CGRect] = [
        CGRect(x: 220.75, y: 181.84, width: 671, height: 1006),
        CGRect(x: 909.94, y: 181.84, width: 671, height: 1006),
        CGRect(x: 220.75, y: 1206.72, width: 671, height: 1006),
        CGRect(x: 909.94, y: 1206.72, width: 671, height: 1006)
    ]
    var areaSizeKakao2: [CGRect] = [
        CGRect(x: 220.75, y: 457.84, width: 671, height: 1006),
        CGRect(x: 909.94, y: 457.84, width: 671, height: 1006),
        CGRect(x: 220.75, y: 1482.72, width: 671, height: 1006),
        CGRect(x: 909.94, y: 1482.72, width: 671, height: 1006)
    ]
    var areaSizeKakao3: [CGRect] = [
        CGRect(x: 219.75, y: 181.84, width: 671, height: 1006),
        CGRect(x: 908.94, y: 181.84, width: 671, height: 1006),
        CGRect(x: 219.75, y: 1206.72, width: 671, height: 1006),
        CGRect(x: 908.94, y: 1206.72, width: 671, height: 1006)
    ]
    var areaSizePhotocards: [CGRect] = [
        CGRect(x: 160, y: 366, width: 618, height: 928),
        CGRect(x: 1020, y: 366, width: 618, height: 928),
        CGRect(x: 160, y: 1495, width: 618, height: 928),
        CGRect(x: 1020, y: 1495, width: 618, height: 928)
    ]
    var topImageTemplate: [UIImage] = []
    var areaSizeArray: [[CGRect]] = []
    var compiledImageArray: [UIImage] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        topImageTemplate = [
            UIImage(named: "PhotoboothTemplateSketch.png")!,
            UIImage(named: "PhotoboothTemplateKakao.png")!,
            UIImage(named: "PhotoboothTemplateKakao2.png")!,
            UIImage(named: "PhotoboothTemplateKakao3.png")!,
            UIImage(named: "PhotoboothTemplatePhotocards.png")!,
            UIImage(named: "PhotoboothTemplatePhotocards2.png")!,
        ]
        areaSizeArray = [
            areaSizeSketch,
            areaSizeKakao,
            areaSizeKakao2,
            areaSizeKakao3,
            areaSizePhotocards,
            areaSizePhotocards
        ]
        Task {
            try await compileImages()
        }
    }
    
    @IBAction func backToPhotobooth(_ sender: Any) {
        performSegue(withIdentifier: "cancelPreview", sender: nil)
    }
    
    @IBAction func scrollLeft(_ sender: Any) {
        var newImagePos = (currentImagePos - 1) % 6
        if newImagePos < 0 {
            newImagePos += 6
        }
        UIView.transition(with: self.previewImageView, duration: 0.3, options: .transitionCrossDissolve, animations: {self.previewImageView.image = self.compiledImageArray[newImagePos]}, completion: nil)
        currentImagePos = newImagePos
        numberToPrintLabel.text = String(numberToPrintArray[currentImagePos])
    }
    
    @IBAction func scrollRight(_ sender: Any) {
        let newImagePos = (currentImagePos + 1) % 6
        UIView.transition(with: self.previewImageView, duration: 0.3, options: .transitionCrossDissolve, animations: {self.previewImageView.image = self.compiledImageArray[newImagePos]}, completion: nil)
        currentImagePos = newImagePos
        numberToPrintLabel.text = String(numberToPrintArray[currentImagePos])
    }
    
    @IBAction func addPhoto(_ sender: Any) {
        numberToPrintArray[currentImagePos] += 1
        numberToPrintLabel.text = String(numberToPrintArray[currentImagePos])
    }
    
    @IBAction func removePhoto(_ sender: Any) {
        if numberToPrintArray[currentImagePos] != 0 {
            numberToPrintArray[currentImagePos] -= 1
            numberToPrintLabel.text = String(numberToPrintArray[currentImagePos])
        }
    }
    
    func compileImages() async throws {
        let firstImage = imageArray[0]
        let secondImage = imageArray[1]
        let thirdImage = imageArray[2]
        let fourthImage = imageArray[3]
        let size = CGSize(width: 1800, height: 2700)
        let areaSizeTopImage = CGRect(x: 0, y: 0, width: 1800, height: 2700)
        
        for i in 0...(topImageTemplate.count - 1) {
            UIGraphicsBeginImageContext(size)
            firstImage.draw(in: areaSizeArray[i][0])
            secondImage.draw(in: areaSizeArray[i][1])
            thirdImage.draw(in: areaSizeArray[i][2])
            fourthImage.draw(in: areaSizeArray[i][3])
            topImageTemplate[i].draw(in: areaSizeTopImage, blendMode: .normal, alpha: 1)
            let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            compiledImageArray.append(newImage)
        }
        
        previewImageView.image = compiledImageArray[0]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PhotoboothViewController {
            let destinationVC = segue.destination as! PhotoboothViewController
            destinationVC.ipAddress = ipAddress
            destinationVC.portNumber = portNumber
        }
    }
}
