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

#import "WandererBlockFactory.h"
#import "WandererTile.h"

@implementation WandererBlockFactory

+ (instancetype)withBg:(UIColor *)bgColor fg:(UIColor*)fgColor
{
    WandererBlockFactory *block = [[[self class] alloc] init];
    block.bgColor = bgColor;
    block.fgColor = fgColor;
    
    return block;
}


+(UIImage*)roundedBlock:(UIColor *)bg ch:(char)ch left:(char)left right:(char)right up:(char)up down:(char)down fg:(UIColor*)fg
{
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(kTileWidth, kTileHeight), NO, 0);
    CGRect rect = CGRectMake(0, 0, kTileWidth, kTileHeight);
    
    const CGFloat cornerRadius = 10;
    
    if (bg!=nil)
    {
        [bg set];

        CGMutablePathRef path = CGPathCreateMutable();
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        
        
        // get the 4 corners of the rect
        CGPoint topLeft = CGPointMake(rect.origin.x, rect.origin.y);
        CGPoint topRight = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y);
        CGPoint bottomRight = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
        CGPoint bottomLeft = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
        
        // move to top left
        if (left!=ch && up!=ch)
        {
            CGPathMoveToPoint(path, NULL, topLeft.x + cornerRadius, topLeft.y);
        }
        else
        {
            CGPathMoveToPoint(path, NULL, topLeft.x, topLeft.y);
            CGPathAddLineToPoint(path, NULL, topLeft.x + cornerRadius, topRight.y);
        }
        
        // add top line
        CGPathAddLineToPoint(path, NULL, topRight.x - cornerRadius, topRight.y);
        
        if (right!=ch && up!=ch)
        {
            // add top right curve
            CGPathAddQuadCurveToPoint(path, NULL, topRight.x, topRight.y, topRight.x, topRight.y + cornerRadius);
        }
        else
        {
            CGPathAddLineToPoint(path, NULL, topRight.x, topRight.y);
            CGPathAddLineToPoint(path, NULL, topRight.x, topRight.y + cornerRadius);
        }
        
        // add right line
        CGPathAddLineToPoint(path, NULL, bottomRight.x, bottomRight.y - cornerRadius);
        
        if (right!=ch && down!=ch)
        {
            // add bottom right curve
            CGPathAddQuadCurveToPoint(path, NULL, bottomRight.x, bottomRight.y, bottomRight.x - cornerRadius, bottomRight.y);
        }
        else
        {
            CGPathAddLineToPoint(path, NULL, bottomRight.x, bottomRight.y);
            CGPathAddLineToPoint(path, NULL, bottomRight.x - cornerRadius, bottomRight.y);
        }
        
        // add bottom line
        CGPathAddLineToPoint(path, NULL, bottomLeft.x + cornerRadius, bottomLeft.y);
        
        if (down!=ch && left!=ch)
        {
            // add bottom left curve
            CGPathAddQuadCurveToPoint(path, NULL, bottomLeft.x, bottomLeft.y, bottomLeft.x, bottomLeft.y - cornerRadius);
        }
        else
        {
            CGPathAddLineToPoint(path, NULL, bottomLeft.x, bottomLeft.y);
            CGPathAddLineToPoint(path, NULL, bottomLeft.x, bottomLeft.y - cornerRadius);
        }
        
        // add left line
        CGPathAddLineToPoint(path, NULL, topLeft.x, topLeft.y + cornerRadius);
        
        if (left!=ch && up!=ch)
        {
            // add top left curve
            CGPathAddQuadCurveToPoint(path, NULL, topLeft.x, topLeft.y, topLeft.x + cornerRadius, topLeft.y);
        }
        else
        {
            CGPathAddLineToPoint(path, NULL, topLeft.x, topLeft.y);
            CGPathAddLineToPoint(path, NULL, topLeft.x + cornerRadius, topLeft.y);
        }

        CGContextAddPath(context, path);
        CGContextSetFillColorWithColor(context, bg.CGColor);
        CGContextSetLineWidth(context, 1);
        CGContextClosePath(context);
        CGContextFillPath(context);
        CGPathRelease(path);
    }
    
    if (fg!=nil)
    {
        [fg set];
        
        CGMutablePathRef path = CGPathCreateMutable();
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // get the 4 corners of the rect
        CGPoint topLeft = CGPointMake(rect.origin.x, rect.origin.y);
        CGPoint topRight = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y);
        CGPoint bottomRight = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
        CGPoint bottomLeft = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);

#define MaybeLine(C, X, Y) if((C)) { CGPathAddLineToPoint(path, NULL, X, Y); } else { CGPathMoveToPoint(path, NULL, X, Y); }
        // move to top left
        if (left!=ch && up!=ch)
        {
            CGPathMoveToPoint(path, NULL, topLeft.x + cornerRadius, topLeft.y);
        }
        else
        {
            CGPathMoveToPoint(path, NULL, topLeft.x, topLeft.y);
            
            MaybeLine(up!=ch,topLeft.x + cornerRadius, topRight.y);
        }
        
        // add top line
        MaybeLine(up!=ch,topRight.x - cornerRadius, topRight.y);
        
        if (right!=ch && up!=ch)
        {
            // add top right curve
            CGPathAddQuadCurveToPoint(path, NULL, topRight.x, topRight.y, topRight.x, topRight.y + cornerRadius);
        }
        else
        {
            MaybeLine(up!=ch,    topRight.x, topRight.y);
            MaybeLine(right!=ch, topRight.x, topRight.y + cornerRadius);
        }
        
        // add right line
        MaybeLine(right!=ch,bottomRight.x, bottomRight.y - cornerRadius);
        
        if (right!=ch && down!=ch)
        {
            // add bottom right curve
            CGPathAddQuadCurveToPoint(path, NULL, bottomRight.x, bottomRight.y, bottomRight.x - cornerRadius, bottomRight.y);
        }
        else
        {
            
            MaybeLine(right!=ch, bottomRight.x, bottomRight.y);
            MaybeLine(down!=ch, bottomRight.x - cornerRadius, bottomRight.y);
        }
        
        // add bottom line
        MaybeLine(down!=ch, bottomLeft.x + cornerRadius, bottomLeft.y);
        
        if (down!=ch && left!=ch)
        {
            // add bottom left curve
            CGPathAddQuadCurveToPoint(path, NULL, bottomLeft.x, bottomLeft.y, bottomLeft.x, bottomLeft.y - cornerRadius);
        }
        else
        {
            MaybeLine(down!=ch, bottomLeft.x, bottomLeft.y);
            MaybeLine(left!=ch, bottomLeft.x, bottomLeft.y - cornerRadius);
        }
        
        // add left line
        MaybeLine(left!=ch, topLeft.x, topLeft.y + cornerRadius);
        
        if (left!=ch && up!=ch)
        {
            // add top left curve
            CGPathAddQuadCurveToPoint(path, NULL, topLeft.x, topLeft.y, topLeft.x + cornerRadius, topLeft.y);
        }
        else
        {
            MaybeLine(left!=ch, topLeft.x, topLeft.y);
            MaybeLine(up!=ch, topLeft.x + cornerRadius, topLeft.y);
        }
        
        CGContextAddPath(context, path);
        CGContextSetLineWidth(context, 1);
        CGContextDrawPath(context, kCGPathStroke);
        CGPathRelease(path);
    }
    
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}


- (UIImage *)getImage:(char)ch left:(char)left right:(char)right up:(char)up down:(char)down
{
    return [WandererBlockFactory roundedBlock:self.bgColor ch:ch left:left right:right up:up down:down fg:self.fgColor];
}

#define kLeftMask  0x1000
#define kRightMask 0x2000
#define kUpMask    0x4000
#define kDownMask  0x8000


- (NSNumber *)key:(char)ch left:(char)left right:(char)right up:(char)up down:(char)down
{
    long key = ch;
    
    if (left == ch)
    {
        key |= kLeftMask;
    }
    
    if (right == ch)
    {
        key |= kRightMask;
    }
    
    if (up == ch)
    {
        key |= kUpMask;
    }
    
    if (down == ch)
    {
        key |= kDownMask;
    }
    
    return @(key);
}

@end
