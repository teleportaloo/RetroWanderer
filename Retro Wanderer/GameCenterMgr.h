/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

#define kAchievementDate  @"date"
#define kAchievementScore @"score"

@interface GameCenterMgr : NSObject <GKGameCenterControllerDelegate>

+ (instancetype)sharedManager;

- (void)authenticatePlayer:(dispatch_block_t)success;
- (void)showLeaderboard;
- (void)showAchievements;
- (void)reportScore:(NSInteger)score;
- (void)reportAchievements:(NSDictionary *)achievements;

+ (void)noGameCenter;

@end
