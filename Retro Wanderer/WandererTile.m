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

#import "WandererTile.h"
#import "WandererEmojiFactory.h"
#import "WandererCageFactory.h"
#import "WandererBlockFactory.h"
#import "WandererBackslashFactory.h"
#import "WandererForwardSlashFactory.h"
#import "WandererTextureFromFileFactory.h"
#include "DebugLogging.h"

static bool retro = NO;
static NSMutableDictionary<NSNumber *, SKTexture *> *textures = nil;
static NSMutableDictionary<NSNumber *, WandererTextureFactory *>  *factories;

@implementation WandererTile

+ (void)setRetro:(bool)newRetro
{
    if (retro != newRetro)
    {
        textures = nil;
    }
    retro = newRetro;
}

- (instancetype)init
{
    if ((self = [super init]))
    {
        [self initCaches];        
        return self;
    }
    
    return nil;
}

+ (bool)retro
{
    return retro;
}

- (void)dealloc
{
    if (self.sprite)
    {
        [self.sprite removeFromParent];
        DEBUG_LOGS(self.sprite.name);
    }
}

+ (instancetype)initTileFromCh:(char)ch
{
    WandererTile *tile = [[[self class] alloc] init];
    tile.ch = ch;
    return tile;
}

+ (void)replaceFactory:(char)ch with:(WandererTextureFactory *)tile
{
    factories[@(ch)] = tile;
    [textures removeObjectForKey:[tile key:ch left:0 right:0 up:0 down:0]];
}

#define HTML_COLOR(X) [UIColor colorWithRed:((X) >> 16)/255.0 green:(((X) >> 8)&0xFF)/255.0 blue:((X)&0xFF)/255.0 alpha:1.0]

- (void)initCaches
{
    static dispatch_once_t once;
    dispatch_once(&once, ^ {
        factories = @{
                       @'@':  [WandererEmojiFactory withEmoji:@"😀"],
                       @'M' : [WandererEmojiFactory withEmoji:@"👹"],
                       @'!' : [WandererTextureFromFileFactory withFileName:@"dynamite"],
                       @'*' : [WandererEmojiFactory withEmoji:@"💎"],
                       @'<' : [WandererEmojiFactory withEmoji:@"←" fgColor:[UIColor redColor]],
                       @'>' : [WandererEmojiFactory withEmoji:@"→" fgColor:[UIColor redColor]],
                       @'X' : [WandererEmojiFactory withEmoji:@"🏠"],
                       @'S' : [WandererEmojiFactory withEmoji:@"👻"],
                       @'+' : [WandererCageFactory  withEmoji:@"💎"],
                       @'T' : [WandererEmojiFactory withEmoji:@"🚪"],
                       @'^' : [WandererEmojiFactory withEmoji:@"🎈"],
                       @'C' : [WandererEmojiFactory withEmoji:@"⏱"],
                       @':' : [WandererEmojiFactory withEmoji:@"◼︎" fgColor:HTML_COLOR(0xB5A642)],
                       @'#' : [WandererBlockFactory withBg:[UIColor brownColor] fg:[UIColor grayColor]],
                       @'-' : [WandererBlockFactory withBg:[UIColor grayColor] fg:[UIColor whiteColor]],
                       @'=' : [WandererBlockFactory withBg:[UIColor darkGrayColor] fg:[UIColor grayColor]],
                       @'|' : [WandererBlockFactory withBg:[UIColor grayColor] fg:[UIColor whiteColor]],
                       @'\\': [WandererBackslashFactory slash],
                       @'/' : [WandererForwardSlashFactory slash],
                       @'O' : [WandererTextureFromFileFactory withFileName:@"rock"]
                        }.mutableCopy;
        
        textures = [[NSMutableDictionary alloc] init];

    });
    
}

- (UIImage *)image
{
    WandererTextureFactory *factory = nil;
    
    if (retro)
    {
        factory = [[WandererTextureFactory alloc] init];
    }
    else
    {
        factory = factories[@(self.ch)];
    }
    
    if (factory == nil)
    {
        factory = [[WandererTextureFactory alloc] init];
    }

    return [factory getImage:self.ch left:0 right:0 up:0 down:0];
}

- (void)initSpriteWithNeighborsLeft:(char)left right:(char)right up:(char)up down:(char)down
{
    WandererTextureFactory *factory = nil;
    
    if (retro)
    {
        factory = [[WandererTextureFactory alloc] init];
    }
    else
    {
        factory = factories[@(self.ch)];
    }
      
    if (factory == nil)
    {
        factory = [[WandererTextureFactory alloc] init];
    }
    
    NSNumber *key = [factory key:self.ch left:left right:right up:up down:down];
    SKTexture *texture = textures[key];
    
    if (texture == nil)
    {
        texture = [factory getTexture:self.ch left:left right:right up:up down:down];
        textures[key] = texture;
        // NSLog(@"Textures %d\n", (int)textures.count);
    }
    
    self.sprite = [SKSpriteNode spriteNodeWithTexture:texture];
    

    
#ifdef DEBUGLOGGING
    static NSInteger count = 0;
    self.sprite.name = [NSString stringWithFormat:@"%c%ld", self.ch, (long)count++];
#endif
}

+ (instancetype)tileFromCh:(char)ch
{
    WandererTile *tile = [[self class] initTileFromCh:ch];
    
    [tile initSpriteWithNeighborsLeft:NO right:NO up:NO down:NO];
    
    return tile;
}




@end
