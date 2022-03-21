/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import "WandererTextureFactory.h"

@interface WandererEmojiFactory : WandererTextureFactory

@property (nonatomic, retain) NSString *emoji;
@property (nonatomic, retain) UIColor *fgColor;
@property (nonatomic, retain) UIColor *bgColor;

+ (instancetype)withEmoji:(NSString *)emoji;
+ (instancetype)withEmoji:(NSString *)emoji fg:(UIColor *)fgColor;
+ (instancetype)withEmoji:(NSString *)emoji bg:(UIColor *)bgColor;

@end
