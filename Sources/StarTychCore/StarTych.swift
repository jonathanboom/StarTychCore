//
//  StarTych.swift
//  
//
//  Created by Jonathan Lynch on 1/23/20.
//

import CoreGraphics
import ImageIO
import ImageUtils

public class StarTych: Codable {
    
    public var isOrientationSwapped = false
    public var outerBorderWeight: Float
    public var innerBorderWeight: Float
    public var borderColor: CGColor
    
    public var images = [CroppableImage]() {
        didSet {
            // Need to invalidate this cache every time we change the images array
            averageColorCache = nil
        }
    }
    
    public var imageCount: Int {
        return self.images.count
    }
    
    public var hasAnyImage: Bool {
        return !self.images.isEmpty
    }
    
    private var averageColorCache: CGColor?
    
    // This should probably be synchronized to prevent concurrency issues
    public var averageColor: CGColor? {
        if let cachedAverage = averageColorCache {
            return cachedAverage
        }
        
        if images.isEmpty {
            return nil
        }
        
        let sumComponents: [CGFloat] = images
            .map { ImageUtils.averageColorComponents(for: $0.originalImage) }
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
    
    private enum CodingKeys: CodingKey {
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
        try container.encode(images, forKey: .images)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        isOrientationSwapped = try container.decode(Bool.self, forKey: .orientationSwapped)
        outerBorderWeight = try container.decode(Float.self, forKey: .outerBorder)
        innerBorderWeight = try container.decode(Float.self, forKey: .innerBorder)
        borderColor = try container.decode(CodableCGColor.self, forKey: .borderColor).color
        images = try container.decode(Array<CroppableImage>.self, forKey: .images)
    }
    
    public init(borderWeight: Float) {
        borderColor = CGColor(colorSpace: CGColorSpaceCreateDeviceGray(), components: [255.0, 1.0])!
        innerBorderWeight = borderWeight
        outerBorderWeight = borderWeight
    }
    
    public func addImage(_ image: CGImage, orientation: CGImagePropertyOrientation = .up) {
        images.append(CroppableImage(image: image, orientation: orientation))
    }
    
    public func setImage(at index: Int, image: CGImage, orientation: CGImagePropertyOrientation = .up) -> Int {
        if index < images.count {
            images[index] = CroppableImage(image: image, orientation: orientation)
            return index
        }
        
        addImage(image)
        return images.count - 1
    }
    
    private let makeImageDrawGroup = DispatchGroup()
    
    public func makeImage(in frame: CGSize? = nil, interpolationQuality: CGInterpolationQuality = .default) -> CGImage? {
        if images.isEmpty {
            return nil
        }

        guard let layout = LayoutInformation(for: self, in: frame) else {
            return nil
        }

        guard let canvas = CGContext(data: nil, width: layout.canvasWidth, height: layout.canvasHeight, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: ImageUtils.alphaPremultipliedLast.rawValue) else {
            print("Something went wrong creating CGContext")
            return nil
        }

        if let scale = layout.canvasScale {
            if scale < 1.0 {
                canvas.scaleBy(x: scale, y: scale)
            }
        }

        canvas.setFillColor(borderColor)
        canvas.fill(CGRect(x: 0, y: 0, width: layout.fullWidth, height: layout.fullHeight))
        canvas.interpolationQuality = interpolationQuality
        for scaledImage in layout.scaledImagesInfo {
            canvas.draw(scaledImage.image.croppedImage,
                        in: CGRect(x: scaledImage.origin.x,
                                   y: scaledImage.origin.y,
                                   width: scaledImage.size.width,
                                   height: scaledImage.size.height))
        }

        return canvas.makeImage()
    }
}
