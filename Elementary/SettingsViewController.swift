//
//  SettingsViewController.swift
//  Elementary
//
//  Created by Mathieu Vandeginste on 16/05/15.
//  Copyright (c) 2015 Supinfo. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    // MARK: IBActions
	

    
    @IBAction func quit(sender: AnyObject) {
		self.dismiss(animated: true, completion: nil)
    }
    
	@IBOutlet weak var volume: UISlider!
	@IBAction func slideVolume(sender: AnyObject) {
		
		Music.adjustVolume(volume.value)
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		let swipeDown = UISwipeGestureRecognizer(target: self, action: "swiped:")
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
		self.view.addGestureRecognizer(swipeDown)
		let _ :UIViewController! = self.presentingViewController
    }
	
	func swiped(_ gesture : UIGestureRecognizer) {
		if let swipeGesture = gesture as? UISwipeGestureRecognizer {
			
			switch swipeGesture.direction {

            case UISwipeGestureRecognizerDirection.down:
                self.dismiss(animated: true, completion: nil)
				
			default:
				break
			}
			
		}
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
		
        // Dispose of any resources that can be recreated.
    }
	
	
	@IBAction func resetGame(_ sender: AnyObject) {
		// create alert controller
        let myAlert = UIAlertController(title: "Warning", message: "Are you sure to reset Elementary? Everything will be lost.", preferredStyle: UIAlertControllerStyle.alert)
		// add an "OK" button
        myAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
			for zone in World.zones {
				World.selectedZone = zone.id
				zone.removeZone()
			}
			Utils.resetFiles()
			
            World.selectedZone = nil
            self.dismiss(animated: true, completion: nil)
		}))
		// add an "Cancel" button
        myAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		// show the alert
        self.present(myAlert, animated: true, completion: nil)
        
        
	}

	
	
	
}

