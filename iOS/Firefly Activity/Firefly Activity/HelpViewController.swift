//
//  HelpViewController.swift
//  Firefly Activity
//
//  Created by Denis Bohm on 4/20/18.
//  Copyright © 2018 Firefly Design LLC. All rights reserved.
//

import UIKit

protocol HelpViewControllerDelegate {
    
    func emailSupport(helpViewController: HelpViewController)
    func closeHelp(helpViewController: HelpViewController)
    
}

class HelpViewController: UIViewController {
    
    @IBOutlet var textView: UITextView!
    
    var delegate: HelpViewControllerDelegate? = nil
    var text: String = ""
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        textView.text = text
    }

    @IBAction func emailSupport(_ sender: Any?) {
        delegate?.emailSupport(helpViewController: self)
    }
    
    @IBAction func closeHelp() {
        delegate?.closeHelp(helpViewController: self)
    }
    
}
