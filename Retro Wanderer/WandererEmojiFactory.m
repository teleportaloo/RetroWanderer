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

#import "WandererEmojiFactory.h"
#import "WandererTile.h"

@implementation WandererEmojiFactory

+ (instancetype)withEmoji:(NSString *)emoji
{
    WandererEmojiFactory *e = [[[self class] alloc] init];
    e.emoji = emoji;
    
    return e;
}

+ (instancetype)withEmoji:(NSString *)emoji fg:(UIColor *)fgColor
{
    WandererEmojiFactory *e = [[[self class] alloc] init];
    e.emoji = emoji;
    e.fgColor = fgColor;
    
    return e;
}

+ (instancetype)withEmoji:(NSString *)emoji bg:(UIColor *)bgColor
{
    WandererEmojiFactory *e = [[[self class] alloc] init];
    e.emoji = emoji;
    e.bgColor = bgColor;
    
    return e;
}

- (UIImage *)getImage:(char)ch left:(char)left right:(char)right up:(char)up down:(char)down
{
    UIImage * image = [self simpleCharacterTileImage:self.emoji
                                                  bg:self.bgColor
                                                  fg:self.fgColor];
    
    return image;
}

@end
