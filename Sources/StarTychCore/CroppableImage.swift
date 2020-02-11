//
//  CroppableImage.swift
//  
//
//  Created by Jonathan Lynch on 2/8/20.
//

import CoreGraphics
import ImageIO
import ImageUtils

public class CroppableImage: Codable {
    
    public let originalImage: CGImage
    
    private var rawCroppedImage: CGImage
    private let imageCropDispatchGroup = DispatchGroup()
    
    public var croppedFrame: CGRect? {
        didSet {
            // Updating the frame blocks reads to croppedImage
            if self.croppedFrame == oldValue {
                return
            }
                
            imageCropDispatchGroup.enter()
            if let newFrame = self.croppedFrame {
                // If the new frame is not fully contained within the original image, we will update it
                let originalFrame = CGRect(x: 0, y: 0, width: self.originalImage.width, height: self.originalImage.height)
                if !originalFrame.contains(newFrame) {
                    // If the new frame fully contains the original image, we aren't cropping at all
                    // Otherwise, we want the intersection
                    var replacementFrame: CGRect? = nil
                    if !newFrame.contains(originalFrame) {
                        replacementFrame = newFrame.intersection(originalFrame)
                    }
                    
                    self.croppedFrame = replacementFrame
                }
            }
            
            imageCropDispatchGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                if let frame = self.croppedFrame {
                    self.rawCroppedImage = self.originalImage.cropping(to: frame)!
                } else {
                    // TODO: Should this copy or ref the original?
                    self.rawCroppedImage = self.originalImage
                }
                self.imageCropDispatchGroup.leave()
            }
            
            imageCropDispatchGroup.leave()
        }
    }
    
    public var croppedImage: CGImage {
        imageCropDispatchGroup.wait()
        return rawCroppedImage
    }
    
    public var width: Int {
        if let frame = self.croppedFrame {
            return Int(frame.width)
        } else {
            return self.originalImage.width
        }
    }
    
    public var height: Int {
        if let frame = self.croppedFrame {
            return Int(frame.height)
        } else {
            return self.originalImage.height
        }
    }
    
    public init(image: CGImage, orientation: CGImagePropertyOrientation = .up) {
        originalImage = ImageUtils.imageWithCorrectedOrientation(image, orientation: orientation)!
        
        // TODO: Should this copy or ref the original?
        rawCroppedImage = originalImage
    }
    
    private enum CodingKeys: CodingKey {
        case image
        case frame
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        originalImage = try container.decode(CodableCGImage.self, forKey: .image).image
        croppedFrame = try container.decode(CGRect.self, forKey: .frame)
        if let frame = croppedFrame {
            rawCroppedImage = originalImage.cropping(to: frame)!
        } else {
            // TODO: Should this copy or ref the original?
            rawCroppedImage = originalImage
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(CodableCGImage(with: originalImage), forKey: .image)
        try container.encode(croppedFrame, forKey: .frame)
    }
}
