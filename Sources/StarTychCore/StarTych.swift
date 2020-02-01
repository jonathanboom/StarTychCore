//
//  StarTych.swift
//  
//
//  Created by Jonathan Lynch on 1/23/20.
//

import CoreGraphics
import ImageUtils

public class StarTych: Codable {
    
    public var isOrientationSwapped = false
    public var outerBorderWeight: Float
    public var innerBorderWeight: Float
    public var borderColor: CGColor
    
    public var maxPreviewSize = 800 {
        didSet {
            previewImages = images.map {
                ImageUtils.copyImage($0, maxSize: maxPreviewSize)!
            }
        }
    }
    
    var images = [CGImage]()
    var previewImages = [CGImage]()
    
    // NB: Need to invalidate this cache every time we change the images array
    private var averageColorCache: CGColor?
    
    // This should really be synchronized to prevent concurrency issues
    public var averageColor: CGColor? {
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
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(isOrientationSwapped, forKey: .orientationSwapped)
        try container.encode(outerBorderWeight, forKey: .outerBorder)
        try container.encode(innerBorderWeight, forKey: .innerBorder)
        try container.encode(CodableCGColor(with: borderColor), forKey: .borderColor)
        try container.encode(images.map{ CodableCGImage(with: $0) }, forKey: .images)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        isOrientationSwapped = try container.decode(Bool.self, forKey: .orientationSwapped)
        outerBorderWeight = try container.decode(Float.self, forKey: .outerBorder)
        innerBorderWeight = try container.decode(Float.self, forKey: .innerBorder)
        borderColor = try container.decode(CodableCGColor.self, forKey: .borderColor).color
        images = try container.decode(Array<CodableCGImage>.self, forKey: .images).map {
            $0.image
        }
        previewImages = images.map {
            ImageUtils.copyImage($0, maxSize: maxPreviewSize)!
        }
    }
    
    public init(borderWeight: Float) {
        borderColor = CGColor(colorSpace: CGColorSpaceCreateDeviceGray(), components: [255.0, 1.0])!
        innerBorderWeight = borderWeight
        outerBorderWeight = borderWeight
    }
    
    public func copyWithoutImages() -> StarTych {
        let newTych = StarTych(borderWeight: innerBorderWeight)
        newTych.outerBorderWeight = outerBorderWeight
        newTych.borderColor = borderColor.copy()!
        return newTych
    }
    
    public func addImage(_ image: CGImage) {
        averageColorCache = nil
        images.append(image)
        previewImages.append(ImageUtils.copyImage(image, maxSize: maxPreviewSize)!)
    }
    
    public func removeImage(index: Int) {
        if index >= images.count {
            return
        }
        
        averageColorCache = nil
        images.remove(at: index)
        previewImages.remove(at: index)
    }
    
    public func setImage(at index: Int, image: CGImage) -> Int {
        averageColorCache = nil
        if index < images.count {
            images[index] = image
            previewImages[index] = ImageUtils.copyImage(image, maxSize: maxPreviewSize)!
            return index
        }
        
        addImage(image)
        return images.count - 1
    }
    
    public func swapImage(firstIndex: Int, secondIndex: Int) {
        // We don't need to invalidate the average color cache for a swap
        if firstIndex >= images.count || secondIndex >= images.count {
            return
        }
        
        let swapImage = images[firstIndex]
        images[firstIndex] = images[secondIndex]
        images[secondIndex] = swapImage
        
        let previewSwap = previewImages[firstIndex]
        previewImages[firstIndex] = previewImages[secondIndex]
        previewImages[secondIndex] = previewSwap
    }
    
    public func resizeImage(index: Int, maxSize: Int) {
        // We don't need to invalidate the average color cache for a resize
        if index >= images.count {
            return
        }
        
        let currentImage = images[index]
        if currentImage.width <= maxSize && currentImage.height < maxSize {
            return
        }
        
        guard let resizedImage = ImageUtils.copyImage(currentImage, maxSize: maxSize) else {
            return
        }
        
        images[index] = resizedImage
    }
    
    public func hasImage(index: Int) -> Bool {
        return images.count > index
    }
    
    public func hasAnyImage() -> Bool {
        return !images.isEmpty
    }
    
    public func makeImage(isPreview: Bool = false) -> CGImage? {
        if images.isEmpty {
            return nil
        }
        
        guard let layout = LayoutInformation(for: self, isPreview: isPreview) else {
            return nil
        }
        
        guard let canvas = CGContext(data: nil, width: layout.totalWidth, height: layout.totalHeight, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: ImageUtils.alphaPremultipliedLast.rawValue) else {
            print("Something went wrong creating CGContext")
            return nil
        }
        
        canvas.setFillColor(borderColor)
        canvas.fill(CGRect(x: 0, y: 0, width: layout.totalWidth, height: layout.totalHeight))
        
        var xOffset = layout.outerBorderSize
        var yOffset = layout.outerBorderSize
        if layout.isHorizontal {
            for scaledImage in layout.scaledImagesInfo {
                canvas.draw(scaledImage.image, in: CGRect(x: xOffset, y: yOffset, width: scaledImage.width, height: scaledImage.height))
                xOffset += scaledImage.width + layout.innerBorderSize
            }
        } else {
            for scaledImage in layout.scaledImagesInfo.reversed() {
                canvas.draw(scaledImage.image, in: CGRect(x: xOffset, y: yOffset, width: scaledImage.width, height: scaledImage.height))
                yOffset += scaledImage.height + layout.innerBorderSize
            }
        }
        
        return canvas.makeImage()
    }
}
