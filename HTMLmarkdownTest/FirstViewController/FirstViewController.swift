//
//  FirstViewController.swift
//  HTMLmarkdownTest
//
//  Created by Natalia Sinitsyna on 30.12.2022.
//

import UIKit

class FirstViewController: UIViewController, FirstViewControllerDelegate {

    @IBOutlet weak var textView: UITextView!
    
    var text = "Some text"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.text = text
    }
    
    override func viewWillAppear(_ animated: Bool) {
        textView.text = text
    }

    @IBAction func buttonTapped(_ sender: Any) {
        let vc = TextViewController(wordPressMode: true)
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func movedBack(text: String) {
        self.text = text
    }
    
}
