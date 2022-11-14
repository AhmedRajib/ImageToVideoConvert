//
//  HomeView.swift
//  MakeVideoFromImages
//
//  Created by Ahmed Rajib on 7/11/22.
//

import SwiftUI
import PhotosUI
import AVKit
struct HomeView: View {
    @State private var showImagePicker: Bool = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var image: UIImage?
    @State private var urlOfVideo: String?
    
     // MARK: - PhPicker
    @State private var selectedItems = [PhotosPickerItem]()
    @State private var selectedImages = [UIImage]()

    var body: some View {
        VStack(spacing: 32) {
            
            SelectedImages(selectedImages: $selectedImages)
            
            PhotosPicker(selection: $selectedItems,maxSelectionCount: 3,matching: .any(of: [.images, .videos])) {
                Label(selectedImages.count > 0 ? "Change Images?" : "Select ImagesFor Making Video" , image: "photo.artframe")
            }
            .onChange(of: selectedItems) { newValues in
                Task {
                    selectedItems = []
                    for image in newValues {
                        if let imageData = try? await image.loadTransferable(type: Data.self), let image = UIImage(data: imageData) {
                            selectedImages.append(image)
                        }
                    }
                    
                }
            }
            
            Spacer()
            
            if selectedImages.count > 0 {
                Button {
                    // MARK: - Handle Button Actions
                  urlOfVideo =  ImagesToVideoConvert().buildVideoFromImageArray(selectedImages: selectedImages)
                    
                   
                  
                } label: {
                    Text("Make Videos")
                }
            }
            
            if let urlOfVideo {
                VideoPlayer(player: AVPlayer(url:  URL(string: "Documents/video1.MP4")!))
                    .frame(height: 400)
//                PlayVideo()
//                debugPrint("URL OF videos ", urlOfVideo)
            }

        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
