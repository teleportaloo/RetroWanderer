/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>

@class GameViewController;

@interface ScreenSelector : UIViewController

@property (strong, nonatomic) IBOutlet UIButton *screenButton;
@property (strong, nonatomic) NSMutableArray<UIButton *> *screenButtons;
@property (weak, nonatomic) GameViewController *gameView;
@property (strong, nonatomic) IBOutlet UILabel *percentageDone;

@end
