//
//  ScaledImageInformation.swift
//  
//
//  Created by Jonathan Lynch on 1/25/20.
//

import CoreGraphics

struct ScaledImageInformation {
    
    let image: CroppableImage
    let width: CGFloat
    let height: CGFloat
    
    func copy(scale: CGFloat) -> ScaledImageInformation {
        return ScaledImageInformation(image: image, width: width * scale, height: height * scale)
    }
}

extension ScaledImageInformation {
    init(with anImage: CroppableImage, scaleFactor: CGFloat) {
        self.init(image: anImage,
                  width: CGFloat(anImage.width) * scaleFactor,
                  height: CGFloat(anImage.height) * scaleFactor)
    }
}
