//
// Copyright (c) 2020, Jonathan Lynch
//
// This source code is licensed under the BSD 3-Clause License license found in the
// LICENSE file in the root directory of this source tree.
//

#import "include/AverageColorUtil.h"

@implementation AverageColorUtil

+ (const NSArray<NSNumber *> *)averageColorComponentsForImage:(CGImageRef)image {
    // Make the raw space to draw 1 pixel, 4 bytes
    unsigned char *rawData = (unsigned char *)malloc(4);
    
    // Draw the image as a 1x1 pixel into a canvas (in 32-bit, big endian format)
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef canvas = CGBitmapContextCreate(rawData, 1, 1, 8, 4, colorSpace, (CGBitmapInfo)(kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big));
    CGContextDrawImage(canvas, CGRectMake(0, 0, 1, 1), image);
    CGContextRelease(canvas);
    CGColorSpaceRelease(colorSpace);
    
    // Get the color components from the rawData and make an array of float values
    unsigned char redByte = rawData[0];
    unsigned char greenByte = rawData[1];
    unsigned char blueByte = rawData[2];
    
    // Make the components array
    NSArray<NSNumber *> *components = [[NSArray alloc] initWithObjects:
                                       [NSNumber numberWithFloat:(CGFloat)redByte / 0xff],
                                       [NSNumber numberWithFloat:(CGFloat)greenByte / 0xff],
                                       [NSNumber numberWithFloat:(CGFloat)blueByte / 0xff],
                                       [NSNumber numberWithFloat:1.0],
                                       nil];
    free(rawData);
    return components;
}

@end
