//
//  LoadAndSave.swift
//  Elementary
//
//  Created by Adrian on 25/05/2015.
//  Copyright (c) 2015 Supinfo. All rights reserved.
//

import SceneKit


//Serializing home
class LoadAndSaveHome: NSObject, NSCoding {
    var zones: [Zone]
    
    init(zones: [Zone]) {
        self.zones = zones
        super.init()
    }
    
    required init(coder decoder: NSCoder) {
        self.zones = decoder.decodeObject(forKey: "zones") as! [Zone]
        super.init()
    }
    
    func encode(with encoder: NSCoder) {
        encoder.encode(zones, forKey:"zones")
    }
}

//Serializing blocks
class LoadAndSaveZones: NSObject, NSSecureCoding {
    var blocks: [Block]
    
    init(blocks: [Block]) {
        self.blocks = blocks
        super.init()
    }
    
    class var supportsSecureCoding: Bool {
        return true
    }
    
    required init(coder decoder: NSCoder) {
        self.blocks = decoder.decodeObject(of: [Block.self, NSArray.self], forKey: "blocks") as! [Block]
        super.init()
    }
    
    func encode(with encoder: NSCoder) {
        encoder.encode(blocks, forKey:"blocks")
    }
}


