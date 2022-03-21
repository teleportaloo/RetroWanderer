/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
#import "WandererTextureFactory.h"

@interface WandererBlockFactory : WandererTextureFactory

@property (nonatomic, retain) UIColor *bgColor;
@property (nonatomic, retain) UIColor *fgColor;
@property (nonatomic, retain) UIImage *image;

+ (instancetype)withBg:(UIColor *)bgColor fg:(UIColor *)fgColor;
+ (instancetype)withFg:(UIColor *)fgColor fileName:(NSString *)image;

@end
