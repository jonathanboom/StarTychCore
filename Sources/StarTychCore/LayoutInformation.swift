//
//  LayoutInformation.swift
//  
//
//  Created by Jonathan Lynch on 1/25/20.
//

struct LayoutInformation {
    
    let isHorizontal: Bool
    let minDimension: Int
    let innerBorderSize: Int
    let outerBorderSize: Int
    let totalWidth: Int
    let totalHeight: Int
    let scaledImagesInfo: [ScaledImageInformation]
    
    init?(for starTych: StarTych, isPreview: Bool = false) {
        if !starTych.hasAnyImage() {
            return nil
        }
        
        let imagesForLayout = isPreview ? starTych.previewImages : starTych.images
        
        var portraitOrSquareCount = 0
        var drawableImages = 0
        var minWidth = Int.max
        var minHeight = Int.max
        
        // Take a first pass over the images to compute the minimum dimensions and tally the number of portrait or square images
        for image in imagesForLayout {
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
        minDimension = isHorizontal ? minHeight : minWidth
        outerBorderSize = Int(Float(minDimension) * starTych.outerBorderWeight)
        innerBorderSize = Int(Float(minDimension) * starTych.innerBorderWeight)
        
        var totalWidthSoFar = 2 * outerBorderSize
        var totalHeightSoFar = 2 * outerBorderSize
        if isHorizontal {
            totalWidthSoFar += innerBorderSize * (drawableImages - 1)
            totalHeightSoFar += minDimension
        }
        else {
            totalWidthSoFar += minDimension
            totalHeightSoFar += innerBorderSize * (drawableImages - 1)
        }
        
        // Compute the dimensions of the scaled images and the final dimensions in the same pass
        var scaledImages = [ScaledImageInformation]()
        for image in imagesForLayout {
            // Don't compute for un-drawable images
            if image.width == 0 || image.height == 0 {
                continue
            }
            
            let scaleFactor = Float(minDimension) / Float(isHorizontal ? image.height : image.width)
            let scaledImageInfo = ScaledImageInformation(with: image, scaleFactor: scaleFactor)
            
            if isHorizontal {
                totalWidthSoFar += scaledImageInfo.width
            } else {
                totalHeightSoFar += scaledImageInfo.height
            }
            
            scaledImages.append(scaledImageInfo)
        }
        
        scaledImagesInfo = scaledImages
        totalWidth = totalWidthSoFar
        totalHeight = totalHeightSoFar
    }
}
