//
//  WandererSlashFactory.h
//  Retro Wanderer
//
//  Created by Andrew Wallace on 8/2/20.
//  Copyright © 2020 Teleportaloo. All rights reserved.
//

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WandererTextureFactory.h"

NS_ASSUME_NONNULL_BEGIN

@interface WandererSlashFactory : WandererTextureFactory

- (UIImage *)drawSlash:(TileNeighbors)neighbors color:(UIColor *)col;

+ (instancetype)slash;

@end

NS_ASSUME_NONNULL_END
