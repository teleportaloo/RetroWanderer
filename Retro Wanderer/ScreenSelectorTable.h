/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>

@class GameViewController;

#define kPrevText @"Previous"
#define kNextText @"Next"


@interface ScreenSelectorTable : UITableViewController
@property (nonatomic, weak) GameViewController *gameView;

@end
