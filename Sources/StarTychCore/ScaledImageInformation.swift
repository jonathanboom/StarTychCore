//
// Copyright (c) 2020, Jonathan Lynch
//
// This source code is licensed under the BSD 3-Clause License license found in the
// LICENSE file in the root directory of this source tree.
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
