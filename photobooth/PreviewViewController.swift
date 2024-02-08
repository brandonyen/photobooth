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
    var topImage =  UIImage(named: "CafeNightPhotoboothTemplateColor.png")

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
        let areaSize = CGRect(x: 174, y: 204, width: 716, height: 1075)
        let areaSize2 = CGRect(x: 910, y: 204, width: 716, height: 1075)
        let areaSize3 = CGRect(x: 174, y: 1299, width: 716, height: 1075)
        let areaSize4 = CGRect(x: 910, y: 1299, width: 716, height: 1075)
        firstImage.draw(in: areaSize)
        secondImage.draw(in: areaSize2)
        thirdImage.draw(in: areaSize3)
        fourthImage.draw(in: areaSize4)
        topImage!.draw(in: areaSizeTopImage, blendMode: .normal, alpha: 1)
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        previewImageView.image = newImage
    }
}
