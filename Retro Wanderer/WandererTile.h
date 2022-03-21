/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import "TileNeighbors.h"

#import <SpriteKit/SpriteKit.h>

@class WandererTextureFactory;

#define kTileWidth  28
#define kTileHeight 32

#define kTileRect   CGRectMake(0, 0, kTileWidth, kTileHeight)

typedef enum eTileStyle {
    kStyleNone          = -1,
    kStyleRetro         =  0,
    kStyleDos           =  1,
    kStyleEmoji         =  2,
    kStyleEmojiTextures =  3
} tileStyle;



#define kChPlayer  '@'
#define kChMonster 'M'
#define kChMine    '!'
#define kChMoney   '*'
#define kChLeft    '<'
#define kChRight   '>'
#define kChExit    'X'
#define kChBaby    'S'
#define kChCage    '+'
#define kChTrans   'T'
#define kChBalloon '^'
#define kChClock   'C'
#define kChEarth   ':'
#define kChGranite '#'
#define kChHoriz   '-'
#define kChBrick   '='
#define kChSide    '|'
#define kChRampB   '\\'
#define kChRampF   '/'
#define kChRock    'O'


typedef enum {
    kHighlightedExit   = 1000,
    kPlaybackPLayer    = 1001,
    kHappyPlayer       = 1002,
    kDeadPlayer        = 1003,
    kFlashingPlayer    = 1004,
    kHighlightedPlayer = 1005,
    kTeleportedPlayer  = 1006,
    kNormalPlayer      = kChPlayer,
    kNormalExit        = kChExit
} kSpecialTiles;

typedef NSMutableDictionary<NSNumber *, WandererTextureFactory *> FACTORIES;

@class WandererTextureFactory;

@interface WandererTile : NSObject

@property (assign, nonatomic) char ch;
@property (strong, nonatomic) SKSpriteNode *sprite;

+ (instancetype)tileFromCh:(char)ch;
+ (instancetype)initTileFromCh:(char)ch;
- (void)initSpriteWithNeighbors:(TileNeighbors)neighbors;
+ (void)setStyle:(tileStyle)newStyle;
+ (tileStyle)style;
+ (void)replaceFactory:(char)ch with:(WandererTextureFactory *)tile;
+ (WandererTextureFactory *)specialFactory:(NSInteger)ch;
- (UIImage *)image;
+ (FACTORIES *)getFactoriesForStyle:(tileStyle)style;
+ (FACTORIES *)getSpecialFactoriesForStyle:(tileStyle)style;

@end
