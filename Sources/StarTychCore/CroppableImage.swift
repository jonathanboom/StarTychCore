//
//  CroppableImage.swift
//  
//
//  Created by Jonathan Lynch on 2/8/20.
//

import CoreGraphics
import ImageUtils

class CroppableImage: Codable {
    
    let originalImage: CGImage
    var croppedFrame: CGRect? {
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
                    self.croppedImage = self.originalImage.cropping(to: frame)!
                } else {
                    self.croppedImage = self.originalImage
                }
                pthread_rwlock_unlock(&self.croppingLock)
            }
        }
    }
    
    private var croppedImage: CGImage
    private var croppingLock = pthread_rwlock_t()
    
    init(image: CGImage) {
        originalImage = image
        croppedImage = image
        pthread_rwlock_init(&croppingLock, nil)
    }
    
    private enum CodingKeys: CodingKey {
        case image
        case frame
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        originalImage = try container.decode(CodableCGImage.self, forKey: .image).image
        croppedImage = originalImage
        croppedFrame = try container.decode(CGRect.self, forKey: .frame)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(CodableCGImage(with: originalImage), forKey: .image)
        try container.encode(croppedFrame, forKey: .frame)
    }
    
    public func width() -> CGFloat {
        if let frame = croppedFrame {
            return frame.width
        } else {
            return CGFloat(originalImage.width)
        }
    }
    
    public func height() -> CGFloat {
        if let frame = croppedFrame {
            return frame.height
        } else {
            return CGFloat(originalImage.height)
        }
    }
    
    func getCroppedFullImage() -> CGImage? {
        pthread_rwlock_rdlock(&croppingLock)
        let returnImage = croppedImage
        pthread_rwlock_unlock(&croppingLock)
        return returnImage
    }
    
    func getCroppedImage(maxSize: Int) -> CGImage? {
        pthread_rwlock_rdlock(&croppingLock)
        let returnImage = ImageUtils.copyImage(croppedImage, maxSize: maxSize)
        pthread_rwlock_unlock(&croppingLock)
        return returnImage
    }
}
