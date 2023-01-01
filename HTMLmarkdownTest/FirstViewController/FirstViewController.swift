//
//  FirstViewController.swift
//  HTMLmarkdownTest
//
//  Created by Natalia Sinitsyna on 30.12.2022.
//

import UIKit

class FirstViewController: UIViewController, FirstViewControllerDelegate {

    @IBOutlet weak var textView: UITextView!
    
    var text: NSMutableAttributedString = NSMutableAttributedString(string: "Some text", attributes: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.attributedText = text
    }
    
    override func viewWillAppear(_ animated: Bool) {
        textView.attributedText = text
    }

    @IBAction func buttonTapped(_ sender: Any) {
        let vc = TextViewController(withText: text)
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func movedBack(text: NSMutableAttributedString) {
        self.text = text
    }
    
}
