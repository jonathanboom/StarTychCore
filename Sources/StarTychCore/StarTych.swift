//
//  StarTych.swift
//  
//
//  Created by Jonathan Lynch on 1/23/20.
//

import CoreGraphics

class StarTych: Codable {
    var isOrientationSwapped = false
    var outerBorderWeight: Float
    var innerBorderWeight: Float
    var borderColor: CGColor
    var images = [CGImage]()
    
    // Need to invalidate this cache every time we change the images array
    private var averageColorCache: CGColor?
    
    // This should really be synchronized to prevent concurrency issues
    var averageColor: CGColor? {
        if let cachedAverage = averageColorCache {
            return cachedAverage
        }
        
        if images.isEmpty {
            return nil
        }
        
        let sumComponents: [CGFloat] = images
            .map { ImageUtils.averageColorComponents(for: $0) }
            .reduce([0.0, 0.0, 0.0]) {
                [
                    $0[0] + $1[0],
                    $0[1] + $1[1],
                    $0[2] + $1[2]
                ]
            }
        
        // Compiler gets confused if we try to inline this map, so we build a new
        // array for the average, then add the alpha channel
        var averageComponents = sumComponents.map { $0 / CGFloat(images.count) }
        averageComponents.append(1.0)
        
        averageColorCache = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: averageComponents)
        return averageColorCache
    }
    
    enum CodingKeys: CodingKey {
        case orientationSwapped
        case outerBorder
        case innerBorder
        case borderColor
        case images
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(isOrientationSwapped, forKey: .orientationSwapped)
        try container.encode(outerBorderWeight, forKey: .outerBorder)
        try container.encode(innerBorderWeight, forKey: .innerBorder)
        try container.encode(CodableCGColor(with: borderColor), forKey: .borderColor)
        try container.encode(images.map{ CodableCGImage(with: $0) }, forKey: .images)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        isOrientationSwapped = try container.decode(Bool.self, forKey: .orientationSwapped)
        outerBorderWeight = try container.decode(Float.self, forKey: .outerBorder)
        innerBorderWeight = try container.decode(Float.self, forKey: .innerBorder)
        borderColor = try container.decode(CodableCGColor.self, forKey: .borderColor).color
        images = try container.decode(Array<CodableCGImage>.self, forKey: .images).map {
            $0.image
        }
    }
    
    init(borderWeight: Float) {
        borderColor = CGColor(colorSpace: CGColorSpaceCreateDeviceGray(), components: [255.0, 1.0])!
        innerBorderWeight = borderWeight
        outerBorderWeight = borderWeight
    }
    
    func copyWithoutImages() -> StarTych {
        let newTych = StarTych(borderWeight: innerBorderWeight)
        newTych.outerBorderWeight = outerBorderWeight
        newTych.borderColor = borderColor.copy()!
        return newTych
    }
    
    // TODO: Probably make non-optional
    func makeStarTych() -> CGImage? {
        return nil
    }
    
    func addImage(_ image: CGImage) {
        averageColorCache = nil
        images.append(image)
    }
    
    func removeImage(index: Int) {
        if index >= images.count {
            return
        }
        
        averageColorCache = nil
        images.remove(at: index)
    }
    
    func setImage(at index: Int, image: CGImage) -> Int {
        averageColorCache = nil
        if index < images.count {
            images[index] = image
            return index
        }
        
        images.append(image)
        return images.count - 1
    }
    
    func swapImage(firstIndex: Int, secondIndex: Int) {
        // We don't need to invalidate the average color cache for a swap
        if firstIndex >= images.count || secondIndex >= images.count {
            return
        }
        
        let swapImage = images[firstIndex]
        images[firstIndex] = images[secondIndex]
        images[secondIndex] = swapImage
    }
    
    func resizeImage(index: Int, maxSize: Int) {
        // We don't need to invalidate the average color cache for a resize
        if index >= images.count {
            return
        }
        
        let currentImage = images[index]
        if currentImage.width <= maxSize && currentImage.height < maxSize {
            return
        }
        
        images[index] = ImageUtils.copyImage(currentImage, maxSize: maxSize)
    }
    
    func hasImage(index: Int) -> Bool {
        return images.count > index
    }
    
    func hasAnyImage() -> Bool {
        return !images.isEmpty
    }
    
    func setBorderColor(fromHexCode hex: String) {
        
    }
}
