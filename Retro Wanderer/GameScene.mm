/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "GameScene.h"
#import "SpriteDisplay.h"
#import "GameViewControlleriPad.h"

@interface GameScene ()

@end

@implementation GameScene


- (void)didMoveToView:(SKView *)view {
    self.anchorPoint = CGPointMake(0.5, 0.5);


    CGPoint layerPosition = CGPointMake(-kTileWidth * kBoardWidth / 2, -kTileHeight * kBoardHeight / 2);

    self.boardLayer = [SKNode node];
    self.boardLayer.position = layerPosition;

    [self addChild:self.boardLayer];
}

- (void)update:(NSTimeInterval)currentTime {
    [self.controller processNextAction];
}

@end
