/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>
#import <UIKit/UIKit.h>

#import "TileNeighbors.h"

@interface WandererTextureFactory : NSObject

+ (UIColor *)fillColor:(char)ch;
+ (UIColor *)borderColor;
- (SKTexture *)getTexture:(TileNeighbors)neighbors;
- (UIImage *)getImage:(TileNeighbors)neighbors;
- (UIImage *)simpleCharacterTileImage:(NSString *)text bg:(UIColor *)bg fg:(UIColor *)fg;
- (NSNumber *)key:(TileNeighbors)neighbors;
- (void)additionalDrawing;
+ (instancetype)texture;

@end
