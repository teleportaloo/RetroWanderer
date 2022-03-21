//
//  UIWindow+Helper.h
//  Retro Wanderer
//
//  Created by Andrew Wallace on 7/12/20.
//  Copyright © 2020 Teleportaloo. All rights reserved.
//

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIWindow (Helper)

- (UIViewController *)visibleViewController;

+ (UIWindow *)firstKeyWindow;

@end

NS_ASSUME_NONNULL_END
