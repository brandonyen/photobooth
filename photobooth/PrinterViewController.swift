//
//  PrinterViewController.swift
//  photobooth
//
//  Created by Brandon Yen on 2/15/24.
//

import Foundation
import UIKit

class PrinterViewController: UIViewController {
    var testVar = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func testbutton(_ sender: Any) {
        test()
    }
    
    func test() {
        let printCompletionHandler: UIPrintInteractionController.CompletionHandler = { (controller, success, error) -> Void in
            if success && self.testVar {
                print("printing again")
                self.testVar = false
            } else {
                print("printed twice")
            }
        }
        
        let image = UIImage(named: "PhotoboothTemplateKakao.png")
        let jpgData = image?.jpegData(compressionQuality: 0.1)
        
        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .photoGrayscale
        printInfo.jobName = "Printing"
        
        let printController = UIPrintInteractionController.shared
        printController.printInfo = printInfo
        printController.printingItem = jpgData
        
        let printerURL = URL(string: "ipps://10.156.8.85/ipp/print")!
        let currentPrinter = UIPrinter(url: printerURL)
        
        printController.print(to: currentPrinter, completionHandler: printCompletionHandler)
    }
}
