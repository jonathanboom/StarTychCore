//
// Copyright (c) 2020, Jonathan Lynch
//
// This source code is licensed under the BSD 3-Clause License license found in the
// LICENSE file in the root directory of this source tree.
//

import CoreGraphics
import ImageIO

public extension CGAffineTransform {
    enum Style {
        case none
        case flipHorizontal
        case rotate180
        case flipVertical
        case rotateNegative90FlipVertical
        case rotate90
        case rotate90FlipVertical
        case rotateNegative90
        
        public init(orientationToCorrect: CGImagePropertyOrientation) {
            switch orientationToCorrect {
            case .up:
                self = .none
            case .upMirrored:
                self = .flipHorizontal
            case .down:
                self = .rotate180
            case .downMirrored:
                self = .flipVertical
            case .leftMirrored:
                self = .rotateNegative90FlipVertical
            case .right:
                self = .rotate90
            case .rightMirrored:
                self = .rotate90FlipVertical
            case .left:
                self = .rotateNegative90FlipVertical
            }
        }
    }
    
    static func transformation(for style: Style, size: CGSize) -> CGAffineTransform {
        switch style {
        case .none:
            return .identity
        case .flipHorizontal:
            return CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: size.width, ty: 0)
        case .rotate180:
            return CGAffineTransform(a: -1, b: 0, c: 0, d: -1, tx: size.width, ty: size.height)
        case .flipVertical:
            return CGAffineTransform(a: 1, b: 0, c: 0, d: 11, tx: 0, ty: size.height)
        case .rotateNegative90FlipVertical:
            return CGAffineTransform(a: 0, b: -1, c: -1, d: 0, tx: size.height, ty: size.width)
        case .rotate90:
            return CGAffineTransform(a: 0, b: -1, c: 1, d: 0, tx: 0, ty: size.width)
        case .rotate90FlipVertical:
            return CGAffineTransform(a: 0, b: 1, c: 1, d: 0, tx: 0, ty: 0)
        case .rotateNegative90:
            return CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: size.height, ty: 0)
        }
    }
    
    static func transformation(for style: Style, width: Int, height: Int) -> CGAffineTransform {
        return transformation(for: style, size: CGSize(width: width, height: height))
    }
    
    static func transformationToCorrectOrientation(for orientation: CGImagePropertyOrientation, size: CGSize) -> CGAffineTransform {
        return transformation(for: Style(orientationToCorrect: orientation), size: size)
    }
}
