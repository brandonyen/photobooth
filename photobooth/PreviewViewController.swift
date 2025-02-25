import UIKit
import Foundation

class PreviewViewController: UIViewController {
    // Outlets
    @IBOutlet var previewImageView: UIImageView!
    @IBOutlet var numberToPrintLabel: UILabel!
    
    // Variables
    var pickupName: String!
    var imageArray: [UIImage]!
    var currentImagePos = 0
    var numberToPrintArray = Array(repeating: 0, count: numTemplates)
    var compiledImages: [UIImage] = []
    var compiledPreviewImages: [UIImage] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            try await compileImages()
            try await compilePreviewImages()
        }
    }
    
    @IBAction func toDropbox(_ sender: Any) {
        presentNameAlert { name in
            self.pickupName = name
            self.performSegue(withIdentifier: "toDropbox", sender: nil)
        }
    }
    
    @IBAction func backToPhotobooth(_ sender: Any) {
        performSegue(withIdentifier: "cancelPreview", sender: nil)
    }
    
    @IBAction func scrollLeft(_ sender: Any) {
        updateImagePosition(by: -1)
    }
    
    @IBAction func scrollRight(_ sender: Any) {
        updateImagePosition(by: 1)
    }
    
    @IBAction func addPhoto(_ sender: Any) {
        updatePhotoCount(by: 1)
    }
    
    @IBAction func removePhoto(_ sender: Any) {
        updatePhotoCount(by: -1)
    }
    
    func compileImages() async throws {
        compileImageSet(templates: topImageTemplate, areaSize: areaSizes, into: &compiledImages)
    }
    
    func compilePreviewImages() async throws {
        compileImageSet(templates: topImageTemplatePreview, areaSize: areaSizesPreview, into: &compiledPreviewImages)
        previewImageView.image = compiledPreviewImages.first
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? DropboxViewController {
            destinationVC.compiledImages = compiledImages
            destinationVC.numberToPrintArray = numberToPrintArray
            destinationVC.compiledPreviewImages = compiledPreviewImages
            destinationVC.imageArray = imageArray
            destinationVC.pickupName = pickupName
        }
    }
    
    private func presentNameAlert(completion: @escaping (String) -> Void) {
        let alertController = UIAlertController(title: "Enter your name", message: "Please enter a name for photo pickup.", preferredStyle: .alert)
        alertController.addTextField { $0.placeholder = "Name..." }
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            if let name = alertController.textFields?.first?.text {
                completion(name)
            }
        }
        alertController.addAction(saveAction)
        present(alertController, animated: true)
    }
    
    private func updateImagePosition(by offset: Int) {
        currentImagePos = (currentImagePos + offset + numTemplates) % numTemplates
        UIView.transition(with: previewImageView, duration: 0.3, options: .transitionCrossDissolve) {
            self.previewImageView.image = self.compiledPreviewImages[self.currentImagePos]
        }
        numberToPrintLabel.text = String(numberToPrintArray[currentImagePos])
    }
    
    private func updatePhotoCount(by amount: Int) {
        numberToPrintArray[currentImagePos] = max(0, numberToPrintArray[currentImagePos] + amount)
        numberToPrintLabel.text = String(numberToPrintArray[currentImagePos])
    }
    
    private func compileImageSet(templates: [UIImage], areaSize: [[CGRect]], into array: inout [UIImage]) {
        let size = CGSize(width: 1800, height: 2700)
        let areaSizeTopImage = CGRect(origin: .zero, size: size)
        
        for (index, template) in templates.enumerated() {
            UIGraphicsBeginImageContext(size)
            imageArray.enumerated().forEach { idx, image in
                image.draw(in: areaSize[index][idx])
            }
            template.draw(in: areaSizeTopImage)
            if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
                array.append(newImage)
            }
            UIGraphicsEndImageContext()
        }
    }
}
