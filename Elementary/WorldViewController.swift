//
//  WorldViewController.swift
//  Elementary
//
//  Created by Mathieu Vandeginste on 15/05/15.
//  Copyright (c) 2015 Supinfo. All rights reserved.
//

import UIKit
import SceneKit


class WorldViewController: UIViewController {
	// properties
	var worldNode =  SCNNode()
	let cameraNode = SCNNode()
	var currentAngle: Float = 0.0
	// IB outlets
	@IBOutlet weak var areaName: UILabel!
	@IBOutlet weak var world: SCNView!
	@IBOutlet weak var goToZoneOutlet: UIButton!
	@IBOutlet weak var editButton: UIButton!
	@IBOutlet weak var removeButton: UIButton!
	@IBOutlet weak var settingButton: UIButton!
	@IBOutlet weak var helpButton: UIButton!
	
    override func viewDidLoad() {
		Music.playTrack()
        super.viewDidLoad()
		world.backgroundColor = UIColor(white: 0, alpha: 0)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		world.backgroundColor = UIColor(white: 0, alpha: 0)
		self.world.showsStatistics = false
		self.sceneSetup()
        self.goToZoneOutlet.isHidden = true
        self.editButton.isHidden = true
        self.removeButton.isHidden = true
        
		if Teleport.autoSwitchBackToZone {
			//print("autoSwitch, worldSelected = \(World.selectedZone) ")
			Teleport.autoSwitchBackToZone = false
			Teleport.teleportMode = false
			World.selectedZone = Teleport.teleportFrom
            self.performSegue(withIdentifier: "displaySelectedZone", sender: self)
			
		}
        
		if Teleport.teleportMode {
			self.hideButtons(true)
			self.areaName.text = "Touch a world to teleport in"
            self.areaName.isHidden = false
            self.helpButton.isHidden = true
            self.settingButton.isHidden = true
			
        } else if (World.teleportingZoneId != -1) {
          
            self.hideButtons(true)
            self.areaName.isHidden = false
            self.helpButton.isHidden = true
            self.settingButton.isHidden = true
            self.areaName.text = "Going to \(World.zones[World.teleportingZoneId].name)..."
            
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 1
            //print("teleportingZoneId \(World.teleportingZoneId)")
            self.setNodePosition(World.teleportingZoneId)
            World.selectedZone = World.teleportingZoneId
            
            _ = Timer.scheduledTimer(timeInterval: 1.3, target: self, selector: #selector(WorldViewController.goToTeleportingZone), userInfo: nil, repeats: false)
            World.teleportingZoneId = -1
            SCNTransaction.commit()
            
        } else {
            self.helpButton.isHidden = false
            self.settingButton.isHidden = false
            self.areaName.isHidden = false
            self.areaName.text = "Elementary"
			if World.selectedZone != nil {
                //print("pas nil")
                
				self.areaName.text = World.zones[World.selectedZone!].name
				if World.zones[World.selectedZone!].empty == true {
					self.hideButtons(true)
                    self.goToZoneOutlet.setTitle("Touch here to create a new zone", for: .normal)
                    self.areaName.isHidden = true
                    self.goToZoneOutlet.isHidden = false
				} else {
                    self.goToZoneOutlet.setTitle("Touch here to enter in \(World.zones[World.selectedZone!].name)", for: .normal)
					self.hideButtons(false)
                    self.areaName.isHidden = false
                    self.goToZoneOutlet.isHidden = false
				}
				self.setNodePosition(World.selectedZone!)
				
            } else {
                self.goToZoneOutlet.isHidden = true
                self.editButton.isHidden = true
                self.removeButton.isHidden = true
            }
		}
		
	}
    
    @objc func goToTeleportingZone() {
        self.performSegue(withIdentifier: "displaySelectedZone", sender: self)
        self.setNodePosition(World.selectedZone!)
    }
	
	@IBAction func gotoSelectedZone(sender: AnyObject) {
		
		if World.zones[World.selectedZone!].empty == true {
            self.performSegue(withIdentifier: "createArea", sender: self)
			
		} else {
            self.performSegue(withIdentifier: "displaySelectedZone", sender: self)
			self.setNodePosition(World.selectedZone!)
		}
	}
	
	@IBAction func removeSelectedZone(sender: AnyObject) {
		// create alert controller
        let myAlert = UIAlertController(title: "Warning!", message: "Are you sure to delete \(World.zones[World.selectedZone!].name)? All the data inside the zone will be lost.", preferredStyle: .alert)
		// add an "OK" button
        myAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
			World.zones[World.selectedZone!].removeZone()
			self.hideButtons(true)
            self.hideButtonClearFace()
		}))
		// add an "Cancel" button
        myAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		// show the alert
        self.present(myAlert, animated: true, completion: nil)
	}
	
	@IBAction func editSelectedZone(sender: AnyObject) {
        self.performSegue(withIdentifier: "createArea", sender: self)
        self.goToZoneOutlet.isHidden = true
        self.editButton.isHidden = true
        self.removeButton.isHidden = true
        
        Utils.saveHome()
	}
	
	func sceneSetup() {
		let scene = SCNScene()
        let zonesLoaded = Utils.loadHome()
        
        //Building the world
        //With or without (you) saved zones
        if zonesLoaded != nil { // Saved (and loaded) zones
            World.zones = zonesLoaded!
            self.worldNode = World.buildWorld(withoutNewZones: true) // Without New Zones, just load saved zones
        } else {
            self.worldNode = World.buildWorld() // Create new zones
        }
        
        scene.rootNode.addChildNode(worldNode)
        
        if (World.selectedZone == nil) {
            self.rotateWorld()
        }
		
		//Customizing camera
		world.allowsCameraControl = true
		cameraNode.camera = SCNCamera()
		cameraNode.position = SCNVector3Make(0, 0, 3)
		scene.rootNode.addChildNode(cameraNode)
		
		//Customizing lights
		world.autoenablesDefaultLighting = false
		let ambientLightNode = SCNNode()
		ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = SCNLight.LightType.ambient
		ambientLightNode.light?.color = UIColor.white
		scene.rootNode.addChildNode(ambientLightNode)
		let omniLightNode = SCNNode()
		omniLightNode.light = SCNLight()
        omniLightNode.light!.type = SCNLight.LightType.omni
		omniLightNode.light!.color = UIColor.lightGray
		omniLightNode.position = SCNVector3Make(50, 50, 50)
		scene.rootNode.addChildNode(omniLightNode)
		world.scene = scene
		
		//add transparency to the background
		world.backgroundColor = UIColor(white: 0, alpha: 0)
		
		// add a pan gesture recognizer
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(WorldViewController.panGesture(_:)))
		world.addGestureRecognizer(panRecognizer)

		// add a tap gesture recognizer
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(WorldViewController.handleTap(_:)))
		var gestureRecognizers = [UIGestureRecognizer]()
		gestureRecognizers.append(tapGesture)
		if let existingGestureRecognizers = world.gestureRecognizers {
			gestureRecognizers.append(contentsOf: existingGestureRecognizers)
		}
		world.gestureRecognizers = gestureRecognizers
		
	}
															
	func rotateWorld() {
        self.worldNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 5, y: 1, z: 1, duration: 10)), forKey: "rotation")
	}
	
	func displayZones(){
		let vector = cameraNode.rotation
        let _ = worldNode.rotation
		//print("camera \(vector.w)  \(vector.x)    \(vector.y)")
		//print("node \(vectorNode.w)  \(vectorNode.x)    \(vectorNode.y)")
		if vector.w > 1 && vector.w < 3{
			if vector.x > 0.9 {
				areaName.text = World.zones[4].name
			} else if vector.x < -0.9 {
				areaName.text = World.zones[5].name
			} else if vector.y > 0.9 {
				areaName.text = World.zones[3].name
			}else if vector.y < -0.9 {
				areaName.text = World.zones[2].name
			} else {
				areaName.text = World.zones[1].name
			}
		} else if vector.w >= 3 {
			areaName.text = World.zones[0].name
		}
		else {
			areaName.text = World.zones[1].name
		}
	}
	
	@objc func panGesture(_ sender: UIPanGestureRecognizer) {
		self.hideButtons(true)
        self.worldNode.removeAction(forKey: "rotation")
        World.selectedZone = nil
        
        //Customizing camera function
        let translation = sender.translation(in: sender.view!)
		let translationX : Float = (Float)(translation.x)
		let translationY : Float = (Float)(translation.y)
		let newAngleX: Float = (Float)(translation.x) * .pi/180.0
		let newAngleY: Float = (Float)(translation.y) * .pi/180.0
		var newAngle: Float = sqrt(newAngleX*newAngleX + newAngleY*newAngleY)
		let proportion: Float = sqrt(translationX * translationX + translationY * translationY)
		let xProportion = translationX / proportion
		let yProportion = translationY / proportion
		newAngle += currentAngle
		worldNode.transform = SCNMatrix4MakeRotation(newAngle, yProportion, xProportion, 0)
		self.worldNode.removeAction(forKey: "rotation")

        if (sender.state == .ended){
			currentAngle = newAngle
		}
	}
	
	func setNodePosition(_ id: Int){
		switch id {
		case 0 :
			cameraNode.pivot = SCNMatrix4MakeRotation(0, 0, 0, 0)
			world.scene?.rootNode.pivot = SCNMatrix4MakeRotation(0, 0, 0, 0)
			worldNode.pivot = SCNMatrix4MakeRotation(0, 0, 0, 0)
			worldNode.rotation = SCNVector4Make(0.0, 1.0, 0.0, .pi)
		case 1 :
            worldNode.parent?.rotation = SCNVector4Make(0.0, 0.0, 0.0, 0)
			worldNode.rotation = SCNVector4Make(0.0, 0.0, 0.0, 0)
		case 2 :
            worldNode.parent?.rotation = SCNVector4Make(0.0, 0.0, 0.0, 0)
			worldNode.rotation = SCNVector4Make(0.0, 1.0, 0.0, -.pi/2)
		case 3 :
            worldNode.parent?.rotation = SCNVector4Make(0.0, 0.0, 0.0, 0)
			worldNode.rotation = SCNVector4Make(0.0, 1.0, 0.0, .pi/2)
		case 4 :
            worldNode.parent?.rotation = SCNVector4Make(0.0, 0.0, 0.0, 0)
			worldNode.rotation = SCNVector4Make(1.0, 0.0, 0.0, .pi/2)
		case 5 :
            worldNode.parent?.rotation = SCNVector4Make(0.0, 0.0, 0.0, 0)
			worldNode.rotation = SCNVector4Make(1.0, 0.0, 0.0, -.pi/2)
		default :
			break
		}
	}
	
	@objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        self.hideButtonClearFace()

        // check what nodes are tapped
        let p = gestureRecognize.location(in: world)
		
		let hitResults = world.hitTest(p, options: nil)
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result: AnyObject! = hitResults[0]
            let id: Int  = result.node.value(forKey: "id") as! Int
            if Teleport.teleportMode {
                let arrayLinks : [Int:Int]? = World.zones[id].links
                
                if (arrayLinks!.keys.firstIndex(of: Teleport.teleportFrom) != nil) { // Zone already linked
                    let alert = UIAlertController(title: "Warning", message: "This zone is already linked with the previous.\nYou can link zones between themselves only once.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                } else { // If not linked, ok
                    Teleport.teleportTo = id
                    if Teleport.checkTeleport() {
                        World.selectedZone = id
                        self.performSegue(withIdentifier: "displaySelectedZone", sender: self)
                    }
                }
            } else {
                if (id != World.selectedZone) { // If selected zone is newest
                    // get its material
                    let material = result.node!.geometry!.firstMaterial!
                    // highlight it
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 1
                    material.emission.contents = UIColor.red
                    self.worldNode.removeAction(forKey: "rotation")
                    self.setNodePosition(id)
                    World.selectedZone = id
                    self.areaName.text = World.zones[World.selectedZone!].name
                    if World.zones[World.selectedZone!].empty == true {
                        self.hideButtons(true)
                        self.goToZoneOutlet.setTitle("Touch here to create a new zone", for: .normal)
                        self.areaName.isHidden = true
                        self.goToZoneOutlet.isHidden = false
                    } else {
                        self.goToZoneOutlet.setTitle("Touch here to enter in \(World.zones[World.selectedZone!].name)", for: .normal)
                        self.hideButtons(false)
                    }
                    SCNTransaction.commit()
                } else {
                    World.selectedZone = nil
                }

            }
        } else { // On a cliqué ailleurs que sur une zone, donc on veut quitter la sélection
            World.selectedZone = nil
        }
		
	}
	
    func hideButtonClearFace(withoutRotate : Bool = false) {
        if (World.selectedZone != nil) {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 2
            World.zones[World.selectedZone!].node.geometry!.firstMaterial!.emission.contents = UIColor.black
            SCNTransaction.commit()
        }
        
        self.hideButtons(true)
        
        if (!withoutRotate) {
            self.rotateWorld()
        }
    }
	
	func hideButtons(_ bool: Bool){
        self.goToZoneOutlet.isHidden = bool
        self.editButton.isHidden = bool
        self.removeButton.isHidden = bool
        self.areaName.isHidden = bool
	}


	
}
