//
//  ImageUtils.swift
//  
//
//  Created by Jonathan Lynch on 1/23/20.
//

import CoreImage

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
        let rawData = malloc(4)
        
        // Draw the image as a 1x1 pixel into a canvas (in 32-bit, big endian format)
        let canvas = CGContext(data: rawData, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: alphaPremultipliedLast.rawValue)
        canvas?.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        
        // Load the color components as Floats, then divide by maximum color value to build the component array
        let rawDataChars = rawData?.load(as: [CGFloat].self)
        let comps: [CGFloat] = [
            (rawDataChars?[0])! / 0xff,
            (rawDataChars?[1])! / 0xff,
            (rawDataChars?[2])! / 0xff,
            1.0 // Alpha channel
        ]
        
        free(rawData)
        return comps
    }
    
    static func averageColor(image: CGImage) -> CGColor? {
        let comps: [CGFloat] = averageColorComponents(for: image)
        return CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: comps)
    }
}
