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
    private let readWriteQueue = DispatchQueue(label: "com.IntuitiveSoup.StarTych.CroppableImage.concurrentQueue",
                                               qos: .userInitiated,
                                               attributes: .concurrent)
    
    public var croppedFrame: CGRect? {
        didSet {
            // Updating the frame blocks reads to the croppedImage
            readWriteQueue.sync(flags: .barrier) {
                if self.croppedFrame == oldValue {
                    return
                }
                
                if let newFrame = self.croppedFrame {
                    let ogWidth = CGFloat(self.originalImage.width)
                    let ogHeight = CGFloat(self.originalImage.height)
                    
                    // Make sure we don't make a frame that's larger than the image's true size
//                    if newFrame.width > ogWidth || newFrame.height > ogHeight || newFrame.width < 1 || newFrame.height < 1 {
//
//                    }
                    
                    if newFrame.width > ogWidth && newFrame.height > ogHeight {
                        self.croppedFrame = nil
                    } else if newFrame.width > ogWidth {
                        self.croppedFrame = CGRect(x: 0, y: newFrame.origin.y, width: ogWidth, height: newFrame.height)
                    } else if newFrame.height > ogHeight {
                        self.croppedFrame = CGRect(x: newFrame.origin.x, y: 0, width: newFrame.width, height: ogHeight)
                    }
                }
                
                // Update the rawCroppedImage async
                readWriteQueue.async(flags: .barrier) {
                    if let frame = self.croppedFrame {
                        self.rawCroppedImage = self.originalImage.cropping(to: frame)!
                    } else {
                        // TODO: Should this copy or ref the original?
                        self.rawCroppedImage = self.originalImage
                    }
                }
            }
        }
    }
    
    public var croppedImage: CGImage {
        return readWriteQueue.sync {
            return self.rawCroppedImage
        }
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
