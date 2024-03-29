/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <SpriteKit/SpriteKit.h>

@class GameViewController;

@interface GameScene : SKScene

@property (strong, nonatomic) SKNode *boardLayer;
@property (weak, nonatomic) GameViewController *controller;


@end
