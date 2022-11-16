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
    @State private var videoURL: [String]?
    @ObservedObject var vm = ImagesToVideoConvert()
    @State var showGallery: Bool = false
    @State var showingDetail = false
    
    var body: some View {
        VStack(spacing: 32) {
            
            SelectedImages(selectedImages: $selectedImages)
            
            Button {
                showGallery = true
            } label: {
                Text("Upload images")
                    .frame(width: 150,height: 40)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
            .fullScreenCover(isPresented: $showGallery) {
                VideoPicker(videoURL: $videoURL,selectedImages: $selectedImages)
            }
            
            Spacer()
            
            if selectedImages.count > 0 {
                Button {
                    // MARK: - Handle Button Actions
                    urlOfVideo =  vm.buildVideoFromImageArray(selectedImages: selectedImages)
                } label: {
                    Text("Make Video")
                        .frame(width: 150,height: 40)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)

                }
            }
            
            if !(vm.dataModel.imageArrayToVideoURL.absoluteString?.isEmpty ?? (URL(string: "") != nil)) {
                Button {
                    // MARK: - Handle Button Actions
                    self.showingDetail.toggle()
                } label: {
                    Text("Show Video")
                        .frame(width: 150,height: 40)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)

                }
                .sheet(isPresented: $showingDetail) {
                    FullScreenVideoPlayer(urlOfVideo: vm.dataModel.imageArrayToVideoURL as URL)
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
