/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "SpriteDisplay.h"
#import "WandererEmojiFactory.h"
#import <AudioToolbox/AudioToolbox.h>
#import "DebugLogging.h"
#import "Screens.h"

extern "C"

{
#include "abstracted_display.h"
extern void ad_set_display(id<AbstractedDisplay> display);
}

@implementation SpriteDisplay

- (void)replace:(char)ch with:(WandererTextureFactory *)factory flashing:(WandererTextureFactory *)flashing {
    [WandererTile replaceFactory:ch with:factory];

    int x;

    for (int y = 0; y < kBoardHeight; y++) {
        for (x = 0; x < kBoardWidth; x++) {
            WandererTile *old = _screen[y][x];

            if (old != nil && old.ch == ch) {
                old.sprite.hidden = YES;
                WandererTile *tile = [WandererTile tileFromCh:ch];
                tile.sprite.position = [self pointForColumn:x row:y];
                tile.sprite.zPosition = 100;
                [self.boardLayer addChild:tile.sprite];
                _screen[y][x] = tile;

                if (flashing) {
                    SKTexture *original = tile.sprite.texture;
                    SKTexture *highlight = [flashing getTexture:NoTileNeighbors(tile.ch)];

                    SKAction *wait0 = [SKAction waitForDuration:0.33];

                    SKAction *block0 = [SKAction runBlock:^{
                                                     tile.sprite.texture = original;
                                                 }];

                    SKAction *block1 = [SKAction runBlock:^{
                                                     tile.sprite.texture = highlight;
                                                 }];

                    [tile.sprite runAction:[SKAction repeatActionForever:[SKAction sequence:@[wait0, block0, wait0, block1]]]];
                }
            }
        }
    }
}

- (void)deadPlayer {
    [self replace:kChPlayer with:[WandererTile specialFactory:kDeadPlayer] flashing:nil];
}

- (void)playbackPlayer {
    [self replace:kChPlayer with:[WandererTile specialFactory:kPlaybackPLayer] flashing:nil];
}

- (void)normalPlayer {
    [self replace:kChPlayer with:[WandererTile specialFactory:kNormalPlayer] flashing:nil];
}

- (void)flashingPlayer {
    [self replace:kChPlayer with:[WandererTile specialFactory:kNormalPlayer]
         flashing:[WandererTile specialFactory:kHighlightedPlayer]];
}

- (void)happyPlayer {
    [self replace:kChPlayer with:[WandererTile specialFactory:kHappyPlayer] flashing:nil];
}

- (instancetype)init {
    if ((self = [super init])) {
        ad_set_display(self);
        self.sequence = [NSMutableArray array];
        self.slowGroup = [NSMutableArray array];
        self.hideAction = [SKAction hide];
        self.fastMoveCache = [NSMutableDictionary dictionary];
        [self ad_clear];
    }

    return self;
}

- (CGPoint)pointForColumn:(NSInteger)column row:(NSInteger)row {
    return CGPointMake(column * kTileWidth + kTileWidth / 2, kBoardHeight * kTileHeight - (row * kTileHeight + kTileHeight / 2));
}

- (void)ad_clear {
    int x;

    for (int y = 0; y < kBoardHeight; y++) {
        for (x = 0; x < kBoardWidth; x++) {
            WandererTile *old = _screen[y][x];

            if (old != nil) {
                old.sprite.hidden = YES;
            }

            _screen[y][x] = nil;
        }
    }

    if (self.homeSprite) {
        [self.homeSprite removeAllActions];
        self.homeSprite = nil;
    }

    [self normalPlayer];

    [self.boardLayer removeAllChildren];
}

- (void)runSequenceWithCompletion:(dispatch_block_t)sequenceCompletionBlock {
    self.sequenceCompletionBlock = sequenceCompletionBlock;
    [self runSequence];
}

- (void)nextInSequence {
    if (!_cancelling) {
        [self runSequence];
    } else {
        for (dispatch_block_t block in self.sequence) {
            block();
        }

        [self.sequence removeAllObjects];
        [self runSequence];
    }
}

- (void)runSequence {
    if (self.slowGroup.count > 0) {
        NSMutableArray *group = self.slowGroup;
        __weak typeof(self) weakSelf = self;
        [self.sequence addObject:^{
                           for (dispatch_block_t slow in group) {
                           slow();
                           }

                           [weakSelf runSequence];
                       }];
        self.slowGroup = [NSMutableArray array];
    }

    if (self.sequence.count > 0) {
        dispatch_block_t next = self.sequence.firstObject;
        [self.sequence removeObjectAtIndex:0];
        next();
    } else {
        if (self.sequenceCompletionBlock) {
            self.sequenceCompletionBlock();
            self.sequenceCompletionBlock = nil;
        }

        if (_cancelling) {
            _cancelling = NO;

            if (self.sequenceCancellationBlock) {
                self.sequenceCancellationBlock();
                self.sequenceCancellationBlock = nil;
            }
        }

        [self.fastMoveCache removeAllObjects];
        self.cacheHits = 0;
    }
}

- (void)cancelSequenceWithCompletion:(dispatch_block_t)sequenceCancellationBlock {
    if (self.sequence.count > 0 && !_cancelling) {
        _cancelling = YES;
        self.sequenceCancellationBlock = sequenceCancellationBlock;
    } else {
        sequenceCancellationBlock();
    }
}

- (void)animateMove:(WandererTile *)moving toX:(int)x toY:(int)y over:(SKSpriteNode *)over replace:(SKSpriteNode *)left
          finalTile:(WandererTile *)finalTile
               hint:(int)hint
         completion:(dispatch_block_t)completion {
    moving.sprite.zPosition = 100;

    // The item to be left behind should be below the moving tile
    if (left) {
        left.zPosition = 90;
        [self.boardLayer addChild:left];
    }

    // This is the to tile, which is gong to be wiped out so it is behind.
    if (over) {
        over.zPosition = 90;
    }

    // The final tile is below even the over tile
    if (finalTile) {
        finalTile.sprite.zPosition = 85;
    }

    bool slow_and_grouped = self.playerDuration == 0.0 ? YES : (hint == ad_hint_slow_and_grouped);

    NSTimeInterval duration = 0;

    if (slow_and_grouped) {
        duration = self.playerDuration;
    } else {
        duration = self.animationDuration;
    }

    SKAction *move = nil;

    if (slow_and_grouped) {
        move = [SKAction moveTo:[self pointForColumn:x row:y] duration:duration];
        move.timingMode = SKActionTimingLinear;
    } else {
        NSNumber *actionKey = @(x + y * kBoardWidth);

        move = self.fastMoveCache[actionKey];

        if (move == nil) {
            move = [SKAction moveTo:[self pointForColumn:x row:y] duration:duration];
            move.timingMode = SKActionTimingLinear;
            [self.fastMoveCache setObject:move forKey:actionKey];
        } else {
            self.cacheHits++;
        }
    }

    SKAction *action = nil;

    dispatch_block_t newCompletion = ^{
        completion();
        [self nextInSequence];
    };

    if (slow_and_grouped) {
        newCompletion = completion;
    }

    if (finalTile) {
        action = [SKAction sequence:@[move, self.hideAction, [SKAction runBlock:newCompletion]]];
    } else {
        action = [SKAction sequence:@[move, [SKAction runBlock:newCompletion]]];
    }

    if (slow_and_grouped) {
        [self.slowGroup addObject:
         ^{
             [moving.sprite runAction:action];
         }
        ];
    } else {
        if (self.slowGroup.count > 0) {
            __weak typeof(self) weakSelf = self;

            if (self.waitAction == nil || self.waitActionDuration != self.playerDuration) {
                self.waitAction = [SKAction sequence:@[[SKAction waitForDuration:self.playerDuration],
                                                       [SKAction runBlock:
                                                        ^{
                                                            DEBUG_LOG(@"Wait block");
                                                            [weakSelf nextInSequence];
                                                        }]]];
                self.waitActionDuration = self.playerDuration;
            }

            [self.slowGroup addObject:^{
                                [moving.sprite runAction:weakSelf.waitAction];
                            }];

            NSMutableArray *group = self.slowGroup;
            [self.sequence addObject:^{
                               for (dispatch_block_t slow in group) {
                               slow();
                               }
                           }];
            self.slowGroup = [NSMutableArray array];
        }

        [self.sequence addObject:^{
                           [moving.sprite runAction:action];
                       }];
    }

    //DEBUG_LOGC(moving.ch);
    //DEBUG_LOGLU(self.sequence.count);
}

- (void)ad_sound:(char)sound {
    if (self.sounds) {
        // Sounds are played after all is done.
        NSDictionary<NSNumber *, NSNumber *> *sounds = @{
            @kChCage: @(1103),
            @kChMoney: @(1054),
            @kChEarth: @(1104),
            @kChExit: @(1025),
            @kChMonster: @(1105),
            @kChMine: @(1053)
        };


        NSNumber *soundId = sounds[@(sound)];

        if (soundId != nil) {
            AudioServicesPlaySystemSound(soundId.unsignedIntValue);
        }
    }
}

// This function is pretty complicated now - so it needs a lot of comments.
- (void)ad_move_ch:(char)ch fromY:(int)y fromX:(int)x toY:(int)ny toX:(int)nx replace:(char)replace newch:(char)newch sound:(char)sound
              hint:(int)hint {
    //if (y==ny && x==nx)
    //{
    //   return;
    //}

    if (x == 0 && y == 0) {
        x = nx;
        y = ny;
    }

#ifdef DEBUGLOGGING1
    static char last = 0;

    if (ch != last) {
        DEBUG_LOGC(ch);
        last = ch;
    }

#endif

    if (y < kBoardHeight && x < kBoardWidth) {
        WandererTile *movingTile = _screen[y][x];
        bool keepOriginal = NO;
        SKSpriteNode *spriteLeft = nil;

        // Sometimes there is a boulder already in the little monster's position
        if (movingTile == nil || movingTile.ch != ch) {
            // If there is an item there just make sure it is behind the item we are creating.
            if (movingTile) {
                movingTile.sprite.zPosition = 90;
            }

            // This is a temporary tile for the actual character we are moving.
            movingTile = [WandererTile tileFromCh:ch];
            movingTile.sprite.position = [self pointForColumn:x row:y];
            [self.boardLayer addChild:movingTile.sprite];

            // Don't replace the one left behind, if it's a boulder is needs to be there.
            keepOriginal = YES;
        }

        if (ny < kBoardHeight && nx < kBoardWidth) {
            // There maybe something where we are going.
            WandererTile *toTile = _screen[ny][nx];

            if (toTile == movingTile) {
                toTile = nil;
                keepOriginal = YES;
            }

            // We may need a tile to display what is left behind after we moved.
            WandererTile *leftTile = nil;

            if (replace != ' ') {
                leftTile = [WandererTile tileFromCh:replace];
                leftTile.sprite.position = [self pointForColumn:x row:y];
                spriteLeft = leftTile.sprite;
            }

            // After we have moved we may actually change the tile to something else - e.g. a cage into a diamond.
            WandererTile *finalTile = nil;

            if (newch != 0) {
                finalTile = [WandererTile tileFromCh:newch];
                finalTile.sprite.position = [self pointForColumn:nx row:ny];
                finalTile.sprite.zPosition = 70;
                [self.boardLayer addChild:finalTile.sprite];
            }

            // This updates our model of the sprites to their final state.
            if (!finalTile) {
                _screen[ny][nx] = movingTile;
            } else {
                _screen[ny][nx] = finalTile;
            }

            if (!keepOriginal) {
                _screen[y][x] = leftTile;
            }

            self.animationCount++;
            // NSLog(@"animationCount %d\n", self.animationCount);

            if (self.animationCount == 1) {
                //  NSLog(@"Animations started");
                //  self.view.userInteractionEnabled = NO;
                if (self.delegate) {
                    [self.delegate animationsStarted];
                }
            }

            // NSLog(@"%d %c sound1 %c\n",self.animationCount, ch, sound);
            // int count = self.animationCount;
            [self animateMove:movingTile toX:nx toY:ny over:toTile.sprite replace:spriteLeft
                    finalTile:finalTile
                         hint:hint
                   completion:^{
                       //NSLog(@"%d %c sound2 %c\n", count, ch, sound);

                       // movingTile needs to be referenced here
                       // this is just to keep a reference to movingTile, so it will not be
                       // dealloc'd before this is run.  This will stop the animation otherwise.
                       char ch = movingTile.ch;
                       ch++;

                       // toTile needs to be referenced here - it'll naturally get destroyed.

                       if (toTile) {
                           ch = toTile.ch;
                           ch++;
                       }

                       self.animationCount--;

                       if (self.animationCount == 0) {
                           // self.view.userInteractionEnabled = YES;
                           //NSLog(@"Animations all completed\n");
                           if (self.delegate) {
                               [self.delegate animationsDone];
                           }
                       }

                       [self ad_sound:sound];
                   }];
        }
    }
}

- (void)ad_draw_atY:(int)y X:(int)x ch:(char)ch {
    if (y < kBoardHeight && x < kBoardWidth) {
        WandererTile *old = _screen[y][x];

        if (ch == ' ') {
            _screen[y][x] = nil;
        } else {
            WandererTile *tile = [WandererTile tileFromCh:ch];
            tile.sprite.position = [self pointForColumn:x row:y];
            [self.boardLayer addChild:tile.sprite];
            _screen[y][x] = tile;
        }

        if (old) {
            old.sprite.hidden = YES;
        }
    }
}

- (void)ad_init_atY:(int)y X:(int)x ch:(char)ch {
    if (y < kBoardHeight && x < kBoardWidth) {
        WandererTile *old = _screen[y][x];

        if (ch == ' ') {
            _screen[y][x] = nil;
        } else {
            WandererTile *tile = [WandererTile initTileFromCh:ch];
            _screen[y][x] = tile;
        }

        if (old) {
            old.sprite.hidden = YES;
        }
    }
}

- (void)ad_init_completed {
    for (int y = 0; y < kBoardHeight; y++) {
        for (int x = 0; x < kBoardWidth; x++) {
            WandererTile *tile = _screen[y][x];
            WandererTile *left = x > 0 ? _screen[y][x - 1] : nil;
            WandererTile *right = x < (kBoardWidth - 1) ? _screen[y][x + 1] : nil;
            WandererTile *up =    y > 0 ? _screen[y - 1][x] : nil;
            WandererTile *down =  y < (kBoardHeight - 1) ? _screen[y + 1][x] : nil;

            if (tile.sprite) {
                [tile.sprite removeFromParent];
            }

            if (tile) {
                [tile initSpriteWithNeighbors:TileNeighborsMake(tile.ch,
                                                                left ? left.ch : 0,
                                                                right ? right.ch : 0,
                                                                up ? up.ch : 0,
                                                                down ? down.ch : 0)];

                tile.sprite.position = [self pointForColumn:x row:y];
                [self.boardLayer addChild:tile.sprite];
            }
        }
    }

    [self updateDiamonds];
    [self updateMonster];
}

- (bool)runSyncOnMainQueueWithoutDeadlocking:(void (^)(void))block {
    static dispatch_once_t onceTokenAndKey;
    static void *contextValue = (void *)1;

    dispatch_once(&onceTokenAndKey, ^{
        dispatch_queue_main_t queue = dispatch_get_main_queue();
        dispatch_queue_set_specific(queue, &onceTokenAndKey, contextValue, NULL);
    });

    bool background = NO;

    if (dispatch_get_specific(&onceTokenAndKey) == contextValue) {
        block();
    } else {
        background = YES;
        dispatch_sync(dispatch_get_main_queue(), block);
    }

    return background;
}

- (bool)updateLabel:(UILabel *)label attributedText:(NSAttributedString *)text {
    return [self runSyncOnMainQueueWithoutDeadlocking:^{
                     if (label) {
                     label.attributedText = text;
                     }
                 }];
}

- (bool)updateLabel:(UILabel *)label text:(NSString *)text {
    return [self runSyncOnMainQueueWithoutDeadlocking:^{
                     if (label) {
                     label.text = text;
                     }
                 }];
}

- (void)ad_refresh {
}

- (void)ad_score:(long)score {
    [self updateLabel:self.scoreLabel text:[NSString stringWithFormat:@"Screen score: %ld", score]];
}

- (void)ad_diamondsNotFound:(int)nf total:(int)total {
    self.cached_ad_diamonds_nf = nf;
    self.cached_ad_diamonds_total = total;

    [self updateDiamonds];
}

- (void)updateDiamonds {
    WandererTile *tile = [WandererTile initTileFromCh:kChMoney];

    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];

    attachment.image = tile.image;

    __block CGSize neededSize = CGSizeMake(0, 0);

    NSString *count = [NSString stringWithFormat:@": %d/%d", self.cached_ad_diamonds_nf, self.cached_ad_diamonds_total];

    [self runSyncOnMainQueueWithoutDeadlocking:^{
              if (self.diamondsLabel) {
              self.diamondsLabel.text = count;
              neededSize = [self.diamondsLabel sizeThatFits:CGSizeMake(500, CGFLOAT_MAX)];
              }
          }];

    const CGFloat margin = 2;
    CGFloat h = neededSize.height - margin * 2;

    attachment.bounds = CGRectMake(0, -margin, kTileWidth * h / kTileHeight, h);

    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];

    NSMutableAttributedString *myString = [[NSMutableAttributedString alloc] init];

    [myString appendAttributedString:attachmentString];



    [myString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:count]];

    [self updateLabel:self.diamondsLabel attributedText:myString];

    if (self.cached_ad_diamonds_total == self.cached_ad_diamonds_nf) {
        int x;

        for (int y = 0; y < kBoardHeight; y++) {
            for (x = 0; x < kBoardWidth; x++) {
                WandererTile *old = _screen[y][x];

                if (old != nil && old.ch == kChExit) {
                    SKTexture *original = old.sprite.texture;
                    WandererTextureFactory *factory = nil;

                    factory = [WandererTile specialFactory:kHighlightedExit];

                    SKTexture *highlight = [factory getTexture:NoTileNeighbors(kChExit)];

                    SKAction *wait0 = [SKAction waitForDuration:0.33];

                    SKAction *block0 = [SKAction runBlock:^{
                                                     old.sprite.texture = original;
                                                 }];

                    SKAction *block1 = [SKAction runBlock:^{
                                                     old.sprite.texture = highlight;
                                                 }];

                    old.sprite.zPosition = -50;

                    [old.sprite runAction:[SKAction repeatActionForever:[SKAction sequence:@[wait0, block0, wait0, block1]]]];

                    self.homeSprite = old.sprite;

                    break;
                }
            }
        }
    }
}

- (void)ad_maxmoves:(int)maxmoves {
    if (maxmoves >= 0) {
        [self updateLabel:self.maxMovesLabel text:[NSString stringWithFormat:@"Max moves: %d", maxmoves]];
    } else {
        [self updateLabel:self.maxMovesLabel text:@"Unlimited moves"];
        self.maxMovesLabel.text = @"Unlimited moves";
    }
}

- (void)ad_monster:(int)monster {
    self.cached_ad_monster = monster != 0;
    [self updateMonster];
}

- (void)updateMonster {
    if (self.cached_ad_monster) {
        WandererTile *tile = [WandererTile initTileFromCh:kChMonster];

        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = tile.image;
        attachment.bounds = CGRectMake(0, 0, tile.image.size.width * 0.8, tile.image.size.height * 0.8);

        NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];

        NSMutableAttributedString *myString = [[NSMutableAttributedString alloc] initWithString:@""];
        [myString appendAttributedString:attachmentString];

        [self updateLabel:self.monsterLabel attributedText:myString];
    } else {
        [self updateLabel:self.monsterLabel text:@""];
    }
}

- (void)updateName {
    NSMutableString *screenName = [NSMutableString string];

    if (self.screenPrefix) {
        [screenName appendString:self.screenPrefix];
    } else {
        [screenName appendString:@"Screen "];
    }

    [screenName appendString:[Screens.sharedInstance visableScreenNameFromNum:self.screenNumber]];

    if (self.screenName != nil && self.screenName.length != 0) {
        [screenName appendString:@": "];
        [screenName appendString:self.screenName];
    }

    [self updateLabel:self.nameLabel text:screenName];
}

- (void)ad_screen_number:(int)n {
    self.screenNumber = n;

    [self updateName];
}

- (void)ad_screen_name:(char *)name {
    self.screenName = [NSString stringWithFormat:@"%s", name];
    [self updateName];
}

- (void)ad_teleport {
    FACTORIES *factories =  [WandererTile getFactoriesForStyle:WandererTile.style];

    [self replace:kChPlayer with:factories[@(kChPlayer)]
         flashing:[WandererTile specialFactory:kTeleportedPlayer]];

    self.normalFlashing = YES;
}

@end
