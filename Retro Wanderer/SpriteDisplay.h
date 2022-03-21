/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import "abstracted_display_objc.h"
#import "WandererTile.h"

#define kBoardHeight 18
#define kBoardWidth  42

@class WandererTextureFactory;

@protocol SpriteDisplayDelegate

- (void)animationsStarted;
- (void)animationsDone;

@end

@interface SpriteDisplay : NSObject <AbstractedDisplay> {
    WandererTile *_screen[kBoardHeight][kBoardWidth];
    bool _cancelling;
}

@property (weak, nonatomic)  id<SpriteDisplayDelegate> delegate;
@property (strong, nonatomic) SKNode *boardLayer;
@property (weak, nonatomic)   UIView *view;
@property (nonatomic, retain) UILabel *scoreLabel;
@property (nonatomic, retain) UILabel *diamondsLabel;
@property (nonatomic, retain) UILabel *maxMovesLabel;
@property (nonatomic, retain) UILabel *monsterLabel;
@property (nonatomic, retain) UILabel *nameLabel;
@property (nonatomic, retain) SKSpriteNode *homeSprite;
@property (nonatomic) double animationDuration;
@property (nonatomic) double playerDuration;
@property (nonatomic) bool sounds;
@property (nonatomic, copy) NSString *screenName;
@property (nonatomic, retain) NSMutableArray<dispatch_block_t> *sequence;
@property (nonatomic, retain) NSMutableArray<dispatch_block_t> *slowGroup;
@property (atomic) int animationCount;
@property (atomic, copy) dispatch_block_t sequenceCompletionBlock;
@property (atomic, copy) dispatch_block_t sequenceCancellationBlock;
@property (nonatomic, retain) SKAction *hideAction;
@property (nonatomic, retain) SKAction *waitAction;
@property (nonatomic) double waitActionDuration;
@property (nonatomic, retain) NSMutableDictionary<NSNumber *, SKAction *> *fastMoveCache;
@property (nonatomic) int cacheHits;
@property (nonatomic, copy) NSString *screenPrefix;
@property (nonatomic) int screenNumber;
@property (nonatomic) bool normalFlashing;

@property (nonatomic) bool cached_ad_monster;
@property (nonatomic) int cached_ad_diamonds_nf;
@property (nonatomic) int cached_ad_diamonds_total;

- (void)updateMonster;
- (void)updateDiamonds;
- (void)deadPlayer;
- (void)playbackPlayer;
- (void)normalPlayer;
- (void)flashingPlayer;
- (void)happyPlayer;
- (void)runSequenceWithCompletion:(dispatch_block_t)sequenceCompletionBlock;
- (void)cancelSequenceWithCompletion:(dispatch_block_t)sequenceCancellationBlock;
- (void)updateName;

@end
