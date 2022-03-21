/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "WandererTile.h"
#import "WandererEmojiFactory.h"
#import "WandererCageFactory.h"
#import "WandererBlockFactory.h"
#import "WandererBackslashFactory.h"
#import "WandererForwardSlashFactory.h"
#import "WandererTextureFromFileFactory.h"
#include "DebugLogging.h"

static tileStyle currentStyle = kStyleEmoji;
static NSMutableDictionary<NSNumber *, SKTexture *> *textures = nil;

@implementation WandererTile

+ (void)setStyle:(tileStyle)newStyle {
    if (currentStyle != newStyle) {
        textures = [NSMutableDictionary dictionary];
    }

    currentStyle = newStyle;

    [WandererTile replaceFactory:kChPlayer with:[WandererTile specialFactory:kNormalPlayer]];
    [WandererTile replaceFactory:kChExit with:[WandererTile specialFactory:kNormalExit]];
}

- (instancetype)init {
    if ((self = [super init])) {
        [self initCaches];
        return self;
    }

    return nil;
}

+ (tileStyle)style {
    return currentStyle;
}

- (void)dealloc {
    if (self.sprite) {
        [self.sprite removeFromParent];
        DEBUG_LOGS(self.sprite.name);
    }
}

+ (instancetype)initTileFromCh:(char)ch {
    WandererTile *tile = [[[self class] alloc] init];

    tile.ch = ch;
    return tile;
}

+ (WandererTextureFactory *)specialFactory:(NSInteger)ch {
    FACTORIES *factories = [WandererTile getSpecialFactoriesForStyle:currentStyle];
    WandererTextureFactory *factory = nil;

    if (factories != nil) {
        factory = factories[@(ch)];

        if (factory == nil) {
            if (ch == kHighlightedExit) {
                factory = factories[@(kChExit)];
            } else {
                factory = factories[@(kChPlayer)];
            }
        }
    }

    if (factory == nil) {
        return [[WandererTextureFactory alloc] init];
    }

    return factory;
}

+ (void)replaceFactory:(char)ch with:(WandererTextureFactory *)tile {
    FACTORIES *factories =  [WandererTile getFactoriesForStyle:currentStyle];

    if (factories != nil) {
        factories[@(ch)] = tile;
        [textures removeObjectForKey:[tile key:NoTileNeighbors(ch)]];
    }
}

#define HTML_COLOR(X) [UIColor colorWithRed:((X) >> 16) / 255.0 green:(((X) >> 8) & 0xFF) / 255.0 blue:((X) & 0xFF) / 255.0 alpha:1.0]

+ (FACTORIES *)getFactoriesForStyle:(tileStyle)style {
    return [WandererTile getFactoriesForStyle:style special:NO];
}

+ (FACTORIES *)getSpecialFactoriesForStyle:(tileStyle)style {
    return [WandererTile getFactoriesForStyle:style special:YES];
}

+ (FACTORIES *)getFactoriesForStyle:(tileStyle)style special:(bool)special {
    static FACTORIES *factoryStyle;
    static FACTORIES *specialStyle;
    static tileStyle lastStyle = kStyleNone;
    UIColor *leftColor = [UIColor magentaColor];
    UIColor *rightColor = [UIColor orangeColor];

    if (style != lastStyle) {
        textures = [NSMutableDictionary dictionary];
    }

    if (style != lastStyle || factoryStyle == nil) {
        lastStyle = style;
        switch (style) {
            case kStyleNone:
            case kStyleRetro: {
                WandererTextureFactory *player = [WandererEmojiFactory withEmoji:@"@"];
                specialStyle = @{
                    @(kHighlightedExit): [WandererEmojiFactory withEmoji:@"X" bg:[UIColor whiteColor]],
                    @(kNormalExit): [WandererEmojiFactory withEmoji:@"X"],
                    @(kHighlightedPlayer): [WandererEmojiFactory withEmoji:@"@" bg:[UIColor whiteColor]],
                    @(kTeleportedPlayer): [WandererEmojiFactory withEmoji:@"@" bg:[UIColor cyanColor]],
                    @(kPlaybackPLayer): [WandererEmojiFactory withEmoji:@"@"],
                    @(kFlashingPlayer): player,
                    @(kHappyPlayer): [WandererEmojiFactory withEmoji:@"@"],
                    @(kDeadPlayer): [WandererEmojiFactory withEmoji:@"@"],
                    @(kNormalPlayer): player
                }.mutableCopy;

                factoryStyle = nil;
                break;
            }

            case kStyleEmojiTextures: {
                WandererTextureFactory *player = [WandererEmojiFactory withEmoji:@"😀"];

                specialStyle = @{
                    @(kHighlightedExit): [WandererEmojiFactory withEmoji:@"🏠" bg:[UIColor whiteColor]],
                    @(kNormalExit): [WandererEmojiFactory withEmoji:@"🏠"],
                    @(kHighlightedPlayer): [WandererEmojiFactory withEmoji:@"😀" bg:[UIColor whiteColor]],
                    @(kTeleportedPlayer): [WandererEmojiFactory withEmoji:@"😲" bg:[UIColor cyanColor]],
                    @(kPlaybackPLayer): [WandererEmojiFactory withEmoji:@"😎"],
                    @(kFlashingPlayer): player,
                    @(kHappyPlayer): [WandererEmojiFactory withEmoji:@"🤠"],
                    @(kDeadPlayer): [WandererEmojiFactory withEmoji:@"💀"],
                    @(kNormalPlayer): player
                }.mutableCopy;

                factoryStyle = @{
                    @(kChPlayer): player,
                    @(kChMonster): [WandererEmojiFactory withEmoji:@"👹"],
                    @(kChMine): [WandererTextureFromFileFactory withFileName:@"dynamite.png"],
                    @(kChMoney): [WandererEmojiFactory withEmoji:@"💎"],
                    @(kChLeft): [WandererEmojiFactory withEmoji:@"←" fg:leftColor],
                    @(kChRight): [WandererEmojiFactory withEmoji:@"→" fg:rightColor],
                    @(kChExit): [WandererEmojiFactory withEmoji:@"🏠"],
                    @(kChBaby): [WandererEmojiFactory withEmoji:@"👻"],
                    @(kChCage): [WandererCageFactory withEmoji:@"💎"],
                    @(kChTrans): [WandererEmojiFactory withEmoji:@"🚪"],
                    @(kChBalloon): [WandererEmojiFactory withEmoji:@"🎈"],
                    @(kChClock): [WandererEmojiFactory withEmoji:@"⏱"],
                    @(kChEarth): [WandererEmojiFactory withEmoji:@"▩" fg:HTML_COLOR(0xB5A642)],
                    @(kChGranite): [WandererBlockFactory withFg:[WandererTextureFactory borderColor] fileName:@"granite.gif"],
                    @(kChBrick): [WandererBlockFactory withFg:[WandererTextureFactory borderColor] fileName:@"brick.gif"],
                    @(kChHoriz): [WandererBlockFactory withFg:[WandererTextureFactory borderColor] fileName:@"granite.gif"],
                    @(kChSide): [WandererBlockFactory withFg:[WandererTextureFactory borderColor] fileName:@"granite.gif"],
                    @(kChRampB): [WandererBackslashFactory slash],
                    @(kChRampF): [WandererForwardSlashFactory slash],
                    @(kChRock): [WandererTextureFromFileFactory withFileName:@"new_rock.png"]
                }.mutableCopy;
                break;
            }

            case kStyleEmoji: {
                WandererTextureFactory *player = [WandererEmojiFactory withEmoji:@"😀"];

                specialStyle = @{
                    @(kHighlightedExit): [WandererEmojiFactory withEmoji:@"🏠" bg:[UIColor whiteColor]],
                    @(kNormalExit): [WandererEmojiFactory withEmoji:@"🏠"],
                    @(kHighlightedPlayer): [WandererEmojiFactory withEmoji:@"😀" bg:[UIColor whiteColor]],
                    @(kTeleportedPlayer): [WandererEmojiFactory withEmoji:@"😲" bg:[UIColor cyanColor]],
                    @(kPlaybackPLayer): [WandererEmojiFactory withEmoji:@"😎"],
                    @(kFlashingPlayer): player,
                    @(kHappyPlayer): [WandererEmojiFactory withEmoji:@"🤠"],
                    @(kDeadPlayer): [WandererEmojiFactory withEmoji:@"💀"],
                    @(kNormalPlayer): player
                }.mutableCopy;

                factoryStyle = @{
                    @(kChPlayer): player,
                    @(kChMonster): [WandererEmojiFactory withEmoji:@"👹"],
                    @(kChMine): [WandererTextureFromFileFactory withFileName:@"dynamite.png"],
                    @(kChMoney): [WandererEmojiFactory withEmoji:@"💎"],
                    @(kChLeft): [WandererEmojiFactory withEmoji:@"←" fg:leftColor],
                    @(kChRight): [WandererEmojiFactory withEmoji:@"→" fg:rightColor],
                    @(kChExit): [WandererEmojiFactory withEmoji:@"🏠"],
                    @(kChBaby): [WandererEmojiFactory withEmoji:@"👻"],
                    @(kChCage): [WandererCageFactory withEmoji:@"💎"],
                    @(kChTrans): [WandererEmojiFactory withEmoji:@"🚪"],
                    @(kChBalloon): [WandererEmojiFactory withEmoji:@"🎈"],
                    @(kChClock): [WandererEmojiFactory withEmoji:@"⏱"],
                    @(kChEarth): [WandererEmojiFactory withEmoji:@"◼︎" fg:HTML_COLOR(0xB5A642)],
                    @(kChGranite): [WandererBlockFactory withBg:[WandererTextureFactory fillColor:kChGranite]  fg:[WandererTextureFactory borderColor]],
                    @(kChHoriz): [WandererBlockFactory withBg:[WandererTextureFactory fillColor:kChHoriz]    fg:[WandererTextureFactory borderColor]],
                    @(kChBrick): [WandererBlockFactory withBg:[WandererTextureFactory fillColor:kChBrick]    fg:[WandererTextureFactory borderColor]],
                    @(kChSide): [WandererBlockFactory withBg:[WandererTextureFactory fillColor:kChSide]     fg:[WandererTextureFactory borderColor]],
                    @(kChRampB): [WandererBackslashFactory slash],
                    @(kChRampF): [WandererForwardSlashFactory slash],
                    @(kChRock): [WandererTextureFromFileFactory withFileName:@"new_rock.png"]
                }.mutableCopy;
                break;
            }

            case kStyleDos: {
                WandererTextureFactory *player = [WandererTextureFromFileFactory withFileName:@"player.gif"];

                specialStyle = @{
                    @(kHighlightedExit): [WandererTextureFromFileFactory withFileName:@"exitH.gif"],
                    @(kNormalExit): [WandererTextureFromFileFactory withFileName:@"exit.gif"],
                    @(kHighlightedPlayer): [WandererTextureFromFileFactory withFileName:@"playerH.gif"],
                    @(kPlaybackPLayer): [WandererTextureFromFileFactory withFileName:@"playerA.gif"],
                    @(kFlashingPlayer): [WandererTextureFromFileFactory withFileName:@"playerH.gif"],
                    @(kTeleportedPlayer): [WandererTextureFromFileFactory withFileName:@"playerH.gif"],
                    @(kHappyPlayer): [WandererTextureFromFileFactory withFileName:@"playerH.gif"],
                    @(kDeadPlayer): [WandererTextureFromFileFactory withFileName:@"playerD.gif"],
                    @(kNormalPlayer): player
                }.mutableCopy;

                WandererTextureFactory *granite = [WandererTextureFromFileFactory withFileName:@"granite.gif"];

                factoryStyle = @{
                    @(kChPlayer): player,
                    @(kChMonster): [WandererTextureFromFileFactory withFileName:@"monster.gif"],
                    @(kChMine): [WandererTextureFromFileFactory withFileName:@"mine.gif"],
                    @(kChMoney): [WandererTextureFromFileFactory withFileName:@"money.gif"],
                    @(kChLeft): [WandererTextureFromFileFactory withFileName:@"arrowL.gif"],
                    @(kChRight): [WandererTextureFromFileFactory withFileName:@"arrowR.gif"],
                    @(kChExit): [WandererTextureFromFileFactory withFileName:@"exit.gif"],
                    @(kChBaby): [WandererTextureFromFileFactory withFileName:@"babyMonster.gif"],
                    @(kChCage): [WandererTextureFromFileFactory withFileName:@"cage.gif"],
                    @(kChTrans): [WandererTextureFromFileFactory withFileName:@"teleporter.gif"],
                    @(kChBalloon): [WandererTextureFromFileFactory withFileName:@"balloon.gif"],
                    @(kChClock): [WandererTextureFromFileFactory withFileName:@"time.gif"],
                    @(kChEarth): [WandererTextureFromFileFactory withFileName:@"dirt.gif"],
                    @(kChGranite): granite,
                    @(kChHoriz): granite,
                    @(kChBrick): [WandererTextureFromFileFactory withFileName:@"brick.gif"],
                    @(kChSide): granite,
                    @(kChRampB): [WandererTextureFromFileFactory withFileName:@"rampR.gif"],
                    @(kChRampF): [WandererTextureFromFileFactory withFileName:@"rampL.gif"],
                    @(kChRock): [WandererTextureFromFileFactory withFileName:@"rock.gif"]
                }.mutableCopy;
                break;
            }
        }
    }

    return special ? specialStyle : factoryStyle;
}

- (void)initCaches {
}

- (UIImage *)image {
    WandererTextureFactory *factory = nil;

    FACTORIES *factories = [WandererTile getFactoriesForStyle:currentStyle];

    if (factories == nil) {
        factory = [[WandererTextureFactory alloc] init];
    } else {
        factory = factories[@(self.ch)];
    }

    if (factory == nil) {
        factory = [[WandererTextureFactory alloc] init];
    }

    return [factory getImage:NoTileNeighbors(self.ch)];
}

- (void)initSpriteWithNeighbors:(TileNeighbors)neighbors {
    WandererTextureFactory *factory = nil;

    FACTORIES *factories = [WandererTile getFactoriesForStyle:currentStyle];

    if (factories == nil) {
        factory = [[WandererTextureFactory alloc] init];
    } else {
        factory = factories[@(self.ch)];
    }

    if (factory == nil) {
        factory = [[WandererTextureFactory alloc] init];
    }

    NSNumber *key = [factory key:neighbors];
    SKTexture *texture = textures[key];

    if (texture == nil) {
        texture = [factory getTexture:neighbors];
        textures[key] = texture;
        // NSLog(@"Textures %d\n", (int)textures.count);
    }

    self.sprite = [SKSpriteNode spriteNodeWithTexture:texture];



#ifdef DEBUGLOGGING
    static NSInteger count = 0;
    self.sprite.name = [NSString stringWithFormat:@"%c%ld", self.ch, (long)count++];
#endif
}

+ (instancetype)tileFromCh:(char)ch {
    WandererTile *tile = [[self class] initTileFromCh:ch];

    [tile initSpriteWithNeighbors:NoTileNeighbors(ch)];

    return tile;
}

@end
