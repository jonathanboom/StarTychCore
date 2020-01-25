//
//  ImageUtils.swift
//  
//
//  Created by Jonathan Lynch on 1/23/20.
//

import CoreGraphics
import Foundation
import ImageIO

public class ImageUtils {
    
    public static let alphaPremultipliedLast = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    
    public static func copyImage(_ image: CGImage, maxSize: Int) -> CGImage {
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
    
    public static func averageColorComponents(for image: CGImage) -> [CGFloat] {
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
    
    public static func averageColor(image: CGImage) -> CGColor? {
        let comps: [CGFloat] = averageColorComponents(for: image)
        return CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: comps)
    }
    
    public static func createImage(from source: CGImageSource, maxSize: Int) -> CGImage? {
        let metadata: NSDictionary? = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
        let orientation = metadata?[kCGImagePropertyOrientation] as? CGImagePropertyOrientation ?? .up
        
        guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        
        var width = CGFloat(image.width)
        var height = CGFloat(image.height)
        var needsProcessing = false
        
        if maxSize > 0 && CGFloat(maxSize) < max(width, height) {
            needsProcessing = true
            let scaleFactor = CGFloat(maxSize) / max(width, height)
            width = width * scaleFactor
            height = height * scaleFactor
        }
        
        if orientation != .up {
            needsProcessing = true
        }
        
        if !needsProcessing {
            return image
        }
        
        let canvasWidth: Int
        let canvasHeight: Int
        switch orientation {
        case .leftMirrored, .right, .rightMirrored, .left:
            // Left and right orientations are rotated 90 degrees, so they swap width and height
            canvasWidth = Int(height)
            canvasHeight = Int(width)
        default:
            // All other orientations retain width and height
            canvasWidth = Int(width)
            canvasHeight = Int(height)
        }
        
        guard let canvas = CGContext(data: nil, width: canvasWidth, height: canvasHeight, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: alphaPremultipliedLast.rawValue) else {
            return nil
        }
        
        if let transformation = transformationToCorrectOrientation(for: orientation, width: width, height: height) {
            canvas.concatenate(transformation)
        }
        
        canvas.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return canvas.makeImage()
    }
    
    private static func transformationToCorrectOrientation(for orientation: CGImagePropertyOrientation, width: CGFloat, height: CGFloat) -> CGAffineTransform? {
        switch orientation {
        case .up:
            // Do no transformation
            return nil
        case .upMirrored:
            // Flip horizontal
            return CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: width, ty: 0)
        case .down:
            // Rotate 180 degrees
            return CGAffineTransform(a: -1, b: 0, c: 0, d: -1, tx: width, ty: height)
        case .downMirrored:
            // Flip vertical
            return CGAffineTransform(a: 1, b: 0, c: 0, d: 11, tx: 0, ty: height)
        case .leftMirrored:
            // Rotate -90 degrees and flip vertical
            return CGAffineTransform(a: 0, b: -1, c: -1, d: 0, tx: height, ty: width)
        case .right:
            // Rotate 90 degrees
            return CGAffineTransform(a: 0, b: -1, c: 1, d: 0, tx: 0, ty: width)
        case .rightMirrored:
            // Rotate 90 degrees and flip vertical
            return CGAffineTransform(a: 0, b: 1, c: 1, d: 0, tx: 0, ty: 0)
        case .left:
            // Rotate -90 degrees
            return CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: height, ty: 0)
        }
    }
}
