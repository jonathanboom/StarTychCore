//
//  ScaledImageInformation.swift
//  
//
//  Created by Jonathan Lynch on 1/25/20.
//

import CoreGraphics

struct ScaledImageInformation {
    
    let image: CGImage
    let width: Int
    let height: Int
    
    init(with anImage: CGImage, scaleFactor: Float) {
        image = anImage
        width = Int(Float(image.width) * scaleFactor)
        height = Int(Float(image.height) * scaleFactor)
    }
}
