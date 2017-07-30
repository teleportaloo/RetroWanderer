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

#import "WandererTextureFactory.h"
#import "WandererTile.h"

@implementation WandererTextureFactory

+ (instancetype)texture
{
    return [[[self class] alloc] init];
}

- (SKTexture *)getTexture:(char)ch left:(char)left right:(char)right up:(char)up down:(char)down
{
    return [SKTexture textureWithImage:[self getImage:ch left:left right:right up:up down:down]];
}


- (UIImage *)getImage:(char)ch left:(char)left right:(char)right up:(char)up down:(char)down
{
    unichar uch = ch;
    UIImage * image = [self simpleCharacterTileImage:[NSString stringWithCharacters:&uch length:1]
                                                  bg:nil
                                                  fg:nil];
    
    return image;
}

- (void)additionalDrawing
{
    
}


-(UIImage*)simpleCharacterTileImage:(NSString *)text bg:(UIColor *)bg fg:(UIColor *)fg
{
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(kTileWidth, kTileHeight), NO, 0);
    CGRect rect = CGRectMake(0, 0, kTileWidth, kTileHeight);
    
    if (bg!=nil)
    {
        [bg set];
        UIRectFill(rect);
    }
    
    // if (bg == nil || fg!=nil)
    {
        
        UIFont *font = nil;
        
        if ([text characterAtIndex:0] < 128)
        {
            font = [UIFont systemFontOfSize:26];
        }
        else
        {
            font = [UIFont systemFontOfSize:22];

        }
        if (fg == nil)
        {
            fg = [UIColor whiteColor];
        }

        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        
        NSDictionary *attributes = @{NSFontAttributeName:font, NSForegroundColorAttributeName:fg, NSParagraphStyleAttributeName:paragraphStyle};
        CGSize textSize = [text sizeWithAttributes: attributes];
        CGRect textRect = CGRectMake((kTileWidth - textSize.width)/2, (kTileHeight-textSize.height)/2, textSize.width, textSize.height );
        [text drawInRect:textRect withAttributes:attributes];
    }
    
    [self additionalDrawing];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (NSNumber *)key:(char)ch left:(char)left right:(char)right up:(char)up down:(char)down
{
    return @(ch);
}


@end
