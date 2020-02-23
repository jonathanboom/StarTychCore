//
//  ScaledImageInformation.swift
//  
//
//  Created by Jonathan Lynch on 1/25/20.
//

import CoreGraphics

struct ScaledImageInformation {
    
    let image: CroppableImage
    let size: CGSize
    let origin: CGPoint
    
    static func scaledImageSize(image: CroppableImage, scaleFactor: Float) -> CGSize {
        return CGSize(width: Int(Float(image.width) * scaleFactor),
                      height: Int(Float(image.height) * scaleFactor))
    }
}
