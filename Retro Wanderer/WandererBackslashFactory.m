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

#import "WandererBackslashFactory.h"
#import "WandererTile.h"

@implementation WandererBackslashFactory

+ (instancetype)slash
{
    WandererBackslashFactory *slash = [[[self class] alloc] init];
    
    return slash;
}


+ (UIImage*)drawBackslash
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(kTileWidth, kTileHeight), NO, 0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [UIColor brownColor].CGColor);
    CGContextSetLineWidth(context, 2.0);
    
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, kTileWidth, kTileHeight);
    CGContextStrokePath(context);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (UIImage *)getImage:(char)ch left:(char)left right:(char)right up:(char)up down:(char)down
{
    return [WandererBackslashFactory drawBackslash];
}




@end
