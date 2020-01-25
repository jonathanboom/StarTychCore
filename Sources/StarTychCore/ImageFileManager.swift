//
//  ImageFileManager.swift
//  
//
//  Created by Jonathan Lynch on 1/25/20.
//

import CoreGraphics
import CoreServices
import Foundation
import ImageIO

class ImageFileManager {
    static func createCGImage(from url: URL) -> CGImage? {
        return createCGImage(from: url, maxSize: 0)
    }
    
    static func createCGImage(from url: URL, maxSize: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as NSURL as CFURL, nil) else {
            return nil
        }
        
        if CGImageSourceGetStatusAtIndex(source, 0) == .statusInvalidData {
            return nil
        }
        
        return ImageUtils.createImage(from: source, maxSize: maxSize)
    }
    
    static func write(image: CGImage, to url: URL) {
        // Default to TIFF
        var utType = kUTTypeTIFF
        
        // If the URL extension is an image type, use that instead
        let urlExtension = url.pathExtension as NSString as CFString
        if let urlUtType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, urlExtension, nil)?.takeRetainedValue() {
            if UTTypeConformsTo(urlUtType, kUTTypeImage) {
                utType = urlUtType
            }
        }
        
        write(image: image, to: url, utType: utType)
    }
    
    static func write(image: CGImage, to url: URL, utType: CFString) {
        guard let output = CGImageDestinationCreateWithURL(url as NSURL as CFURL, utType, 1, nil) else {
            return
        }
        
        CGImageDestinationAddImage(output, image, nil)
        CGImageDestinationFinalize(output)
    }
}
