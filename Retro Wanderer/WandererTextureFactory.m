/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "WandererTextureFactory.h"
#import "WandererTile.h"

@implementation WandererTextureFactory

+ (instancetype)texture {
    return [[[self class] alloc] init];
}

+ (UIColor *)fillColor:(char)ch {
    static NSDictionary<NSNumber *, UIColor *> *colors;
    static dispatch_once_t once;

    dispatch_once(&once, ^{
        colors = @{
            @kChGranite:  [UIColor brownColor],
            @kChHoriz:  [UIColor grayColor],
            @kChBrick:  [UIColor darkGrayColor],
            @kChSide:  [UIColor grayColor],
            @kChRampB:  [UIColor brownColor],
            @kChRampF:  [UIColor brownColor]
        };
    });

    UIColor *col = colors[@(ch)];

    if (col == nil) {
        return [UIColor grayColor];
    }

    return col;
}

+ (UIColor *)borderColor {
    return [UIColor colorWithWhite:0.6 alpha:1.0];
}

- (SKTexture *)getTexture:(TileNeighbors)neighbors {
    return [SKTexture textureWithImage:[self getImage:neighbors]];
}

- (UIImage *)getImage:(TileNeighbors)neighbors {
    unichar uch = neighbors.tile;
    UIImage *image = [self simpleCharacterTileImage:[NSString stringWithCharacters:&uch length:1]
                                                 bg:nil
                                                 fg:nil];

    return image;
}

- (void)additionalDrawing {
}

- (UIImage *)simpleCharacterTileImage:(NSString *)text bg:(UIColor *)bg fg:(UIColor *)fg {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(kTileWidth, kTileHeight), NO, 0);
    CGRect rect = CGRectMake(0, 0, kTileWidth, kTileHeight);

    if (bg == nil) {
        bg = [UIColor clearColor];
    }

    [bg set];
    UIRectFill(rect);

    // if (bg == nil || fg!=nil)
    {
        UIFont *font = nil;

        if (text.length == 0) {
            text = @"?";
        }

        if ([text characterAtIndex:0] < 128) {
            font = [UIFont fontWithName:@"Courier-Bold" size:28];
        } else {
            font = [UIFont systemFontOfSize:22];
        }

        if (fg == nil) {
            fg = [UIColor greenColor];
        }

        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.alignment = NSTextAlignmentCenter;

        NSDictionary *attributes = @{ NSFontAttributeName: font, NSForegroundColorAttributeName: fg, NSBackgroundColorAttributeName: bg, NSParagraphStyleAttributeName: paragraphStyle };
        CGSize textSize = [text sizeWithAttributes:attributes];
        CGRect textRect = CGRectMake((kTileWidth - textSize.width) / 2, (kTileHeight - textSize.height) / 2, textSize.width, textSize.height);
        [text drawInRect:textRect withAttributes:attributes];
    }

    [self additionalDrawing];

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return newImage;
}

- (NSNumber *)key:(TileNeighbors)neighbors {
    return @(neighbors.tile);
}

@end
