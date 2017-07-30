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

#import <SpriteKit/SpriteKit.h>

#define kTileWidth    28
#define kTileHeight   32

@class WandererTextureFactory;

@interface WandererTile : NSObject

@property (assign, nonatomic) char ch;
@property (strong, nonatomic) SKSpriteNode *sprite;

+ (instancetype)tileFromCh:(char) ch;
+ (instancetype)initTileFromCh:(char)ch;
- (void)initSpriteWithNeighborsLeft:(char)left right:(char)right up:(char)up down:(char)down;
+ (void)setRetro:(bool)newRetro;
+ (bool)retro;
+ (void)replaceFactory:(char)ch with:(WandererTextureFactory *)tile;
- (UIImage *)image;


@end
