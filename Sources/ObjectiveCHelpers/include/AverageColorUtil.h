//
//  AverageColorUtil.h
//  
//
//  Created by Jonathan Lynch on 1/25/20.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface AverageColorUtil: NSObject

+ (const NSArray<NSNumber *> *)averageColorComponentsForImage:(CGImageRef)image;

@end
