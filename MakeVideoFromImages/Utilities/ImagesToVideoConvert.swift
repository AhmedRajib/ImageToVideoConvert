//
//  ImagesToVideoConvert.swift
//  MakeVideoFromImages
//
//  Created by MacBook Pro on 7/11/22.
//

import Foundation
import UIKit
import AVFoundation



struct HomeScreendataModel {
    let outputSize = CGSize(width: 1920, height: 1280)
    let imagesPerSecond: TimeInterval = 3 //each image will be stay for 3 secs
    var selectedPhotosArray = [UIImage]()
    var imageArrayToVideoURL = NSURL()
    let audioIsEnabled: Bool = false //if your video has no sound
    var asset: AVAsset!
}


class ImagesToVideoConvert: ObservableObject {
    
    
    @Published var dataModel = HomeScreendataModel()

    
    func buildVideoFromImageArray(selectedImages: [UIImage]) -> String {
        //           for image in 0..<5 {
        //               selectedPhotosArray.append(UIImage(named: "\(image + 1).JPG")!) //name of the images: 1.JPG, 2.JPG, 3.JPG, 4.JPG, 5.JPG
        //           }
        dataModel.selectedPhotosArray.append(contentsOf: selectedImages)
        
        dataModel.imageArrayToVideoURL = NSURL(fileURLWithPath: NSHomeDirectory() + "/Documents/video1.MP4")
        removeFileAtURLIfExists(url: dataModel.imageArrayToVideoURL)
        guard let videoWriter = try? AVAssetWriter(outputURL: dataModel.imageArrayToVideoURL as URL, fileType: AVFileType.mp4) else {
            fatalError("AVAssetWriter error")
        }
        let outputSettings = [AVVideoCodecKey : AVVideoCodecType.h264, AVVideoWidthKey : NSNumber(value: Float(dataModel.outputSize.width)), AVVideoHeightKey : NSNumber(value: Float(dataModel.outputSize.height))] as [String : Any]
        guard videoWriter.canApply(outputSettings: outputSettings, forMediaType: AVMediaType.video) else {
            fatalError("Negative : Can't apply the Output settings...")
        }
        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        let sourcePixelBufferAttributesDictionary = [kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32ARGB), kCVPixelBufferWidthKey as String: NSNumber(value: Float(dataModel.outputSize.width)), kCVPixelBufferHeightKey as String: NSNumber(value: Float(dataModel.outputSize.height))]
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        }
        if videoWriter.startWriting() {
            let zeroTime = CMTimeMake(value: Int64(dataModel.imagesPerSecond),timescale: Int32(1))
            videoWriter.startSession(atSourceTime: zeroTime)
            
            assert(pixelBufferAdaptor.pixelBufferPool != nil)
            let media_queue = DispatchQueue(label: "mediaInputQueue")
            videoWriterInput.requestMediaDataWhenReady(on: media_queue, using: { [self] () -> Void in
                let fps: Int32 = 1
                let framePerSecond: Int64 = Int64(dataModel.imagesPerSecond)
                let frameDuration = CMTimeMake(value: Int64(dataModel.imagesPerSecond), timescale: fps)
                var frameCount: Int64 = 0
                var appendSucceeded = true
                while (!self.dataModel.selectedPhotosArray.isEmpty) {
                    if (videoWriterInput.isReadyForMoreMediaData) {
                        let nextPhoto = dataModel.selectedPhotosArray.remove(at: 0)
                        let lastFrameTime = CMTimeMake(value: frameCount * framePerSecond, timescale: fps)
                        let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                        var pixelBuffer: CVPixelBuffer? = nil
                        let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferAdaptor.pixelBufferPool!, &pixelBuffer)
                        if let pixelBuffer = pixelBuffer, status == 0 {
                            let managedPixelBuffer = pixelBuffer
                            CVPixelBufferLockBaseAddress(managedPixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                            let data = CVPixelBufferGetBaseAddress(managedPixelBuffer)
                            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
                            let context = CGContext(data: data, width: Int(dataModel.outputSize.width), height: Int(dataModel.outputSize.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(managedPixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
                            context!.clear(CGRect(x: 0, y: 0, width: CGFloat(dataModel.outputSize.width), height: CGFloat(dataModel.outputSize.height)))
                            let horizontalRatio = CGFloat(dataModel.outputSize.width) / nextPhoto.size.width
                            let verticalRatio = CGFloat(dataModel.outputSize.height) / nextPhoto.size.height
                            //let aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFill
                            let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit
                            let newSize: CGSize = CGSize(width: nextPhoto.size.width * aspectRatio, height: nextPhoto.size.height * aspectRatio)
                            let x = newSize.width < dataModel.outputSize.width ? (dataModel.outputSize.width - newSize.width) / 2 : 0
                            let y = newSize.height < dataModel.outputSize.height ? (dataModel.outputSize.height - newSize.height) / 2 : 0
                            context?.draw(nextPhoto.cgImage!, in: CGRect(x: x, y: y, width: newSize.width, height: newSize.height))
                            CVPixelBufferUnlockBaseAddress(managedPixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                            appendSucceeded = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                        } else {
                            print("Failed to allocate pixel buffer")
                            appendSucceeded = false
                        }
                    }
                    if !appendSucceeded {
                        break
                    }
                    frameCount += 1
                }
                videoWriterInput.markAsFinished()
                videoWriter.finishWriting {
                    DispatchQueue.main.async {
                        print("-----video1 url = \(self.dataModel.imageArrayToVideoURL)")
                        
                        dataModel.asset = AVAsset(url: dataModel.imageArrayToVideoURL as URL)
                    }
                    
//                    exportVideoWithAnimation()
                }
            })
        }
        if !(dataModel.imageArrayToVideoURL.absoluteString?.isEmpty ?? false) {
            return self.dataModel.imageArrayToVideoURL.absoluteString ?? ""
        }else {
            return "IsEmpty"
        }
        
    }
    
    func removeFileAtURLIfExists(url: NSURL) {
        if let filePath = url.path {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                do{
                    try fileManager.removeItem(atPath: filePath)
                } catch let error as NSError {
                    print("Couldn't remove existing destination file: \(error)")
                }
            }
        }
    }
    
    func exportVideoWithAnimation() async {
        let composition = AVMutableComposition()
        
        let track =  dataModel.asset?.tracks(withMediaType: AVMediaType.video)
        let videoTrack:AVAssetTrack = track![0] as AVAssetTrack
        guard let timerange =  try? await CMTimeRangeMake(start: CMTime.zero, duration: (dataModel.asset?.load(.duration))!) else {
            return
        }
        
        let compositionVideoTrack:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID())!
        
        do {
            try compositionVideoTrack.insertTimeRange(timerange, of: videoTrack, at: CMTime.zero)
            compositionVideoTrack.preferredTransform = videoTrack.preferredTransform
        } catch {
            print(error)
        }
        
        //if your video has sound, you don’t need to check this
        if dataModel.audioIsEnabled {
            let compositionAudioTrack:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID())!
            
            for audioTrack in (dataModel.asset?.tracks(withMediaType: AVMediaType.audio))! {
                do {
                    try compositionAudioTrack.insertTimeRange(audioTrack.timeRange, of: audioTrack, at: CMTime.zero)
                } catch {
                    print(error)
                }
            }
        }
        
        let size = videoTrack.naturalSize
        
        let videolayer = CALayer()
        videolayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        let parentlayer = CALayer()
        parentlayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        parentlayer.addSublayer(videolayer)
        
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //this is the animation part
        var time = [0.00001, 3, 6, 9, 12] //I used this time array to determine the start time of a frame animation. Each frame will stay for 3 secs, thats why their difference is 3
        var imgarray = [UIImage]()
        
        for image in 0..<5 {
            imgarray.append(UIImage(named: "\(image + 1).JPG")!)
            
            let nextPhoto = imgarray[image]
            
            let horizontalRatio = CGFloat(self.dataModel.outputSize.width) / nextPhoto.size.width
            let verticalRatio = CGFloat(self.dataModel.outputSize.height) / nextPhoto.size.height
            let aspectRatio = min(horizontalRatio, verticalRatio)
            let newSize: CGSize = CGSize(width: nextPhoto.size.width * aspectRatio, height: nextPhoto.size.height * aspectRatio)
            let x = newSize.width < self.dataModel.outputSize.width ? (self.dataModel.outputSize.width - newSize.width) / 2 : 0
            let y = newSize.height < self.dataModel.outputSize.height ? (self.dataModel.outputSize.height - newSize.height) / 2 : 0
            
            ///I showed 10 animations here. You can uncomment any of this and export a video to see the result.
            
            ///#1. left->right///
            let blackLayer = CALayer()
            blackLayer.frame = CGRect(x: -videoTrack.naturalSize.width, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
            blackLayer.backgroundColor = UIColor.black.cgColor
            
            let imageLayer = CALayer()
            imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
            imageLayer.contents = imgarray[image].cgImage
            blackLayer.addSublayer(imageLayer)
            
            let animation = CABasicAnimation()
            animation.keyPath = "position.x"
            animation.fromValue = -videoTrack.naturalSize.width
            animation.toValue = 2 * (videoTrack.naturalSize.width)
            animation.duration = 3
            animation.beginTime = CFTimeInterval(time[image])
            animation.fillMode = CAMediaTimingFillMode.forwards
            animation.isRemovedOnCompletion = false
            blackLayer.add(animation, forKey: "basic")
            
            parentlayer.addSublayer(blackLayer)
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        
        let layercomposition = AVMutableVideoComposition()
        layercomposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        layercomposition.renderSize = size
        layercomposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videolayer, in: parentlayer)
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: composition.duration)
        let videotrack = composition.tracks(withMediaType: AVMediaType.video)[0] as AVAssetTrack
        let layerinstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videotrack)
        instruction.layerInstructions = [layerinstruction]
        layercomposition.instructions = [instruction]
        
        let animatedVideoURL = NSURL(fileURLWithPath: NSHomeDirectory() + "/Documents/video2.mp4")
        removeFileAtURLIfExists(url: animatedVideoURL)
        
        guard let assetExport = AVAssetExportSession(asset: composition, presetName:AVAssetExportPresetHighestQuality) else {return}
        assetExport.videoComposition = layercomposition
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = animatedVideoURL as URL
        assetExport.exportAsynchronously(completionHandler: {
            switch assetExport.status{
            case  AVAssetExportSession.Status.failed:
                print("failed \(String(describing: assetExport.error))")
            case AVAssetExportSession.Status.cancelled:
                print("cancelled \(String(describing: assetExport.error))")
            default:
                print("Exported")
            }
        })
    }
    
}


