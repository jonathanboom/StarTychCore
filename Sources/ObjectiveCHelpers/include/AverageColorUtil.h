//
// Copyright (c) 2020, Jonathan Lynch
//
// This source code is licensed under the BSD 3-Clause License license found in the
// LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface AverageColorUtil: NSObject

+ (const NSArray<NSNumber *> *)averageColorComponentsForImage:(CGImageRef)image;

@end
