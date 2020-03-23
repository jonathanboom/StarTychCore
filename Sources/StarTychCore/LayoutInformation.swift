//
// Copyright (c) 2020, Jonathan Lynch
//
// This source code is licensed under the BSD 3-Clause License license found in the
// LICENSE file in the root directory of this source tree.
//

import CoreGraphics

struct LayoutInformation {
    
    let isHorizontal: Bool
    let innerBorderSize: Int
    let outerBorderSize: Int
    let fullWidth: Int
    let fullHeight: Int
    
    let canvasWidth: Int
    let canvasHeight: Int
    let canvasScale: CGFloat?
    
    let scaledImagesInfo: [ScaledImageInformation]
    
    init?(for starTych: StarTych, in frame: CGSize? = nil) {
        if !starTych.hasAnyImage {
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
        let minDimension = isHorizontal ? minHeight : minWidth
        outerBorderSize = Int(Float(minDimension) * starTych.outerBorderWeight)
        innerBorderSize = Int(Float(minDimension) * starTych.innerBorderWeight)
        
        var totalWidthSoFar = 2 * outerBorderSize
        var totalHeightSoFar = 2 * outerBorderSize
        
        // Compute the dimensions of the scaled images and the final dimensions in the same pass
        var scaledImages = [ScaledImageInformation]()
        if isHorizontal {
            totalWidthSoFar += innerBorderSize * (drawableImages - 1)
            totalHeightSoFar += minHeight
            var xOffset = outerBorderSize
            for image in starTych.images {
                // Don't compute for un-drawable images
                if image.width == 0 || image.height == 0 {
                    continue
                }
                
                let scaleFactor = Float(minHeight) / Float(image.height)
                let scaledSize = ScaledImageInformation.scaledImageSize(image: image, scaleFactor: scaleFactor)
                let origin = CGPoint(x: xOffset, y: outerBorderSize)
                let scaledImageInfo = ScaledImageInformation(image: image, size: scaledSize, origin: origin)
                scaledImages.append(scaledImageInfo)

                totalWidthSoFar += Int(scaledSize.width)
                xOffset += Int(scaledSize.width) + innerBorderSize
            }
        } else {
            totalWidthSoFar += minWidth
            totalHeightSoFar += innerBorderSize * (drawableImages - 1)
            var yOffset = outerBorderSize
            
            // Loop in reverse order for vertical drawing due to bottom-left origin
            for image in starTych.images.reversed() {
                // Don't compute for un-drawable images
                if image.width == 0 || image.height == 0 {
                    continue
                }
                
                let scaleFactor = Float(minWidth) / Float(image.width)
                let scaledSize = ScaledImageInformation.scaledImageSize(image: image, scaleFactor: scaleFactor)
                let origin = CGPoint(x: outerBorderSize, y: yOffset)
                let scaledImageInfo = ScaledImageInformation(image: image, size: scaledSize, origin: origin)
                scaledImages.append(scaledImageInfo)
                
                totalHeightSoFar += Int(scaledSize.height)
                yOffset += Int(scaledSize.height) + innerBorderSize
            }
        }
        
        fullWidth = totalWidthSoFar
        fullHeight = totalHeightSoFar
        scaledImagesInfo = scaledImages

        if let frameWidth = frame?.width, let frameHeight = frame?.height {
            let frameAspect = LayoutInformation.aspectRatio(width: frameWidth, height: frameHeight)
            let imageAspect = LayoutInformation.aspectRatio(width: totalWidthSoFar, height: totalHeightSoFar)
            
            if imageAspect > frameAspect && CGFloat(totalWidthSoFar) > frameWidth {
                // Width dominates
                canvasScale = frameWidth / CGFloat(totalWidthSoFar)
                canvasWidth = Int(frameWidth)
                canvasHeight = Int(CGFloat(totalHeightSoFar) * canvasScale!)
            } else if CGFloat(totalHeightSoFar) > frameHeight {
                canvasScale = frameHeight / CGFloat(totalHeightSoFar)
                canvasWidth = Int(CGFloat(totalWidthSoFar) * canvasScale!)
                canvasHeight = Int(frameHeight)
            } else {
                canvasScale = nil
                canvasWidth = totalWidthSoFar
                canvasHeight = totalHeightSoFar
            }
        } else {
            canvasScale = nil
            canvasWidth = totalWidthSoFar
            canvasHeight = totalHeightSoFar
        }
    }
    
    // Width:height aspect ratio as a decimal; 16:9 would be 1.777...
    private static func aspectRatio(width: CGFloat, height: CGFloat) -> CGFloat {
        if width.isZero || height.isZero {
            return 0.0
        }
        
        return width / height
    }
    
    private static func aspectRatio(width: Int, height: Int) -> CGFloat {
        if width == 0 || height == 0 {
            return 0.0
        }
        
        return CGFloat(width) / CGFloat(height)
    }
}
