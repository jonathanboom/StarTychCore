//
//  CodableCGImage.swift
//  
//
//  Created by Jonathan Lynch on 1/23/20.
//

import CoreGraphics
import CoreServices
import Foundation
import ImageIO

struct CodableCGImage: Codable {
    let image: CGImage
    
    init(with anImage: CGImage) {
        image = anImage
    }
    
    enum CodingKeys: CodingKey {
        case imageData
    }
    
    func encode(to encoder: Encoder) throws {
        guard let imageData = CFDataCreateMutable(kCFAllocatorDefault, 0) else {
            throw EncodingError.invalidValue(image, EncodingError.Context(codingPath: [CodingKeys.imageData], debugDescription: "Could not create CFMutableData while encoding CGImage"))
        }
        
        guard let imageDestination = CGImageDestinationCreateWithData(imageData, kUTTypePNG, 1, nil) else {
            throw EncodingError.invalidValue(image, EncodingError.Context(codingPath: [CodingKeys.imageData], debugDescription: "Could not create CGImageDestination while encoding CGImage"))
        }
        
        CGImageDestinationAddImage(imageDestination, image, nil)
        CGImageDestinationFinalize(imageDestination)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(imageData as Data, forKey: .imageData)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let imageData = try container.decode(Data.self, forKey: .imageData)
        
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [CodingKeys.imageData], debugDescription: "Could not create CGImageSource from decoded data"))
        }
        
        guard let decodedImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [CodingKeys.imageData], debugDescription: "Could not create CGImage from decoded CGImageSource"))
        }
        
        image = decodedImage
    }
}
