/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "WandererEmojiFactory.h"
#import "WandererTile.h"
#import "DebugLogging.h"

@implementation WandererEmojiFactory

+ (instancetype)withEmoji:(NSString *)emoji {
    WandererEmojiFactory *e = [[[self class] alloc] init];

    e.emoji = emoji;

    DEBUG_ASSERT(emoji.length > 0, @"length %lu", emoji.length);

    return e;
}

+ (instancetype)withEmoji:(NSString *)emoji fg:(UIColor *)fgColor {
    WandererEmojiFactory *e = [[[self class] alloc] init];

    e.emoji = emoji;
    e.fgColor = fgColor;

    DEBUG_ASSERT(emoji.length > 0, @"length %lu", emoji.length);

    return e;
}

+ (instancetype)withEmoji:(NSString *)emoji bg:(UIColor *)bgColor {
    WandererEmojiFactory *e = [[[self class] alloc] init];

    e.emoji = emoji;
    e.bgColor = bgColor;

    DEBUG_ASSERT(emoji.length > 0, @"length %lu", emoji.length);

    return e;
}

- (UIImage *)getImage:(TileNeighbors)neighbors {
    UIImage *image = [self simpleCharacterTileImage:self.emoji
                                                 bg:self.bgColor
                                                 fg:self.fgColor];

    return image;
}

@end
