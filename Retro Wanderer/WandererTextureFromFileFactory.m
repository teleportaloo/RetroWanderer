/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "WandererTextureFromFileFactory.h"

@implementation WandererTextureFromFileFactory

+ (instancetype)withFileName:(NSString *)fileName {
    WandererTextureFromFileFactory *e = [[[self class] alloc] init];

    e.fileName = fileName;

    return e;
}

- (SKTexture *)getTexture:(char)ch left:(char)left right:(char)right up:(char)up down:(char)down {
    return [SKTexture textureWithImageNamed:self.fileName];
}

- (UIImage *)getImage:(TileNeighbors)neighbors {
    NSString *path = [[NSBundle mainBundle] pathForResource:self.fileName.stringByDeletingPathExtension.lastPathComponent ofType:self.fileName.pathExtension];

    return [UIImage imageWithContentsOfFile:path];
}

@end
