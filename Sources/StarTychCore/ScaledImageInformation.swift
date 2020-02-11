//
//  ScaledImageInformation.swift
//  
//
//  Created by Jonathan Lynch on 1/25/20.
//

struct ScaledImageInformation {
    
    let image: CroppableImage
    let width: Int
    let height: Int
}

extension ScaledImageInformation {
    init(with anImage: CroppableImage, scaleFactor: Float) {
        self.init(image: anImage,
                  width: Int(Float(anImage.width) * scaleFactor),
                  height: Int(Float(anImage.height) * scaleFactor))
    }
}
