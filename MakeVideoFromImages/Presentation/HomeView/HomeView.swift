//
//  HomeView.swift
//  MakeVideoFromImages
//
//  Created by Ahmed Rajib on 7/11/22.
//

import SwiftUI
import PhotosUI
import AVKit
import Photos

struct HomeView: View {
    @State private var showImagePicker: Bool = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var image: UIImage?
    @State private var urlOfVideo: String?
    
    // MARK: - PhPicker
    @State private var selectedItems = [PhotosPickerItem]()
    @State private var selectedImages = [UIImage]()
    @ObservedObject var vm = ImagesToVideoConvert()
    @State var showingDetail = false
    
    var body: some View {
        VStack(spacing: 32) {
            
            SelectedImages(selectedImages: $selectedImages)
            
            PhotosPicker(selection: $selectedItems,maxSelectionCount: 0,matching: .any(of: [.images, .videos])) {
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
                    urlOfVideo =  vm.buildVideoFromImageArray(selectedImages: selectedImages)
                } label: {
                    Text("Make Videos")
                }
            }
            
            if !(vm.dataModel.imageArrayToVideoURL.absoluteString?.isEmpty ?? (URL(string: "") != nil)) {
                Button {
                    // MARK: - Handle Button Actions
//                    selectedImages = []
                    self.showingDetail.toggle()
                } label: {
                    Text("Show Video")
                }
                .sheet(isPresented: $showingDetail) {
                    FullScreenVideoPlayer(urlOfVideo: vm.dataModel.imageArrayToVideoURL as URL)
                }
            }
        }
    }
}

//struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeView()
//    }
//}
