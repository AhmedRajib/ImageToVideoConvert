//
//  mergeImageTwoVideo.swift
//  MakeVideoFromImages
//
//  Created by MacBook Pro on 9/11/22.
//

import Foundation
import AVFoundation
import UIKit

func writeImagesAsMovie(allImages: [UIImage], videoPath: String, videoSize: CGSize, videoFPS: Int32) {
    // Create AVAssetWriter to write video
    guard let assetWriter = createAssetWriter(path: videoPath, size: videoSize) else {
        print("Error converting images to video: AVAssetWriter not created")
        return
    }

    // If here, AVAssetWriter exists so create AVAssetWriterInputPixelBufferAdaptor
    let writerInput = assetWriter.inputs.filter{ $0.mediaType == AVMediaType.video }.first!
    let sourceBufferAttributes : [String : AnyObject] = [
        kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32ARGB),
        kCVPixelBufferWidthKey as String : videoSize.width,
        kCVPixelBufferHeightKey as String : videoSize.height,
        ]
    let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourceBufferAttributes)

    // Start writing session
    assetWriter.startWriting()
    assetWriter.startSession(atSourceTime: CMTime.zero)
    if (pixelBufferAdaptor.pixelBufferPool == nil) {
        print("Error converting images to video: pixelBufferPool nil after starting session")
        return
    }

    // -- Create queue for <requestMediaDataWhenReadyOnQueue>
    let mediaQueue = DispatchQueue("mediaInputQueue", nil)

    // -- Set video parameters
    let frameDuration = CMTimeMake(1, videoFPS)
    var frameCount = 0

    // -- Add images to video
    let numImages = allImages.count
    writerInput.requestMediaDataWhenReadyOnQueue(mediaQueue, usingBlock: { () -> Void in
        // Append unadded images to video but only while input ready
        while (writerInput.readyForMoreMediaData && frameCount < numImages) {
            let lastFrameTime = CMTimeMake(Int64(frameCount), videoFPS)
            let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)

            if !self.appendPixelBufferForImageAtURL(allImages[frameCount], pixelBufferAdaptor: pixelBufferAdaptor, presentationTime: presentationTime) {
                print("Error converting images to video: AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer")
                return
            }

            frameCount += 1
        }

        // No more images to add? End video.
        if (frameCount >= numImages) {
            writerInput.markAsFinished()
            assetWriter.finishWritingWithCompletionHandler {
                if (assetWriter.error != nil) {
                    print("Error converting images to video: \(assetWriter.error)")
                } else {
                    self.saveVideoToLibrary(NSURL(fileURLWithPath: videoPath))
                    print("Converted images to movie @ \(videoPath)")
                }
            }
        }
    })
}


func createAssetWriter(path: String, size: CGSize) -> AVAssetWriter? {
    // Convert <path> to NSURL object
    let pathURL = NSURL(fileURLWithPath: path)

    // Return new asset writer or nil
    do {
        // Create asset writer
        let newWriter = try AVAssetWriter(URL: pathURL, fileType: AVFileTypeMPEG4)

        // Define settings for video input
        let videoSettings: [String : AnyObject] = [
            AVVideoCodecKey  : AVVideoCodecH264,
            AVVideoWidthKey  : size.width,
            AVVideoHeightKey : size.height,
            ]

        // Add video input to writer
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
        newWriter.addInput(assetWriterVideoInput)

        // Return writer
        print("Created asset writer for \(size.width)x\(size.height) video")
        return newWriter
    } catch {
        print("Error creating asset writer: \(error)")
        return nil
    }
}


func appendPixelBufferForImageAtURL(image: UIImage, pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor, presentationTime: CMTime) -> Bool {
    var appendSucceeded = false

    autoreleasepool {
        if  let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool {
            let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.alloc(1)
            let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(
                kCFAllocatorDefault,
                pixelBufferPool,
                pixelBufferPointer
            )

            if let pixelBuffer = pixelBufferPointer.memory where status == 0 {
                fillPixelBufferFromImage(image, pixelBuffer: pixelBuffer)
                appendSucceeded = pixelBufferAdaptor.appendPixelBuffer(pixelBuffer, withPresentationTime: presentationTime)
                pixelBufferPointer.destroy()
            } else {
                NSLog("Error: Failed to allocate pixel buffer from pool")
            }

            pixelBufferPointer.dealloc(1)
        }
    }

    return appendSucceeded
}


func fillPixelBufferFromImage(image: UIImage, pixelBuffer: CVPixelBufferRef) {
    CVPixelBufferLockBaseAddress(pixelBuffer, 0)

    let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()

    // Create CGBitmapContext
    let context = CGBitmapContextCreate(
        pixelData,
        Int(image.size.width),
        Int(image.size.height),
        8,
        CVPixelBufferGetBytesPerRow(pixelBuffer),
        rgbColorSpace,
        CGImageAlphaInfo.PremultipliedFirst.rawValue
    )

    // Draw image into context
    CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage)

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0)
}


func saveVideoToLibrary(videoURL: NSURL) {
    PHPhotoLibrary.requestAuthorization { status in
        // Return if unauthorized
        guard status == .Authorized else {
            print("Error saving video: unauthorized access")
            return
        }

        // If here, save video to library
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(videoURL)
        }) { success, error in
            if !success {
                print("Error saving video: \(error)")
            }
        }
    }
}
