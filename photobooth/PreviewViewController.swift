//
//  PreviewViewController.swift
//  photobooth
//
//  Created by Brandon Yen on 2/6/24.
//

import UIKit
import Foundation

class PreviewViewController: UIViewController {
    // Outlet variables
    @IBOutlet var previewImageView: UIImageView!
    @IBOutlet var numberToPrintLabel: UILabel!
    
    // Variables
    var imageArray: [UIImage]!
    var currentImagePos = 0
    var numberToPrintArray = [0,0,0,0,0,0]
    var topImageTemplate: [UIImage] = []
    var topImageTemplatePreview: [UIImage] = []
    var areaSizes: [[CGRect]] = []
    var areaSizesPreview: [[CGRect]] = []
    var compiledImages: [UIImage] = []
    var compiledPreviewImages: [UIImage] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        topImageTemplate = [ // Overlay template array (for actual print)
            UIImage(named: "PhotoboothTemplateSketch.png")!,
            UIImage(named: "PhotoboothTemplateKakao.png")!,
            UIImage(named: "PhotoboothTemplateKakao2.png")!,
            UIImage(named: "PhotoboothTemplateKakao3.png")!,
            UIImage(named: "PhotoboothTemplatePhotocards.png")!,
            UIImage(named: "PhotoboothTemplatePhotocards2.png")!,
        ]
        topImageTemplatePreview = [ // Overlay template array (for previewing)
            UIImage(named: "PhotoboothTemplateSketchPreview.png")!,
            UIImage(named: "PhotoboothTemplateKakaoPreview.png")!,
            UIImage(named: "PhotoboothTemplateKakao2Preview.png")!,
            UIImage(named: "PhotoboothTemplateKakao3Preview.png")!,
            UIImage(named: "PhotoboothTemplatePhotocardsPreview.png")!,
            UIImage(named: "PhotoboothTemplatePhotocards2Preview.png")!,
        ]
        areaSizes = [ // Areas to place the photos in
            areaSizeSketch,
            areaSizeKakao,
            areaSizeKakao2,
            areaSizeKakao3,
            areaSizePhotocards,
            areaSizePhotocards
        ]
        areaSizesPreview = [
            areaSizeSketchPreview,
            areaSizeKakaoPreview,
            areaSizeKakao2Preview,
            areaSizeKakao3Preview,
            areaSizePhotocardsPreview,
            areaSizePhotocardsPreview
        ]
        Task { // Compile the four images with each template
            try await compileImages()
            try await compilePreviewImages()
        }
    }
    
    @IBAction func toDropbox(_ sender: Any) {
        performSegue(withIdentifier: "toDropbox", sender: nil)
    }
    
    @IBAction func backToPhotobooth(_ sender: Any) {
        performSegue(withIdentifier: "cancelPreview", sender: nil)
    }
    
    @IBAction func scrollLeft(_ sender: Any) { // View image to the left
        var newImagePos = (currentImagePos - 1) % 6
        if newImagePos < 0 {
            newImagePos += 6
        }
        UIView.transition(with: self.previewImageView, duration: 0.3, options: .transitionCrossDissolve, animations: {self.previewImageView.image = self.compiledPreviewImages[newImagePos]}, completion: nil)
        currentImagePos = newImagePos
        numberToPrintLabel.text = String(numberToPrintArray[currentImagePos])
    }
    
    @IBAction func scrollRight(_ sender: Any) { // View image to the right
        let newImagePos = (currentImagePos + 1) % 6
        UIView.transition(with: self.previewImageView, duration: 0.3, options: .transitionCrossDissolve, animations: {self.previewImageView.image = self.compiledPreviewImages[newImagePos]}, completion: nil)
        currentImagePos = newImagePos
        numberToPrintLabel.text = String(numberToPrintArray[currentImagePos])
    }
    
    @IBAction func addPhoto(_ sender: Any) { // Adds 1 to the amount to print of that image
        numberToPrintArray[currentImagePos] += 1
        numberToPrintLabel.text = String(numberToPrintArray[currentImagePos])
    }
    
    @IBAction func removePhoto(_ sender: Any) { // Removes 1 to the amount to print of that image
        if numberToPrintArray[currentImagePos] != 0 {
            numberToPrintArray[currentImagePos] -= 1
            numberToPrintLabel.text = String(numberToPrintArray[currentImagePos])
        }
    }
    
    func compileImages() async throws { // Compile four images and templates
        let firstImage = imageArray[0]
        let secondImage = imageArray[1]
        let thirdImage = imageArray[2]
        let fourthImage = imageArray[3]
        let size = CGSize(width: 1800, height: 2700)
        let areaSizeTopImage = CGRect(x: 0, y: 0, width: 1800, height: 2700)
        
        for i in 0...(topImageTemplate.count - 1) {
            UIGraphicsBeginImageContext(size)
            firstImage.draw(in: areaSizes[i][0])
            secondImage.draw(in: areaSizes[i][1])
            thirdImage.draw(in: areaSizes[i][2])
            fourthImage.draw(in: areaSizes[i][3])
            topImageTemplate[i].draw(in: areaSizeTopImage, blendMode: .normal, alpha: 1)
            let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            compiledImages.append(newImage)
        }
    }
    
    func compilePreviewImages() async throws { // Compile four images and preview templates
        let firstImage = imageArray[0]
        let secondImage = imageArray[1]
        let thirdImage = imageArray[2]
        let fourthImage = imageArray[3]
        let size = CGSize(width: 1800, height: 2700)
        let areaSizeTopImage = CGRect(x: 0, y: 0, width: 1800, height: 2700)
        
        for i in 0...(topImageTemplatePreview.count - 1) {
            UIGraphicsBeginImageContext(size)
            firstImage.draw(in: areaSizesPreview[i][0])
            secondImage.draw(in: areaSizesPreview[i][1])
            thirdImage.draw(in: areaSizesPreview[i][2])
            fourthImage.draw(in: areaSizesPreview[i][3])
            topImageTemplatePreview[i].draw(in: areaSizeTopImage, blendMode: .normal, alpha: 1)
            let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            compiledPreviewImages.append(newImage)
        }
        
        previewImageView.image = compiledPreviewImages[0] // Display first image
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is DropboxViewController { // If segue destination is dropbox view controller
            let destinationVC = segue.destination as! DropboxViewController
            // Send images, preview images, four photos taken, and the number of each image to print to the dropbox view controller
            destinationVC.compiledImages = compiledImages
            destinationVC.numberToPrintArray = numberToPrintArray
            destinationVC.compiledPreviewImages = compiledPreviewImages
            destinationVC.imageArray = imageArray
        }
    }
}
