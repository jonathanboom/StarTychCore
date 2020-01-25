//
//  ImageUtils.swift
//  
//
//  Created by Jonathan Lynch on 1/23/20.
//

import CoreGraphics
import Foundation
import ImageIO

class ImageUtils {
    
    private static let alphaPremultipliedLast = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    
    static func copyImage(_ image: CGImage, maxSize: Int) -> CGImage {
        let origWidth = Float(image.width)
        let origHeight = Float(image.height)
        if origWidth <= Float(maxSize) && origHeight <= Float(maxSize) {
            return image.copy()!
        }
        
        let scaleFactor = Float(maxSize) / max(origWidth, origHeight)
        let width = Int(origWidth * scaleFactor)
        let height = Int(origHeight * scaleFactor)
        
        let canvas = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: alphaPremultipliedLast.rawValue)
        canvas?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return (canvas?.makeImage())!
    }
    
    static func averageColorComponents(for image: CGImage) -> [CGFloat] {
        // Make the raw space to draw 1 pixel, 4 bytes
        let rawData = UnsafeMutableRawPointer.allocate(byteCount: 4, alignment: 1)
        
        // Draw the image as a 1x1 pixel into a canvas (in 32-bit, big endian format)
        let canvas = CGContext(data: rawData, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: alphaPremultipliedLast.rawValue)
        canvas?.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        
        // Load the color components as Floats, then divide by maximum color value to build the component array
        let rawDataChars = rawData.load(as: [CGFloat].self)
        let comps: [CGFloat] = [
            rawDataChars[0] / 0xff,
            rawDataChars[1] / 0xff,
            rawDataChars[2] / 0xff,
            1.0 // Alpha channel
        ]
        
        rawData.deallocate()
        return comps
    }
    
    static func averageColor(image: CGImage) -> CGColor? {
        let comps: [CGFloat] = averageColorComponents(for: image)
        return CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: comps)
    }
    
    static func createImage(from source: CGImageSource, maxSize: Int) -> CGImage? {
        let metadata: NSDictionary? = CGImageSourceCopyProperties(source, nil)
        let orientation = metadata?[kCGImagePropertyOrientation] as? Int ?? 0
        
        guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        
        var width = CGFloat(image.width)
        var height = CGFloat(image.height)
        if (maxSize <= 0 || CGFloat(maxSize) > max(width, height)) && (orientation == 0 || orientation == 1) {
            return image
        }
        
        let scaleFactor = CGFloat(maxSize) / max(width, height)
        width = width * scaleFactor
        height = height * scaleFactor
        
        // Orientations 1-4 are rotated 0 or 180 degrees, so they retain width and height
        // Orientations 5-8 are rotated 90 degrees, so they swap width and height
        let canvasWidth = orientation <= 4 ? Int(width) : Int(height)
        let canvasHeight = orientation <= 4 ? Int(height) : Int(width)
        guard let canvas = CGContext(data: nil, width: canvasWidth, height: canvasHeight, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: alphaPremultipliedLast.rawValue) else {
            return nil
        }
        
        switch orientation {
        case 2:
            // Flip horizontal
            canvas.concatenate(CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: width, ty: 0))
        case 3:
            // Rotate 180 degrees
            canvas.concatenate(CGAffineTransform(a: -1, b: 0, c: 0, d: -1, tx: width, ty: height))
        case 4:
            // Flip vertical
            canvas.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: 11, tx: 0, ty: height))
        case 5:
            // Rotate -90 degrees and flip vertical
            canvas.concatenate(CGAffineTransform(a: 0, b: -1, c: -1, d: 0, tx: height, ty: width))
        case 6:
            // Rotate 90 degrees
            canvas.concatenate(CGAffineTransform(a: 0, b: -1, c: 1, d: 0, tx: 0, ty: width))
        case 7:
            // Rotate 90 degrees and flip vertical
            canvas.concatenate(CGAffineTransform(a: 0, b: 1, c: 1, d: 0, tx: 0, ty: 0))
        case 8:
            // Rotate -90 degrees
            canvas.concatenate(CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: height, ty: 0))
        default:
            // Do no transformation
            break
        }
        
        canvas.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return canvas.makeImage()
    }
}
