
//
// GameViewController.swift
//  Elementary
//
//  Created by Mathieu Vandeginste on 15/05/15.
//  Copyright (c) 2015 Supinfo. All rights reserved.
//

import UIKit
import SceneKit

class GameViewController: UIViewController {
	
	//global properties
	var editionMode = false
	var editionOpened = false
	var counter = 0
    var cameraBloqued = false
	var scene: SCNScene?
    var cameraNode : SCNNode?
    var rotateAngle : Float = 0.01
	var scale : CGFloat = 1
	var angle : Float = 0
	var angleWorld : Float = 0
    var merging = false
    var mergingNodes = [SCNNode]()
	var savedCamera: SCNMatrix4 = SCNMatrix4()
    
	
	//IBOutlets
	@IBOutlet weak var elementaryButton: UIButton!
	@IBOutlet weak var scnView: SCNView!
	@IBOutlet weak var mergeButton: UIButton!
	@IBOutlet weak var colorButton: UIButton!
	@IBOutlet weak var teleportButton: UIButton!
	@IBOutlet weak var infoButton: UIButton!
	@IBOutlet weak var unmergeButton: UIButton!
	@IBOutlet weak var addEditButton: UIButton!
	@IBOutlet weak var cameraButton: UIButton!
	@IBOutlet weak var trashButton: UIButton!
	@IBOutlet weak var background: UIImageView!
    @IBOutlet weak var okMergeButton: UIButton!
    @IBOutlet weak var cancelMergeButton: UIButton!
   	
	//View methods
	override func viewDidLoad() {
		self.sceneSetup()
		super.viewDidLoad()
		self.hideButtons()
		self.hideTeleportMode(false)
		counter = World.zones[World.selectedZone!].counter
		//scnView.backgroundColor = UIColor(white: 0, alpha: 0)
    }
	
    override func viewDidAppear(_ animated: Bool) {
		
		//scnView.backgroundColor = UIColor(white: 0, alpha: 0)
		
		if counter != World.zones[World.selectedZone!].counter {
            self.addLastBlockToScene()
            self.cameraBloqued = true
            self.changeCamera(false)
			self.editionOpened = false
            self.showHideEdition()
			self.animateEdition()
		}
		if (Teleport.teleportMode){
			self.hideTeleportMode(true)
			// create alert controller
            let myAlert = UIAlertController(title: "Teleportation", message: "Now just choose the block you want to link with.\nPlease note that you can't link with a merged block.", preferredStyle: .alert)
			// add an "Got it!" button
            myAlert.addAction(UIAlertAction(title: "Got it", style: .default, handler: nil))
			// show the alert
            self.present(myAlert, animated: true, completion: nil)
		} else {
			let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(GameViewController.resetCamera))
			doubleTapGesture.numberOfTapsRequired = 2
			view.addGestureRecognizer(doubleTapGesture)
		}
		
		if colorChanged {
			resetCamera()
			colorChanged = false
		}
	}
	
	@objc func resetCamera() {
		self.scene = nil
		self.scnView.scene = self.scene
		self.sceneSetup()
	}
	
    @IBAction func cancelMergeButton(_ sender: AnyObject) {
        //print("cancel merge")
       
        for blocks : SCNNode in self.mergingNodes {
            blocks.geometry!.firstMaterial!.emission.contents = UIColor.black
        }
        
        mergingNodes = []
        showMergeButton(false)
        editionMode = true
        showHideEdition()
    }
    
    @IBAction func validMergeButton(_ sender: AnyObject) {
        if (mergingNodes.count > 1) { // Multiple blocks
            
            var idBlocks = [Int]()
            let parentNode = SCNNode()
            parentNode.setValue(true, forKey: "merged")
            
            for block : SCNNode in self.mergingNodes {
                parentNode.addChildNode(block)
                
                idBlocks.append(block.value(forKey: "id") as! Int)
            }
            
            self.scene!.rootNode.addChildNode(parentNode)
            
            for id : Int in idBlocks {
                let index = World.zones[World.selectedZone!].getIndex(fromBlock: id)
                
                for mergeId : Int in idBlocks {
                    if (mergeId != id) { // We add merge id if it isn't the actual block
                        //print("merge id \(mergeId) added to block \(id)")
                        World.zones[World.selectedZone!].blocks[index!].merge.append(mergeId)
                    }
                }
            }
            
            //print("merged ok")
            
            Utils.saveZone()            
            mergingNodes = []
            editionOpened = true
            self.animateEdition()
            self.showMergeButton(false)
            
            World.zones[World.selectedZone!].selectedNode = parentNode
            World.zones[World.selectedZone!].selectedBlock = idBlocks.first!
            
        } else { // Only one block
            
            let alert = UIAlertController(title: "Warning", message: "Please select more than one block to merge.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        }
    }
    
    @IBAction func mergeButtonClick(_ sender: AnyObject) {
        self.mergingNodes.append(World.zones[World.selectedZone!].selectedNode!)
        
        let msg = "You can now select all the objects you want to merge.\n\nTouch OK to merge the selected objects or the red cross to cancel."
        
        let alert = UIAlertController(title: "Merging", message: msg, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Got it", style: .default, handler: { (action) -> Void in
            self.showMergeButton(true)
            //print(self.mergingNodes)
            World.zones[World.selectedZone!].selectedNode = nil
            World.zones[World.selectedZone!].selectedBlock = -1
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        
        self.present(alert, animated: true, completion: nil)
        
        
    }
    
    @IBAction func unmergeButtonClick(_ sender: AnyObject) {
        if (World.zones[World.selectedZone!].selectedNode?.value(forKey: "merged") != nil) {
            // create alert controller
            let myAlert = UIAlertController(title: "Warning", message: "Are you sure to unmerge these blocks?", preferredStyle: .alert)
            // add an "OK" button
            myAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                for childBlocks : AnyObject in World.zones[World.selectedZone!].selectedNode!.childNodes {
                    let aChildBlock = childBlocks as? SCNNode
                    let idBlock: Int = aChildBlock!.value(forKey: "id") as! Int
                    
                    let index = World.zones[World.selectedZone!].getIndex(fromBlock: idBlock)
                    World.zones[World.selectedZone!].blocks[index!].merge = [Int]()
                    
                    childBlocks.geometry!!.firstMaterial!.emission.contents = UIColor.black
                }
                
                // we remove the parent node
                World.zones[World.selectedZone!].selectedNode?.setValue(nil, forKey: "merged")
                World.zones[World.selectedZone!].selectedNode?.setValue("true", forKey: "oldMerged")
                self.editionOpened = true
                self.editionMode = true
                //if edit was opened previously, we collapse it back
                self.animateEdition()
                self.showHideEdition()
                World.zones[World.selectedZone!].selectedNode = nil
                World.zones[World.selectedZone!].selectedBlock = -1
                Utils.saveZone()
                
                self.unmergeButton.isHidden = true
            }))
            // add an "Cancel" button
            myAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            // show the alert
            self.present(myAlert, animated: true, completion: nil)
        }
    }
    
    @IBAction func infoButtonClick(_ sender: AnyObject) {
		let precision = 1
        let sNode = World.zones[World.selectedZone!].selectedNode!
		let width = String(format: "%.\(precision)f", getDimensionForSelectedNode("x"))
		let height = String(format: "%.\(precision)f", getDimensionForSelectedNode("y"))
        let profondeur = String(format: "%.\(precision)f", getDimensionForSelectedNode("z"))
		var msg : String = ""
    
        if (World.zones[World.selectedZone!].selectedNode!.value(forKey: "merged") != nil) {
            msg += "Block merged\n\n"
        } else {
            let type = String(describing: sNode.geometry!).components(separatedBy: ":")[0].components(separatedBy:"<SCN")
            msg += "Type :  \(type[1])\n"
            msg += "Id :  \(World.zones[World.selectedZone!].selectedBlock)\n\n"
			let x = String(format: "%.\(precision)f", sNode.position.x)
			let y = String(format: "%.\(precision)f", sNode.position.y)
			let z = String(format: "%.\(precision)f", sNode.position.z)
            msg += "Position x :  \(x)\n"
            msg += "Position y :  \(y)\n"
            msg += "Position z :  \(z)\n\n"
        }
		

        msg += "Width :  \(width)\n"
        msg += "Height :  \(height)\n"
        msg += "Depth :  \(profondeur)"
        
        let alert = UIAlertController(title: "Informations", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
	
	func sceneSetup(){
		self.scene = SCNScene()
		//Building the ground
		World.zones[World.selectedZone!].buildGround()
        World.zones[World.selectedZone!].ground.physicsBody = SCNPhysicsBody.static()
		self.scene!.rootNode.addChildNode(World.zones[World.selectedZone!].ground)
		self.scene!.rootNode.rotation = SCNVector4Make(1.0, 0.0, 0.0, .pi/40)
		
		let blocksLoaded = Utils.loadZone(World.selectedZone!)
		
		//Building the world
		//With or without (you) saved blocks
		if blocksLoaded != nil { // Saved (and loaded) blocks
			World.zones[World.selectedZone!].blocks = blocksLoaded!
		}
		
		self.scene!.rootNode.addChildNode(World.zones[World.selectedZone!].buildAllBlocks()) // Build all blocks in array Zone.blocks
		
		let tree = Tree.buildTree()
		tree.position = SCNVector3Make(0, 1.5, 0)
		let house = TexturedHouse.buildHouse()
		house.position = SCNVector3Make(2, 1.5, 2)
		self.scene!.rootNode.addChildNode(tree)
		self.scene!.rootNode.addChildNode(house)
		
		
		// create and add a light to the scene
		let lightNode = SCNNode()
		lightNode.light = SCNLight()
        lightNode.light!.type = SCNLight.LightType.omni
		lightNode.position = SCNVector3(x: 0, y: 100, z: 100)
		scene!.rootNode.addChildNode(lightNode)
		
		// create and add an ambient light to the scene
		let ambientLightNode = SCNNode()
		ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLight.LightType.ambient
        ambientLightNode.light!.color = UIColor.darkGray
		self.scene!.rootNode.addChildNode(ambientLightNode)
        
        self.scnView.scene = scene
		
		// allows the user to manipulate the camera
		changeCamera(false)
		self.cameraNode = SCNNode()
		self.manageCamera()
		scene!.rootNode.addChildNode(cameraNode!)
		
		// show statistics such as fps and timing information
		scnView.showsStatistics = false
		
		// configure the background
		let bgName = "bg\(World.selectedZone!)"
		//print(bgName)
		self.background.image = UIImage(named: bgName)
		self.scnView.backgroundColor = UIColor(white: 0, alpha: 0)
		
		// add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(GameViewController.handleTap(_:)))
		var gestureRecognizers = [UIGestureRecognizer]()
		gestureRecognizers.append(tapGesture)
		if let existingGestureRecognizers = scnView.gestureRecognizers {
			gestureRecognizers.append(contentsOf: existingGestureRecognizers)
		}
		scnView.gestureRecognizers = gestureRecognizers
	}
	
	//IB Actions Methods
	@IBAction func dismiss(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
	}
    
    @IBAction func addEdit(_ sender: AnyObject) {
		if editionMode {
            cameraBloqued = true
            changeCamera(false) // No need to change state, we let it to blocked state
            self.animateEdition()
		} else {
            self.performSegue(withIdentifier: "createShape", sender: self)
		}
	}
	
	@IBAction func removeBlock(_ sender: AnyObject) {
		// create alert controller
        var myAlert : UIAlertController
        
        if (World.zones[World.selectedZone!].selectedNode?.value(forKey: "merged") == nil) {
            myAlert = UIAlertController(title: "Warning", message: "Are you sure to delete this block? ", preferredStyle: .alert)
        } else {
            myAlert = UIAlertController(title: "Warning", message: "You are trying to delete a merged block. If you delete it, all its children will be deleted.\n\nAre you sure to delete this block? ", preferredStyle: .alert)
        }
		// add an "OK" button
        myAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            if (World.zones[World.selectedZone!].selectedNode?.value(forKey: "merged") == nil) { // if not merged
                
                let index = World.zones[World.selectedZone!].getIndex()
                World.zones[World.selectedZone!].blocks.remove(at: index!)
                
                World.zones[World.selectedZone!].removeLinks("blockId", id: World.zones[World.selectedZone!].selectedBlock)
                
            } else { // Merged block
                
                for childBlocks : AnyObject in World.zones[World.selectedZone!].selectedNode!.childNodes {
                    let aChildBlock = childBlocks as? SCNNode
                    let idBlock: Int = aChildBlock!.value(forKey: "id") as! Int
                    
                    let index = World.zones[World.selectedZone!].getIndex(fromBlock: idBlock)
                    World.zones[World.selectedZone!].blocks.remove(at: index!)
                }
                
            }
            
            self.editionOpened = true
            //if edit was opened previously, we collapse it back
            self.animateEdition()
            self.showHideEdition()
            
            World.zones[World.selectedZone!].selectedNode!.removeFromParentNode()
            World.zones[World.selectedZone!].selectedNode = nil
            World.zones[World.selectedZone!].selectedBlock = -1
            
            Utils.saveZone()
		}))
		// add an "Cancel" button
        myAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		// show the alert
        self.present(myAlert, animated: true, completion: nil)
	}
    
	@IBAction func switchCameraMode(_ sender: AnyObject) {
        changeCamera() // when we click on the camera we change state
    }
	
    @IBAction func rotateGesture(_ sender: UIRotationGestureRecognizer) {
        if (World.zones[World.selectedZone!].selectedBlock != -1 && cameraBloqued && !merging) {
			let angleIncrement : Float = (sender.rotation > 0) ? 0.05 : -0.05
			self.angle += angleIncrement
            // World.zones[World.selectedZone!].selectedNode?.runAction(SCNAction.rotateByX(0, y: CGFloat(angle), z: 0, duration: 0.3))
            World.zones[World.selectedZone!].selectedNode?.rotation = SCNVector4Make(0.0, 1.0, 0.0, angle)
			let nodeRotation =  World.zones[World.selectedZone!].selectedNode?.rotation
            
            if (sender.state == .ended){
                World.zones[World.selectedZone!].blocks[World.zones[World.selectedZone!].getIndex()!].rotationX = nodeRotation?.x
                World.zones[World.selectedZone!].blocks[World.zones[World.selectedZone!].getIndex()!].rotationY = nodeRotation?.y
                World.zones[World.selectedZone!].blocks[World.zones[World.selectedZone!].getIndex()!].rotationZ = nodeRotation?.z
                World.zones[World.selectedZone!].blocks[World.zones[World.selectedZone!].getIndex()!].rotationW = nodeRotation?.w
                Utils.saveZone()
            }
		} else { //rotating the world
			let angleIncrement : Float = (sender.velocity > 0) ? 0.05 : -0.05
			self.angleWorld += angleIncrement
			cameraNode!.rotation = SCNVector4Make(0.0, 1.0, 0.0, angleWorld)
			World.zones[World.selectedZone!].selectedNode?.rotation = SCNVector4Make(0.0, 1.0, 0.0, angleWorld)
			

		}
    }
	
    @IBAction func zoomNodeGesture(_ sender: UIPinchGestureRecognizer) {
        if (World.zones[World.selectedZone!].selectedBlock != -1 && cameraBloqued && World.zones[World.selectedZone!].selectedNode!.value(forKey: "merged") == nil && !merging) { // if camera is blocked we take control
			var scaleIncrement : CGFloat = sender.scale
			scaleIncrement = (scaleIncrement - 1 )
			//print("scale \(self.scale) scaleIncrement \(scaleIncrement)")
			scale += scaleIncrement
			scale = (scale < 1 ) ? 1 : scale
			scale = (scale > 20 ) ? 20 : scale
			

            World.zones[World.selectedZone!].selectedNode?.scale = SCNVector3(x: Float(self.scale), y: Float(self.scale), z: Float(self.scale))
            
            if (sender.state == .ended){
                World.zones[World.selectedZone!].blocks[World.zones[World.selectedZone!].getIndex()!].scale = Float(self.scale)
                Utils.saveZone()
            }
        }
	}
	
    @IBAction func moveNodesGestures(_ sender: UIPanGestureRecognizer) {
        if (World.zones[World.selectedZone!].selectedBlock != -1 && cameraBloqued && !merging) { // only if fixed camera
            // direction.y => when we go up, it's < 0
            // direction.y => when we go down, it's > 0
            
            let direction = sender.velocity(in: self.view)
            let actualPosition = World.zones[World.selectedZone!].selectedNode?.position
            
            var newX = Float(actualPosition!.x)
            var newY = Float(actualPosition!.y)
            var newZ = Float(actualPosition!.z)
            
            if (sender.numberOfTouches == 1) { // one finger touch
                newX = (direction.x == 0) ? newX : Float(actualPosition!.x)+Float(direction.x/100)
                newY = (direction.y == 0) ? newY : Float(actualPosition!.y)-Float(direction.y/100)
                
                // if the newY is behind the the ground, we replace it correctly
                // BEWARE : direction.y is inversed. By default, natural scroll is used
                if (World.zones[World.selectedZone!].selectedNode?.value(forKey: "merged") == nil) {
                    //print("merged move")
                    if (newY-getDimensionForSelectedNode("y")/2 <= World.zones[World.selectedZone!].getAxisFromGround(min: false).y && direction.y > 0) {
                        newY = World.zones[World.selectedZone!].getAxisFromGround(min: false).y+self.getDimensionForSelectedNode("y")/2
                    } else if (newY+getDimensionForSelectedNode("y")/2 >= 50 && direction.y < 0) {
                        newY = 50
                    }
                } else {
                    if (newY <= World.zones[World.selectedZone!].getAxisFromGround(min: false).y-1 && direction.y > 0) {
                        newY = World.zones[World.selectedZone!].getAxisFromGround(min: false).y
                    } else if (newY >= 50 && direction.y < 0) {
                        newY = 50
                    }
                }
                
                // if newX is outside the ground, we replace it correctly
                if (newX-getDimensionForSelectedNode("x")/2 <= World.zones[World.selectedZone!].getAxisFromGround().x && direction.x < 0) {
                    newX = World.zones[World.selectedZone!].getAxisFromGround().x+self.getDimensionForSelectedNode("x")/2
                } else if (newX+getDimensionForSelectedNode("y")/2 >= World.zones[World.selectedZone!].getAxisFromGround(min: false).x && direction.x > 0) {
                    newX = World.zones[World.selectedZone!].getAxisFromGround(min: false).x-self.getDimensionForSelectedNode("y")/2
                }
                
            } else if (sender.numberOfTouches == 2) { // two fingers touch
                
                newZ = (direction.y == 0) ? newZ : Float(actualPosition!.z)+Float(direction.y/100)
                
                //if newZ is outside the ground, we replace it correctly
                if (newZ-getDimensionForSelectedNode("z")/2 <= World.zones[World.selectedZone!].getAxisFromGround().z && direction.y < 0) {
                    newZ = World.zones[World.selectedZone!].getAxisFromGround().z+self.getDimensionForSelectedNode("z")/2
                } else if (newZ+getDimensionForSelectedNode("z")/2 >= World.zones[World.selectedZone!].getAxisFromGround(min: false).z && direction.y > 0) {
                    newZ = World.zones[World.selectedZone!].getAxisFromGround(min: false).z-self.getDimensionForSelectedNode("z")/2
                }
            }
            
            World.zones[World.selectedZone!].selectedNode?.position = SCNVector3(x: newX, y: newY, z: newZ)
            
            if (sender.state == .ended){
                if (World.zones[World.selectedZone!].selectedNode!.value(forKey: "merged") == nil) { // if there's no merged block
                    World.zones[World.selectedZone!].blocks[World.zones[World.selectedZone!].getIndex()!].x = newX
                    World.zones[World.selectedZone!].blocks[World.zones[World.selectedZone!].getIndex()!].y = newY
                    World.zones[World.selectedZone!].blocks[World.zones[World.selectedZone!].getIndex()!].z = newZ
                } else { // if block merged, then we apply x,y,z to the children nodes
                    for childBlocks : AnyObject in World.zones[World.selectedZone!].selectedNode!.childNodes {
                        let aChildBlock = childBlocks as? SCNNode
                        let idBlock: Int = aChildBlock!.value(forKey: "id") as! Int

                        World.zones[World.selectedZone!].blocks[World.zones[World.selectedZone!].getIndex(fromBlock: idBlock)!].xParent = newX
                        World.zones[World.selectedZone!].blocks[World.zones[World.selectedZone!].getIndex(fromBlock: idBlock)!].yParent = newY
                        World.zones[World.selectedZone!].blocks[World.zones[World.selectedZone!].getIndex(fromBlock: idBlock)!].zParent = newZ
                    }
                }
                
                Utils.saveZone()
            }
        }
    }
    
	@IBAction func teleport(_ sender: AnyObject) {
        let _ : [Int:Int] = World.zones[World.selectedZone!].links
        
        if ((World.zones[World.selectedZone!].links.values.firstIndex(of: World.zones[World.selectedZone!].selectedBlock)) == nil) { // if a block not yet linked
            if Teleport.canTeleport() {
                Teleport.teleportMode = true
                Teleport.teleportFromBlockId = World.zones[World.selectedZone!].selectedBlock
                self.dismiss(animated: true, completion: nil)
            } else {
                // create alert controller
                let myAlert = UIAlertController(title: "Teleportation is unavailable", message: "You need to have at least another zone not already linked with this zone, which contains at least one unmerged block and with at least one block not linked. ", preferredStyle: .alert)
                // add an "OK" button
                myAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                // show the alert
                self.present(myAlert, animated: true, completion: nil)
            }
        } else {
            let myAlert = UIAlertController(title: "Teleportation is unavailable", message: "This block is already linked. Would you like to remove its link? ", preferredStyle: .alert)
            // add an "OK" button
            myAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) -> Void in
                // We teleport it
                World.zones[World.selectedZone!].removeLinks("blockId", id: World.zones[World.selectedZone!].selectedBlock)
            }))
            // add an "Cancel" button
            myAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            
            // show the alert
            self.present(myAlert, animated: true, completion: nil)
        }
	}
	
    func getDimensionForSelectedNode(_ whatWanted: String, aNode: SCNNode? = nil) -> Float {
        let theNode = (aNode != nil) ? aNode : World.zones[World.selectedZone!].selectedNode
        
        let scale = theNode!.scale.x
        
        let (min, max) = theNode!.boundingBox
        switch whatWanted{
        case "x":
            return (max.x-min.x)*scale
        case "y":
            return (max.y-min.y)*scale
        case "z":
            return (max.z-min.z)*scale
        default:
            return 0
        }
    }
	
    func changeCamera(_ changeState: Bool = true) {
        cameraBloqued = (changeState) ? !cameraBloqued : cameraBloqued
        
        if cameraBloqued {
            // fixed camera
            cameraButton.setImage(UIImage(named: "cameraOff"), for: .normal)
            scnView.allowsCameraControl = false
            cameraNode = SCNNode()
        } else {
            // free camera
            cameraButton.setImage(UIImage(named: "cameraOn"), for: .normal)
            scnView.allowsCameraControl = true
           // manageCamera()
        }
    }
	
    func manageCamera() {
        // create and add a camera to the scene
        self.cameraNode!.camera = SCNCamera()
		//place the camera
        self.cameraNode!.position = SCNVector3(x: 0, y: 20, z: 50)
    }
    
    func clearSelectedFace() {
        if (World.zones[World.selectedZone!].selectedNode != nil) {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 1.5
            if (World.zones[World.selectedZone!].selectedNode!.value(forKey: "merged") != nil) {
                for childBlocks : AnyObject in World.zones[World.selectedZone!].selectedNode!.childNodes {
                    childBlocks.geometry!!.firstMaterial!.emission.contents = UIColor.black
                }
            } else {
                World.zones[World.selectedZone!].selectedNode!.geometry!.firstMaterial!.emission.contents = UIColor.black
            }
            SCNTransaction.commit()
            World.zones[World.selectedZone!].selectedNode = nil
            World.zones[World.selectedZone!].selectedBlock = -1
        }
    }
	
	func addLastBlockToScene() {
		let block: Block = World.zones[World.selectedZone!].blocks.last!
		block.buildBlock()
        let node = block.node
		World.zones[World.selectedZone!].selectedNode = node
		World.zones[World.selectedZone!].selectedBlock = World.zones[World.selectedZone!].blocks.last!.id
        node?.geometry!.firstMaterial!.emission.contents = UIColor.red
		node?.scale = SCNVector3Make(5, 5, 5)
        World.zones[World.selectedZone!].blocks[World.zones[World.selectedZone!].getIndex()!].scale = 5
        Utils.saveZone()
		self.scnView.scene!.rootNode.addChildNode(node!)
        self.counter += 1
	}
	
	@objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        var didTouchNoneBlock = false
        
        if (Teleport.teleportMode) {
            // check what nodes are tapped
            let p = gestureRecognize.location(in: scnView)
            
            let hitResults = scnView.hitTest(p, options: nil)
            // check that we clicked on at least one object
            if hitResults.count > 0 {
                // retrieved the first clicked object
                let result: AnyObject! = hitResults[0]
                let id: Int  = result.node.value(forKey: "id") as! Int
                //print("ID block selected = \(id)")
                if id != -1 && (result.node.parent!.value(forKey: "merged")) == nil { // if not bg nor ground nor merged
                    World.zones[World.selectedZone!].selectedBlock = id
                    //print("ID block selected = \(id), blockSelected = \(World.zones[World.selectedZone!].selectedBlock)")
                    //link the blocks and dismiss
                    //print(Teleport.teleportMode)
                    Teleport.autoSwitchBackToZone = true
                    Teleport.saveTeleport()
                    self.dismiss(animated: true, completion: nil)
                } else if ((result.node.parent!.value(forKey: "merged")) != nil) { // if player chose a merged block
                    let alert = UIAlertController(title: "Warning", message: "You can't link the zone to a merged block.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
            
        } else {
            // check what nodes are tapped
            let p = gestureRecognize.location(in: scnView)
            let hitResults = scnView.hitTest(p, options: nil)
            // check that we clicked on at least one object
            if hitResults.count > 0 {
                // retrieved the first clicked object
                let result: AnyObject! = hitResults[0]
                let id: Int  = result.node.value(forKey: "id") as! Int
                //print("Id block \(id)")
                
                if (!merging) { // we don't merge, we act normally
                    if id != -1 && id != World.zones[World.selectedZone!].selectedBlock {
                        //print(World.zones[World.selectedZone!].links)
                        
                        if ((World.zones[World.selectedZone!].links.values.firstIndex(of: id)) != nil) { // we find out if it's a teleport or not                                 let index = find(World.zones[World.selectedZone!].links.values, id)
                        
                            self.doYouWantToTeleport(id)
                        }

                        self.clearSelectedFace()
                        
                        SCNTransaction.animationDuration = 0.5
                        self.editionOpened = true
                        self.editionMode = false
                        // highlight it
                        //if edit was opened previously, we collapse it back
                        animateEdition()
                        showHideEdition()
                        self.changeCamera(self.cameraBloqued ? true : false)

                        if ((result.node.parent!.value(forKey: "merged")) != nil) { // if we are on a block merged
                            //print("merged node")
                            
                            World.zones[World.selectedZone!].selectedNode = result.node.parent! as SCNNode
                            
                            for childBlocks : AnyObject in result.node.parent!.childNodes {
                                childBlocks.geometry!!.firstMaterial!.emission.contents = UIColor.red
                            }
                            
                        } else {
                            let material = result.node!.geometry!.firstMaterial!
                            let emission = self.editionMode ? UIColor.red : UIColor.black
                            material.emission.contents = emission
                            World.zones[World.selectedZone!].selectedNode = result.node as SCNNode
                        }
                        
                        World.zones[World.selectedZone!].selectedBlock = id

                    } else { //the player touched the ground or it's the same block
                        
                        //print("touched the ground")
                        didTouchNoneBlock = true
                        
                    }
                    
                } else { // we merge !
                 
                    if (id != -1) {
                        if (result.node!.parent!.value(forKey: "merged") == nil) { // If isn't a merged block
                            
                            var removeIndex = -1
                            
                            for i in 0..<self.mergingNodes.count {
                                let nodeId = self.mergingNodes[i].value(forKey: "id") as! Int

                                if nodeId == id { // if we touch an already selected block, we unselect it
                                    result.node!.geometry!.firstMaterial!.emission.contents = UIColor.black
                                    removeIndex = i
                                }
                            }
                            
                            if (removeIndex == -1) { // if it's not a block already selected
                                result.node!.geometry!.firstMaterial!.emission.contents = UIColor.red
                                self.mergingNodes.append(result.node!)
                            } else { // otherwise, we remove the block of the table
                                self.mergingNodes.remove(at: removeIndex)
                            }
                            
                            //print(mergingNodes)
                            
                        } else { // If we are on a merged block
                            
                            let alert = UIAlertController(title: "Warning", message: "This block is already merged. You can't merge it.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            
                        }
                    }
                    
                }
                    
                } else { //the player touched the background
                    
                    //print("touched the background")
                    // if we are in edit mode, we don't consider the touch outside to avoir player errors
                    didTouchNoneBlock = true
                }
                
                if (didTouchNoneBlock && !self.merging) { // if we don't merge
                    //print("didTouchNoneBlock")
                    
                    self.editionOpened = true
                    self.editionMode = true
                    animateEdition()
                    //if editMode is true, we turn it off
                    self.editionMode = true
                    showHideEdition()
                    self.clearSelectedFace()
                    self.changeCamera(((self.cameraBloqued) ? true : false))
                }
            }
        }

    func doYouWantToTeleport(_ idBlock: Int) {
        let array : [Int:Int] = World.zones[World.selectedZone!].links
        //print(World.zones[World.selectedZone!].links)
        var idZoneToTeleport : Int = -1
        
        for (aKey, aValue) in array {
            if (aValue == idBlock) {
                idZoneToTeleport = aKey
            }
        }
        
        let myAlert = UIAlertController(title: "Teleportation", message: "Would you like to teleport you in \"\(World.zones[idZoneToTeleport].name)\"?", preferredStyle: .alert)
        
        // add an "OK" button
        myAlert.addAction(UIAlertAction(title: "Go", style: .default, handler: { (action) -> Void in
            // We teleport it
            World.teleportingZoneId = idZoneToTeleport
            self.dismiss(animated: true, completion: nil)
        }))
        // add an "Cancel" button
        myAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        // show the alert
        self.present(myAlert, animated: true, completion: nil)
    }
	
	func animateEdition(){
		if editionOpened {
			editionOpened = false
			addEditButton.setImage(UIImage(named: "edit1"), for: .normal)
			//print("closing edition")
			hideEditButtons(true)
            cameraButton.isHidden = true
            changeCamera()
		} else {
            editionOpened = true
            cameraButton.isHidden = false
			addEditButton.setImage(UIImage(named: "edit2"), for: .normal)
			//print("opening edition")
			
            self.colorButton.center = CGPoint(x: self.addEditButton.center.x, y: self.addEditButton.center.y)
            self.teleportButton.center = CGPoint(x: self.addEditButton.center.x, y: self.addEditButton.center.y)
            self.infoButton.center = CGPoint(x: self.addEditButton.center.x, y: self.addEditButton.center.y)
            self.unmergeButton.center = CGPoint(x: self.addEditButton.center.x, y: self.addEditButton.center.y)
            self.mergeButton.center = CGPoint(x: self.addEditButton.center.x, y: self.addEditButton.center.y)
            
			hideEditButtons(false)
			UIView.animate(withDuration: 0.3, animations: {
                if (World.zones[World.selectedZone!].selectedNode!.value(forKey: "merged") != nil) { // if mergig, we display two buttons
					self.infoButton.center = CGPoint(x: self.addEditButton.center.x+38, y: self.addEditButton.center.y)
					self.unmergeButton.center = CGPoint(x: self.addEditButton.center.x, y: self.addEditButton.center.y-38)
                } else {
                    self.mergeButton.center = CGPoint(x: self.addEditButton.center.x, y: self.addEditButton.center.y-38)
                    self.infoButton.center = CGPoint(x: self.addEditButton.center.x + 38, y: self.addEditButton.center.y)
                    self.colorButton.center = CGPoint(x: self.addEditButton.center.x + 79, y: self.addEditButton.center.y)
                    self.teleportButton.center = CGPoint(x: self.addEditButton.center.x + 117, y: self.addEditButton.center.y)
                }
				
			})
			
		}
	}
	
	func showHideEdition(){
		if editionMode {
			editionMode = false
			//print("addMode")
			addEditButton.setImage(UIImage(named: "add"), for: .normal)
			trashButton.isHidden = true
			cameraButton.isHidden = true
		} else {
			editionMode = true
			//print("editMode")
			addEditButton.setImage(UIImage(named: "edit1"), for: .normal)
			trashButton.isHidden = false
		}
	}
	
    func hideButtons(_ hideAll : Bool = false){
		mergeButton.isHidden = true
		colorButton.isHidden = true
		teleportButton.isHidden = true
		infoButton.isHidden = true
		unmergeButton.isHidden = true
		trashButton.isHidden = true
		cameraButton.isHidden = true
        
        addEditButton.isHidden = hideAll
	}
    
    func showMergeButton(_ show: Bool) {
        if (show) {
            hideButtons(true)
            okMergeButton.isHidden = false
            cancelMergeButton.isHidden = false
            
            merging = true // merging mode
        } else {
            clearSelectedFace()
            hideButtons()
            okMergeButton.isHidden = true
            cancelMergeButton.isHidden = true
            
            merging = false // not merging mode
        }
    }
	
	func hideEditButtons(_ bool: Bool){
        if (World.zones[World.selectedZone!].selectedNode != nil && World.zones[World.selectedZone!].selectedNode!.value(forKey: "merged") != nil) { // Si merged
            unmergeButton.isHidden = bool
        } else {
            mergeButton.isHidden = bool
            colorButton.isHidden = bool
            teleportButton.isHidden = bool
        }
        
        if (bool) {
            unmergeButton.isHidden = bool
        }
        
        infoButton.isHidden = bool
	}
	
	func hideTeleportMode(_ bool: Bool){
		self.elementaryButton.isHidden = bool
		self.addEditButton.isHidden = bool
	}
	
}
