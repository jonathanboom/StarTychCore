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
    
    public static func copyImage(_ image: CGImage, maxSize: Int) -> CGImage? {
        let origWidth = Float(image.width)
        let origHeight = Float(image.height)
        if origWidth <= Float(maxSize) && origHeight <= Float(maxSize) {
            return image.copy()!
        }
        
        let scaleFactor = Float(maxSize) / max(origWidth, origHeight)
        let width = Int(origWidth * scaleFactor)
        let height = Int(origHeight * scaleFactor)
        
        let colorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        let canvas = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: alphaPremultipliedLast.rawValue)
        canvas?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return canvas?.makeImage()
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
        
        return drawImage(image, size: CGSize(width: width, height: height), orientation: orientation)
    }
    
    public static func imageWithRotation(_ image: CGImage, rotation: Int) -> CGImage? {
        if rotation % 360 == 0 {
            return image
        }
        
        let canvasWidth: Int
        let canvasHeight: Int
        let transform: CGAffineTransform
        
        // Rotations of 90 and -90 swap width and height for canvas
        switch rotation {
        case 90, -270:
            canvasWidth = image.height
            canvasHeight = image.width
            transform = CGAffineTransform.transformation(for: .rotate90, width: image.width, height: image.height)
        case 270, -90:
            canvasWidth = image.height
            canvasHeight = image.width
            transform = CGAffineTransform.transformation(for: .rotateNegative90, width: image.width, height: image.height)
        case 180, -180:
            canvasWidth = image.width
            canvasHeight = image.height
            transform = CGAffineTransform.transformation(for: .rotate180, width: image.width, height: image.height)
        default:
            canvasWidth = image.width
            canvasHeight = image.height
            transform = .identity
        }
        
        let colorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        let canvas = CGContext(data: nil, width: canvasWidth, height: canvasHeight, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: alphaPremultipliedLast.rawValue)

        canvas?.concatenate(transform)
        canvas?.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return canvas?.makeImage()
    }
    
    public static func imageWithCorrectedOrientation(_ image: CGImage, orientation: CGImagePropertyOrientation) -> CGImage? {
        if orientation == .up {
            return image
        }
        
        return drawImage(image, size: CGSize(width: image.width, height: image.height), orientation: orientation)
    }
    
    private static func drawImage(_ image: CGImage, size: CGSize, orientation: CGImagePropertyOrientation) -> CGImage? {
        let canvasWidth: Int
        let canvasHeight: Int
        switch orientation {
        case .leftMirrored, .right, .rightMirrored, .left:
            // Left and right orientations are rotated 90 degrees, so they swap width and height
            canvasWidth = Int(size.height)
            canvasHeight = Int(size.width)
        default:
            // All other orientations retain width and height
            canvasWidth = Int(size.width)
            canvasHeight = Int(size.height)
        }
        
        guard let canvas = CGContext(data: nil, width: canvasWidth, height: canvasHeight, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: alphaPremultipliedLast.rawValue) else {
            return nil
        }
        
        canvas.concatenate(CGAffineTransform.transformationToCorrectOrientation(for: orientation, size: size))
        canvas.draw(image, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
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
}
