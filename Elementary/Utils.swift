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
        guard let dat = try? NSKeyedArchiver.archivedData(withRootObject: znes, requiringSecureCoding: true) else {
            return false
        }
        
        let url = URL(fileURLWithPath: path)
        do {
            try dat.write(to: url)
            return true
        } catch {
            return false
        }
	}
	
	class func loadHome() -> [Zone]? {
		Utils.getPath(6) // Get Path for Home
        
		//print("path = \(path)")
        let url = URL(fileURLWithPath: path)
        guard let dat = try? Data(contentsOf: url),
            let scene = try? NSKeyedUnarchiver.unarchivedObject(ofClass: LoadAndSaveHome.self, from: dat) else {
            return nil
        }
        
        //print("Loaded home!")
        
        for i in scene.zones {
            i.buildZone()
        }
        
        return scene.zones
    }
    
	@discardableResult
    class func saveZone() -> Bool {
        let idZone = World.selectedZone!
        Utils.getPath(idZone)
        
        let blockOfZone = LoadAndSaveZones(blocks: World.zones[idZone].blocks)
        guard let dat = try? NSKeyedArchiver.archivedData(withRootObject: blockOfZone, requiringSecureCoding: true) else {
            return false
        }
        let url = URL(fileURLWithPath: path)
        do {
            try dat.write(to: url)
            return true
        } catch {
            return false
        }
        //print("save blocks of zone (id: \(idZone)) ? \(success)")
        //print("path = \(path)")
    }
    
    class func loadZone(_ idZone: Int) -> [Block]? {
        Utils.getPath(idZone) // Get Path for Home
        
        //print("path = \(path)")
        let url = URL(fileURLWithPath: path)
        guard let dat = try? Data(contentsOf: url),
            let blocks = try? NSKeyedUnarchiver.unarchivedObject(ofClass: LoadAndSaveZones.self, from: dat) else {
            //print("Loaded blocks of zone with id \(idZone) !")
            
            return nil
        }
        return blocks.blocks
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
		return Float(self) ?? 0
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
