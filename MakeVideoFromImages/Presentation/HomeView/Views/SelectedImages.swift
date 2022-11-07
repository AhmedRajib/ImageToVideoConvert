//
//  SelectedImages.swift
//  MakeVideoFromImages
//
//  Created by Ahmed Rajib on 7/11/22.
//

import SwiftUI

struct SelectedImages: View {
    @Binding var selectedImages: [UIImage]
    
    var body: some View {
        VStack {
            if selectedImages.count > 0 {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(selectedImages,id: \.self) {
                            Image(uiImage: $0)
                                .resizable()
                                .frame(width: 200,height: 200)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }else {
                Image(systemName: "video.slash")
                    .resizable()
                    .frame(width: 200,height: 200)
                    .foregroundColor(.gray.opacity(0.2))
                    .padding()
            }
        }
    }
}

//struct SelectedImages_Previews: PreviewProvider {
//    static var previews: some View {
//        SelectedImages()
//    }
//}
