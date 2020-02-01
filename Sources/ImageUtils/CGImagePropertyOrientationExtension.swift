//
//  CGImagePropertyOrientationExtension.swift
//  
//
//  Created by Jonathan Lynch on 2/1/20.
//

import ImageIO
import UIKit

// Simple extension to map UIImage.Orientation to CGImagePropertyOrientation
public extension CGImagePropertyOrientation {
    init(uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up:
            self = .up
        case .upMirrored:
            self = .upMirrored
        case .down:
            self = .down
        case .downMirrored:
            self = .downMirrored
        case .left:
            self = .left
        case .leftMirrored:
            self = .leftMirrored
        case .right:
            self = .right
        case .rightMirrored:
            self = .rightMirrored
        default:
            self = .up
        }
    }
}
