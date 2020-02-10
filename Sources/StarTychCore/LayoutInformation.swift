//
//  LayoutInformation.swift
//  
//
//  Created by Jonathan Lynch on 1/25/20.
//

import CoreGraphics

struct LayoutInformation {
    
    let isHorizontal: Bool
    let innerBorderSize: CGFloat
    let outerBorderSize: CGFloat
    let totalWidth: CGFloat
    let totalHeight: CGFloat
    let scaledImagesInfo: [ScaledImageInformation]
    
    init?(for starTych: StarTych, in frame: CGSize? = nil) {
        if !starTych.hasAnyImage() {
            return nil
        }
        
        var portraitOrSquareCount = 0
        var drawableImages = 0
        var minWidth = Int.max
        var minHeight = Int.max
        
        // Take a first pass over the images to compute the minimum dimensions and tally the number of portrait or square images
        for image in starTych.images {
            if image.width == 0 || image.height == 0 {
                continue
            }
            
            drawableImages += 1
            if image.width < minWidth {
                minWidth = image.width
            }
            
            if image.height < minHeight {
                minHeight = image.height
            }
            
            if image.height >= image.width {
                portraitOrSquareCount += 1
            }
        }
        
        if drawableImages == 0 {
            print("ERROR: all images have at least one 0-dimension")
            return nil
        }
        
        // If we have more portrait than landscape images, default orientation is horizontal
        let isDefaultHorizontal = portraitOrSquareCount * 2 >= drawableImages
        if starTych.isOrientationSwapped {
            isHorizontal = !isDefaultHorizontal
        } else {
            isHorizontal = isDefaultHorizontal
        }
        
        // The dimension we need to pay attention to is height for horizontal layouts, width for vertical
        let minDimension = CGFloat(isHorizontal ? minHeight : minWidth)
        let fullOuterBorderSize = Int(minDimension * CGFloat(starTych.outerBorderWeight))
        let fullInnerBorderSize = Int(minDimension * CGFloat(starTych.innerBorderWeight))
        
        var totalWidthSoFar = 2 * CGFloat(fullOuterBorderSize)
        var totalHeightSoFar = 2 * CGFloat(fullOuterBorderSize)
        if isHorizontal {
            totalWidthSoFar += CGFloat(fullInnerBorderSize * (drawableImages - 1))
            totalHeightSoFar += minDimension
        }
        else {
            totalWidthSoFar += minDimension
            totalHeightSoFar += CGFloat(fullInnerBorderSize * (drawableImages - 1))
        }
        
        // Compute the dimensions of the scaled images and the final dimensions in the same pass
        var scaledImages = [ScaledImageInformation]()
        for image in starTych.images {
            // Don't compute for un-drawable images
            if image.width == 0 || image.height == 0 {
                continue
            }
            
            let scaleFactor = minDimension / CGFloat(isHorizontal ? image.height : image.width)
            let scaledImageInfo = ScaledImageInformation(with: image, scaleFactor: scaleFactor)
            
            if isHorizontal {
                totalWidthSoFar += scaledImageInfo.width
            } else {
                totalHeightSoFar += scaledImageInfo.height
            }
            
            scaledImages.append(scaledImageInfo)
        }
        
        if let frameWidth = frame?.width, let frameHeight = frame?.height {
            let frameAspect = LayoutInformation.aspectRatio(width: frameWidth, height: frameHeight)
            let imageAspect = LayoutInformation.aspectRatio(width: totalWidthSoFar, height: totalHeightSoFar)
            
            var scale: CGFloat = 1.0
            if imageAspect > frameAspect && totalWidthSoFar > frameWidth {
                // Width dominates
                scale = frameWidth / totalWidthSoFar
            } else if totalHeightSoFar > frameHeight {
                scale = frameHeight / totalHeightSoFar
            }
            
            scaledImagesInfo = scaledImages.map { $0.copy(scale: scale) }
            totalWidth = totalWidthSoFar * scale
            totalHeight = totalHeightSoFar * scale
            outerBorderSize = CGFloat(fullOuterBorderSize) * scale
            innerBorderSize = CGFloat(fullInnerBorderSize) * scale
            
        } else {
            scaledImagesInfo = scaledImages
            totalWidth = totalWidthSoFar
            totalHeight = totalHeightSoFar
            outerBorderSize = CGFloat(fullOuterBorderSize)
            innerBorderSize = CGFloat(fullInnerBorderSize)
        }
    }
    
    // Width:height aspect ratio as a decimal; 16:9 would be 1.777...
    private static func aspectRatio(width: CGFloat, height: CGFloat) -> CGFloat {
        if width.isZero || height.isZero {
            return 0.0
        }
        
        return width / height
    }
}
