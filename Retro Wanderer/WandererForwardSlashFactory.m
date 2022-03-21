/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "WandererForwardSlashFactory.h"
#import "WandererTile.h"

@implementation WandererForwardSlashFactory


- (UIImage *)drawSlash:(TileNeighbors)neighbors color:(UIColor *)col {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(kTileWidth, kTileHeight), NO, 0);

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetStrokeColorWithColor(context, col.CGColor);
    CGContextSetLineWidth(context, 2.0);

    CGContextMoveToPoint(context, kTileWidth, 0);
    CGContextAddLineToPoint(context, 0, kTileHeight);

    CGContextStrokePath(context);

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return newImage;
}

@end
