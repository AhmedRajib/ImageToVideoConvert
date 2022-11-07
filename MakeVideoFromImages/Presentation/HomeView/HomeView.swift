//
//  HomeView.swift
//  MakeVideoFromImages
//
//  Created by Ahmed Rajib on 7/11/22.
//

import SwiftUI
import PhotosUI

struct HomeView: View {
    @State private var showImagePicker: Bool = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var image: UIImage?
    
     // MARK: - PhPicker
    @State private var selectedItems = [PhotosPickerItem]()
    @State private var selectedImages = [UIImage]()

    var body: some View {
        VStack(spacing: 32) {
            
            SelectedImages(selectedImages: $selectedImages)
            
            PhotosPicker(selection: $selectedItems,maxSelectionCount: 2,matching: .any(of: [.images, .videos])) {
                Label(selectedImages.count > 0 ? "Make Video" : "Select ImagesFor Making Video" , image: "photo.artframe")
            }
            .onChange(of: selectedItems) { newValues in
                Task {
                    selectedItems = []
                    for image in newValues {
                        if let imageData = try? await image.loadTransferable(type: Data.self), let image = UIImage(data: imageData) {
                            selectedImages.append(image)
                        }
                    }
                    ImagesToVideoConvert().buildVideoFromImageArray(selectedImages: selectedImages)
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
