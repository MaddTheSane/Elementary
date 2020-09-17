//
//  Utils.swift
//  Elementary
//
//  Created by Mathieu Vandeginste on 25/05/15.
//  Copyright (c) 2015 Supinfo. All rights reserved.
//

#if os(macOS)
import Cocoa
#else
import UIKit
#endif
import SceneKit
//let PI: Float = Float(M_PI)
var path: String = ""
var colorChanged: Bool = false


class Utils {
	
	private class func documentsDirectory() -> String {
		let documentsFolderPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
		return documentsFolderPath
	}
	
	private class func fileInDocumentsDirectory(_ filename: String) -> String {
        return (documentsDirectory() as NSString).appendingPathComponent(filename)
	}
	
	private class func getPath(_ id: Int) {
		var name: String
		switch id {
        case 0 :
			name = "zone0.plist"
		case 1 :
			name = "zone1.plist"
		case 2 :
			name = "zone2.plist"
		case 3 :
			name = "zone3.plist"
		case 4 :
			name = "zone4.plist"
		case 5 :
			name = "zone5.plist"
		default :
			name = "home.plist"
		}
		path = fileInDocumentsDirectory(name)
	}
	
	class func resetFiles() {
		for i in 0...6 {
			Utils.getPath(i)
			try! FileManager.default.removeItem(atPath: path)
		}
		
	}
	
	@discardableResult
	class func saveHome() -> Bool {
		Utils.getPath(6)
        
		let znes = LoadAndSaveHome(zones: World.zones)
		var success = false
		success = NSKeyedArchiver.archiveRootObject(znes, toFile: path)
		//print("save home ? \(success)")
		//print("path = \(path)")
		return success
	}
	
	class func loadHome() -> [Zone]? {
		Utils.getPath(6) // Get Path for Home
        
		//print("path = \(path)")
		if let scene = NSKeyedUnarchiver.unarchiveObject(withFile: path) as! LoadAndSaveHome? {
			//print("Loaded home!")
            
            for i in scene.zones {
                i.buildZone()
            }
            
            return scene.zones
		} else {
			return nil
		}
    }
    
	@discardableResult
    class func saveZone() -> Bool {
        let idZone = World.selectedZone!
        Utils.getPath(idZone)
        
        let blockOfZone = LoadAndSaveZones(blocks: World.zones[idZone].blocks)
        var success = false
        success = NSKeyedArchiver.archiveRootObject(blockOfZone, toFile: path)
        //print("save blocks of zone (id: \(idZone)) ? \(success)")
        //print("path = \(path)")
        return success
    }
    
    class func loadZone(_ idZone: Int) -> [Block]? {
        Utils.getPath(idZone) // Get Path for Home
        
        //print("path = \(path)")
		if let blocks = NSKeyedUnarchiver.unarchiveObject(withFile: path) as! LoadAndSaveZones? {
            //print("Loaded blocks of zone with id \(idZone) !")
            
            return blocks.blocks
        } else {
            return nil
        }
    }
}

extension String {
	func toBool() -> Bool {
		switch self {
		case "True", "true", "yes", "1":
			return true
		case "False", "false", "no", "0":
			return false
		default:
			return false
		}
	}
	
	var floatValue: Float {
		return (self as NSString).floatValue
	}
}

extension Bool {
	func toString() -> String {
		switch self {
		case true:
			return "true"
		case false:
			return "false"
		}
	}
}
