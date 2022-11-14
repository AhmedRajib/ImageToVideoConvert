//
//  PlayVideo.swift
//  MakeVideoFromImages
//
//  Created by MacBook Pro on 12/11/22.
//

import SwiftUI
import AVKit

struct PlayVideo: View {
//    let avPlayer = AVPlayer(url:  Bundle.main.url(forResource: "file:///Users/MacBook/Library/Developer/CoreSimulator/Devices/37C38913-E253-4587-8150-59CA86832000/data/Containers/Data/Application/5383A897-4437-4B2E-B33B-7FA7D739DE41/Documents/video1", withExtension: "MP4")!)
    
    let player = AVPlayer(url: URL(string: "Documents/video1.MP4")!)
    var body: some View {
        VideoPlayer(player: player)
            .onDisappear {
                player.isMuted = false
            }
    }
}

struct PlayVideo_Previews: PreviewProvider {
    static var previews: some View {
        PlayVideo()
    }
}
