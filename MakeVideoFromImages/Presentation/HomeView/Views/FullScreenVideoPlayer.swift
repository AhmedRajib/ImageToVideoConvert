//
//  FullScreenVideoPlayer.swift
//  MakeVideoFromImages
//
//  Created by MacBook Pro on 15/11/22.
//

import SwiftUI
import AVKit

struct FullScreenVideoPlayer: View {
    
    @State var urlOfVideo: URL
    var body: some View {
        ZStack {
            Color.gray.opacity(0.6)
            let player = AVPlayer(url: urlOfVideo)
            let _ = print("Main URL OF VIDEO \(urlOfVideo.absoluteString)")

            VideoPlayer(player: player)
                
                .onAppear() {
                    // Start the player going, otherwise controls don't appear
                    player.play()
            }
        }
    }
}

struct FullScreenVideoPlayer_Previews: PreviewProvider {
    static var previews: some View {
        FullScreenVideoPlayer(urlOfVideo: (URL(string: "") ?? URL(string: ""))!)
    }
}
