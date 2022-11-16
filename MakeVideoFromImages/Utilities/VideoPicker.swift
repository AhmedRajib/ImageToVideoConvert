////
////  mergeImageTwoVideo.swift
////  MakeVideoFromImages
////
////  Created by MacBook Pro on 9/11/22.
////
//
import Foundation
import AVFoundation
import UIKit
import SwiftUI
import PhotosUI

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var videoURL: [String]?
    @Binding var selectedImages: [UIImage]
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        
        var config = PHPickerConfiguration()
        config.filter = .any(of: [.videos, .images])
        config.selectionLimit = 0
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator:NSObject, PHPickerViewControllerDelegate{
        
        let parent:VideoPicker
        init(_ parent: VideoPicker){
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            
            picker.dismiss(animated: true) {
                // do something on dismiss
            }
            
            
            
            guard let provider = results.first?.itemProvider else {return}
            let movie = UTType.movie.identifier
            provider.loadFileRepresentation(forTypeIdentifier: movie) { url, error in
                
                guard let url = url else {return}
                
                self.parent.videoURL?.append(url.absoluteString)
                print("Video URl ",url)
                print(FileManager.default.fileExists(atPath: url.path))
                
            }
            
//            guard let provider = results.first?.itemProvider else { return }

//            if provider.canLoadObject(ofClass: UIImage.self) {
//                provider.loadObject(ofClass: UIImage.self) { image, _ in
//                    self.parent.selectedImages.append(image ?? UIImage())
//                }
//            }
            
            let imageItems = results
                    .map { $0.itemProvider }
                    .filter { $0.canLoadObject(ofClass: UIImage.self) }
            
            let dispatchGroup = DispatchGroup()
//                var images = [UIImage]()
                
                for imageItem in imageItems {
                    dispatchGroup.enter() // signal IN
                    
                    imageItem.loadObject(ofClass: UIImage.self) { image, _ in
                        if let image = image as? UIImage {
                            self.parent.selectedImages.append(image)
                        }
                        dispatchGroup.leave() // signal OUT
                    }
                }
                
            
        }
    }
}
