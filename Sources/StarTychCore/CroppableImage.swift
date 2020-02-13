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
    
    private var rawCroppedFrame: CGRect?
    private var rawRotation: Int = 0
    private var rawCroppedImage: CGImage
    private let imageCropDispatchGroup = DispatchGroup()
    private let rawValueDispatchGroup = DispatchGroup()
    
    public var rotation: Int {
        rawValueDispatchGroup.wait()
        return rawRotation
    }
    
    public var croppedFrame: CGRect? {
        rawValueDispatchGroup.wait()
        return rawCroppedFrame
    }
    
    public func set(croppedFrame: CGRect?, rotation: Int) {
        if croppedFrame == rawCroppedFrame && rotation == rawRotation {
            return
        }
        
        imageCropDispatchGroup.enter()
        setRaw(rotation: rotation)
        setRaw(croppedFrame: croppedFrame)
        
        updateCroppedImageAsync()
        imageCropDispatchGroup.leave()
    }
    
    private func setRaw(croppedFrame: CGRect?) {
        rawValueDispatchGroup.enter()
        rawCroppedFrame = croppedFrame
        
        // If the new frame is not fully contained within the original image, we will update it
        if let newFrame = croppedFrame {
            // If we're rotated at a 90, swap width and height for our frame comparison
            let originalFrame: CGRect
            switch rawRotation {
            case -90, 90:
                originalFrame = CGRect(x: 0, y: 0, width: self.originalImage.height, height: self.originalImage.width)
            default:
                originalFrame = CGRect(x: 0, y: 0, width: self.originalImage.width, height: self.originalImage.height)
            }
            
            if !originalFrame.contains(newFrame) {
                // If the new frame fully contains the original image, we aren't cropping at all
                // Otherwise, we want the intersection
                var replacementFrame: CGRect? = nil
                if !newFrame.contains(originalFrame) {
                    replacementFrame = newFrame.intersection(originalFrame)
                }
                
                rawCroppedFrame = replacementFrame
            }
        }
        
        rawValueDispatchGroup.leave()
    }
    
    private func setRaw(rotation: Int) {
        rawValueDispatchGroup.enter()
        rawRotation = rotation
        
        // Bring rotation into the -180...180 range
        while rawRotation < -180 {
            rawRotation += 360
        }
        
        while rawRotation > 180 {
            rawRotation -= 360
        }
        
        // Round down to nearest 90
        if !rawRotation.isMultiple(of: 90) {
            rawRotation -= (rawRotation % 90)
        }
        
        rawValueDispatchGroup.leave()
    }
    
    private func updateCroppedImageAsync() {
        imageCropDispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            self.rawCroppedImage = CroppableImage.cropAndRotate(image: self.originalImage, cropFrame: self.rawCroppedFrame, rotation: self.rawRotation)!
            self.imageCropDispatchGroup.leave()
        }
    }
    
    private static func cropAndRotate(image: CGImage, cropFrame: CGRect?, rotation: Int) -> CGImage? {
        var modifiedImage: CGImage?
        if rotation != 0 {
            modifiedImage = ImageUtils.imageWithRotation(image, rotation: rotation)
        } else {
            modifiedImage = image
        }
        
        if let frame = cropFrame {
            return modifiedImage?.cropping(to: frame)
        } else {
            // TODO: Should this copy or ref the original?
            return modifiedImage
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
        case rotation
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        originalImage = try container.decode(CodableCGImage.self, forKey: .image).image
        rawCroppedFrame = try container.decode(CGRect.self, forKey: .frame)
        rawRotation = try container.decode(Int.self, forKey: .rotation)
        rawCroppedImage = CroppableImage.cropAndRotate(image: originalImage, cropFrame: rawCroppedFrame, rotation: rawRotation)!
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(CodableCGImage(with: originalImage), forKey: .image)
        
        rawValueDispatchGroup.wait()
        try container.encode(rawCroppedFrame, forKey: .frame)
        try container.encode(rawRotation, forKey: .rotation)
    }
}
