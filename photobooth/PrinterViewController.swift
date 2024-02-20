//
//  PrinterViewController.swift
//  photobooth
//
//  Created by Brandon Yen on 2/15/24.
//

import Foundation
import UIKit

let printerURL = URL(string: config.printer_ip)!
let currentPrinter = UIPrinter(url: printerURL)

class PrinterViewController: UIViewController {
    let testImages: [UIImage] = [UIImage(named: "PhotoboothTemplateKakao.png")!,UIImage(named: "PhotoboothTemplateSketch.png")!,UIImage(named: "PhotoboothTemplateKakao2.png")!]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func testbutton(_ sender: Any) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.test2(pos: 0, testImageArray: self.testImages)
        }
        performSegue(withIdentifier: "testSegue", sender: nil)
    }
    
    func test2(pos: Int, testImageArray: [UIImage]) {
        let printCompletionHandler: UIPrintInteractionController.CompletionHandler = { (controller, success, error) -> Void in
            if success && pos + 1 < testImageArray.count {
                print("printing again")
                let temp = pos + 1
                self.test2(pos: temp, testImageArray: testImageArray)
                    } else {
                        print("printed twice")
                    }
                }
        
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .photoGrayscale
        printInfo.jobName = "Printing"
        printController.printInfo = printInfo
        printController.printingItem = testImageArray[pos]
        
        printController.print(to: currentPrinter, completionHandler: printCompletionHandler)
    }
}
