//
//  ViewController.swift
//  Gestures
//
//  Created by David James on 2021-12-09.
//

import C3

class GesturesVc : ViewController, SafeLayout {
    func updateLayout(update: Update) {
        AppView()
            .in(view)
    }
    override var prefersStatusBarHidden: Bool {
        true 
    }
}
