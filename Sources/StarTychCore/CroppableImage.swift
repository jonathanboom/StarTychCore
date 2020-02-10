//
//  CroppableImage.swift
//  
//
//  Created by Jonathan Lynch on 2/8/20.
//

import CoreGraphics
import ImageUtils

class CroppableImage: Codable {
    
    public let originalImage: CGImage
    public var croppedFrame: CGRect? {
        didSet {
            if croppedFrame == oldValue {
                return
            }
            
            if let newFrame = croppedFrame {
                let ogWidth = CGFloat(originalImage.width)
                let ogHeight = CGFloat(originalImage.height)
                
                // Make sure we don't make a frame that's larger than the image's true size
//                if newFrame.width > ogWidth || newFrame.height > ogHeight || newFrame.width < 1 || newFrame.height < 1 {
//
//                }
                
                
                if newFrame.width > ogWidth && newFrame.height > ogHeight {
                    croppedFrame = nil
                } else if newFrame.width > ogWidth {
                    croppedFrame = CGRect(x: 0, y: newFrame.origin.y, width: ogWidth, height: newFrame.height)
                } else if newFrame.height > ogHeight {
                    croppedFrame = CGRect(x: newFrame.origin.x, y: 0, width: newFrame.width, height: ogHeight)
                }
            }
            
            pthread_rwlock_wrlock(&croppingLock)
            DispatchQueue.global().async {
                if let frame = self.croppedFrame {
                    self.rawCroppedImage = self.originalImage.cropping(to: frame)!
                } else {
                    // TODO: Should this copy or ref the original?
                    self.rawCroppedImage = self.originalImage
                }
                pthread_rwlock_unlock(&self.croppingLock)
            }
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
    
    private var rawCroppedImage: CGImage
    private var croppingLock = pthread_rwlock_t()
    
    public var croppedImage: CGImage {
        pthread_rwlock_rdlock(&croppingLock)
        let image = rawCroppedImage
        pthread_rwlock_unlock(&croppingLock)
        return image
    }
    
    public init(image: CGImage) {
        pthread_rwlock_init(&croppingLock, nil)
        originalImage = image
        
        // TODO: Should this copy or ref the original?
        rawCroppedImage = image
    }
    
    deinit {
        pthread_rwlock_destroy(&croppingLock)
    }
    
    private enum CodingKeys: CodingKey {
        case image
        case frame
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        originalImage = try container.decode(CodableCGImage.self, forKey: .image).image
        rawCroppedImage = originalImage
        croppedFrame = try container.decode(CGRect.self, forKey: .frame)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(CodableCGImage(with: originalImage), forKey: .image)
        try container.encode(croppedFrame, forKey: .frame)
    }
}
