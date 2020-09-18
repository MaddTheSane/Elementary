//
//  Block.swift
//  Elementary
//
//  Created by Adrian on 06/06/2015.
//  Copyright (c) 2015 Supinfo. All rights reserved.
//

#if os(macOS)
import Cocoa
#else
import UIKit
#endif
import SceneKit

class Block : NSObject, NSSecureCoding {
	
	
	var id: Int
	var texture: String?
	var red: CGFloat = 0.09
	var green: CGFloat = 0.48
	var blue: CGFloat = 0.05
	var x: Float
	var y: Float
	var z: Float
    var rotationX : Float?
    var rotationY : Float?
    var rotationZ : Float?
    var rotationW : Float?
    var scale = Float(1)
	var shape: SCNGeometry
	var node: SCNNode?
    var merge = [Int]()
    var xParent : Float = 0
    var yParent : Float = 0
    var zParent : Float = 0
	
	
	init(id: Int, texture: String?, red: CGFloat, green: CGFloat, blue: CGFloat, x: Float, y: Float, z: Float, shape: SCNGeometry) {
		self.id = id
		self.red = red
		self.blue = blue
		self.green = green
		self.texture = texture
		self.x = x
		self.y = y
		self.z = z
		self.shape = shape
        super.init()
    }
	
    func buildBlock() {
		//print("Scale \(self.scale)")
        
		
		let node = SCNNode(geometry: self.shape)
		node.geometry!.firstMaterial!.emission.contents = SCNColor.black
        node.setValue(self.id, forKey: "id")
        node.position = SCNVector3(self.x, self.y, self.z)
        node.scale = SCNVector3(self.scale, self.scale, self.scale)
        
        if (self.rotationW != nil) {
            node.rotation = SCNVector4(self.rotationX!, self.rotationY!, self.rotationZ!, self.rotationW!)
        }
        
		self.node = node
	}
	
	func setTexture(_ texture: String?, red: CGFloat, green: CGFloat, blue: CGFloat){
		if let texture = texture {
            //print("mode texture")
            self.texture = texture
            self.node?.geometry?.firstMaterial?.diffuse.contents = SCNImage(named: self.texture!)
        } else {
			self.red = red
			self.green = green
			self.blue = blue
			//print("mode color red = \(self.red) green = \(self.green) blue = \(self.blue)")
			let color = SCNColor(red: self.red, green: self.green, blue: self.blue, alpha: 1)
			self.node?.geometry?.firstMaterial?.diffuse.contents = color
		}
	}
    
    required init(coder decoder: NSCoder) {
		self.id         = decoder.decodeInteger(forKey: "id")
        self.texture    = decoder.decodeObject(of: NSString.self, forKey: "texture") as String?
		self.red        = decoder.decodeObject(of: NSNumber.self, forKey: "red") as! CGFloat
		self.green      = decoder.decodeObject(of: NSNumber.self, forKey: "green") as! CGFloat
		self.blue       = decoder.decodeObject(of: NSNumber.self, forKey: "blue") as! CGFloat
		self.x          = decoder.decodeFloat(forKey: "x")
		self.y          = decoder.decodeFloat(forKey: "y")
		self.z          = decoder.decodeFloat(forKey: "z")
        self.shape      = decoder.decodeObject(of: SCNGeometry.self, forKey: "shape")!
		self.scale      = decoder.decodeFloat(forKey: "scale")
        self.rotationX  = decoder.decodeObject(of: NSNumber.self, forKey: "rotationX") as? Float
		self.rotationY  = decoder.decodeObject(of: NSNumber.self, forKey: "rotationY") as? Float
		self.rotationZ  = decoder.decodeObject(of: NSNumber.self, forKey: "rotationZ") as? Float
		self.rotationW  = decoder.decodeObject(of: NSNumber.self, forKey: "rotationW") as? Float
        self.merge      = decoder.decodeObject(of: [NSNumber.self, NSArray.self], forKey: "merge") as! [Int]
		self.xParent    = decoder.decodeFloat(forKey: "xParent")
		self.yParent    = decoder.decodeFloat(forKey: "yParent")
		self.zParent    = decoder.decodeFloat(forKey: "zParent")
        
        super.init()
    }
    
    func encode(with encoder: NSCoder) {
		encoder.encode(id, forKey: "id")
		encoder.encode(texture, forKey: "texture")
		encoder.encode(red, forKey: "red")
		encoder.encode(green, forKey: "green")
		encoder.encode(blue, forKey: "blue")
		encoder.encode(x, forKey: "x")
		encoder.encode(y, forKey: "y")
		encoder.encode(z, forKey: "z")
		encoder.encode(shape, forKey: "shape")
		encoder.encode(scale, forKey: "scale")
		encoder.encode(rotationX, forKey: "rotationX")
		encoder.encode(rotationY, forKey: "rotationY")
		encoder.encode(rotationZ, forKey: "rotationZ")
		encoder.encode(rotationW, forKey: "rotationW")
		encoder.encode(merge, forKey: "merge")
		encoder.encode(xParent, forKey: "xParent")
		encoder.encode(yParent, forKey: "yParent")
		encoder.encode(zParent, forKey: "zParent")
    }
    
    class var supportsSecureCoding: Bool {
        return true
    }
    
}
