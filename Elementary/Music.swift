//
//  Music.swift
//  Elementary
//
//  Created by Mathieu Vandeginste on 14/06/15.
//  Copyright (c) 2015 Supinfo. All rights reserved.
//

#if os(macOS)
import Cocoa
#else
import UIKit
#endif
import AVFoundation

class Music {
	static var player: AVAudioPlayer?
	class func playTrack() {
		
		let mediapath = "elementary"
		
		if let path = Bundle.main.url(forResource: mediapath, withExtension: "mp3") {
			try! player = AVAudioPlayer(contentsOf: path, fileTypeHint: "mp3")
			player?.numberOfLoops = -1
			player?.prepareToPlay()
			player?.play()
		}
	}
	
	
	class func adjustVolume(_ value: Float) {
		player?.volume = value

	}
}

