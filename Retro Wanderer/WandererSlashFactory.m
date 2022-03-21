//
//  WandererSlashFactory.m
//  Retro Wanderer
//
//  Created by Andrew Wallace on 8/2/20.
//  Copyright © 2020 Teleportaloo. All rights reserved.
//

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WandererSlashFactory.h"

@implementation WandererSlashFactory

+ (instancetype)slash {
    WandererSlashFactory *slash = [[[self class] alloc] init];

    return slash;
}

- (UIImage *)drawSlash:(TileNeighbors)neighbors color:(UIColor *)col {
    return [[UIImage alloc] init];
}

- (UIImage *)getImage:(TileNeighbors)neighbors {
    return [self drawSlash:neighbors color:[WandererTextureFactory fillColor:neighbors.tile]];
}

@end
