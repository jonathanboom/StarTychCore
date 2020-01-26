//
//  ImageUtils.swift
//  
//
//  Created by Jonathan Lynch on 1/23/20.
//

import CoreGraphics
import CoreServices
import Foundation
import ImageIO
import ObjectiveCHelpers

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
    
    public static func fileIsImage(at url: URL) -> Bool {
        let urlExtension = url.pathExtension as NSString as CFString
        if let urlUtType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, urlExtension, nil)?.takeRetainedValue() {
            if UTTypeConformsTo(urlUtType, kUTTypeImage) {
                return true
            }
        }
        return false
    }
    
    public static func averageColorComponents(for image: CGImage) -> [CGFloat] {
        return AverageColorUtil.averageColorComponents(for: image).map { CGFloat($0.floatValue) }
    }
    
    public static func averageColor(image: CGImage) -> CGColor? {
        let components: [CGFloat] = averageColorComponents(for: image)
        return CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: components)
    }
    
    public static func createImage(from source: CGImageSource, maxSize: Int) -> CGImage? {
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
        
        let orientation = getOrientation(of: source)
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
    
    private static func getOrientation(of source: CGImageSource) -> CGImagePropertyOrientation {
        let metadata: NSDictionary? = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
        if let orientationRaw = metadata?[kCGImagePropertyOrientation] as? UInt32,
            let orientation = CGImagePropertyOrientation(rawValue: orientationRaw) {
            return orientation
        }
        
        // If we cannot determine the orientation we use .up, which is the identity value and means that the image is
        // "right side up"
        return .up
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
