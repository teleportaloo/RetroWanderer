/***************************************************************************
 *  Copyright 2017 -   Andrew Wallace                                       *
 *                                                                          *
 *  This program is free software; you can redistribute it and/or modify    *
 *  it under the terms of the GNU General Public License as published by    *
 *  the Free Software Foundation; either version 2 of the License, or       *
 *  (at your option) any later version.                                     *
 *                                                                          *
 *  This program is distributed in the hope that it will be useful,         *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of          *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           *
 *  GNU General Public License for more details.                            *
 *                                                                          *
 *  You should have received a copy of the GNU General Public License       *
 *  along with this program; if not, write to the Free Software             *
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA               *
 *  02111-1307, USA.                                                        *
 ***************************************************************************/

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

@interface SpriteDisplay : NSObject <AbstractedDisplay>
{
    WandererTile *_screen[kBoardHeight][kBoardWidth];
    bool _cancelling;
}

@property (weak, nonatomic)  id<SpriteDisplayDelegate> delegate;
@property (strong, nonatomic) SKNode *boardLayer;
@property (weak, nonatomic)   UIView *view;
@property (nonatomic, retain) UILabel* scoreLabel;
@property (nonatomic, retain) UILabel* diamondsLabel;
@property (nonatomic, retain) UILabel* maxMovesLabel;
@property (nonatomic, retain) UILabel* monsterLabel;
@property (nonatomic, retain) UILabel* nameLabel;
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
@property (nonatomic, retain) NSMutableDictionary<NSNumber *, SKAction*> *fastMoveCache;
@property (nonatomic) int cacheHits;
@property (nonatomic, copy) NSString *screenPrefix;
@property (nonatomic) int screenNumber;



- (void)deadPlayer;
- (void)sunglassesPlayer;
- (void)normalPlayer;
- (void)flashingPlayer;
- (void)happyPlayer;
- (void)runSequenceWithCompletion:(dispatch_block_t)sequenceCompletionBlock;
- (void)cancelSequenceWithCompletion:(dispatch_block_t)sequenceCancellationBlock;
- (void)updateName;

@end
