/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "WandererCageFactory.h"
#import "WandererTile.h"

@implementation WandererCageFactory

#define kMargin 1
#define kBars   5
#define kGap    (kTileWidth / kBars)
#define kTop    (kMargin)
#define kBottom (kTileHeight - kMargin)


- (void)additionalDrawing {
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetStrokeColorWithColor(context, [UIColor grayColor].CGColor);
    CGContextSetLineWidth(context, 1.5);

    CGContextMoveToPoint(context, kMargin, kMargin);
    CGContextAddLineToPoint(context, kTileWidth - 2, kMargin);

    for (int x = 0; x <= kBars; x++) {
        CGContextMoveToPoint(context, kMargin + x * kGap, kTop);
        CGContextAddLineToPoint(context, kMargin + x * kGap, kBottom);
    }

    CGContextMoveToPoint(context, kMargin, kBottom);
    CGContextAddLineToPoint(context, kTileWidth - 2, kBottom);


    CGContextStrokePath(context);
}

@end
