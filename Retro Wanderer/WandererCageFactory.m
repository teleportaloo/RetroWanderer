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

#import "WandererCageFactory.h"
#import "WandererTile.h"

@implementation WandererCageFactory

#define kMargin 1
#define kBars   5
#define kGap    (kTileWidth / kBars)
#define kTop    (kMargin)
#define kBottom (kTileHeight - kMargin)


- (void)additionalDrawing
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [UIColor grayColor].CGColor);
    CGContextSetLineWidth(context, 1.5);
    
    CGContextMoveToPoint(context, kMargin, kMargin);
    CGContextAddLineToPoint(context, kTileWidth-2, 2);

    for (int x=0; x<= kBars; x++)
    {
        CGContextMoveToPoint(context, kMargin + x * kGap, kTop);
        CGContextAddLineToPoint(context, kMargin + x * kGap, kBottom);
    }
    
    CGContextMoveToPoint(context, kMargin, kBottom);
    CGContextAddLineToPoint(context, kTileWidth-2, kBottom);

    
    CGContextStrokePath(context);
    
}
@end
