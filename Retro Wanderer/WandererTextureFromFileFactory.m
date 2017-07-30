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

#import "WandererTextureFromFileFactory.h"

@implementation WandererTextureFromFileFactory

+ (instancetype)withFileName:(NSString *)fileName
{
    WandererTextureFromFileFactory *e = [[[self class] alloc] init];
    e.fileName = fileName;
    
    return e;
}

- (SKTexture *)getTexture:(char)ch left:(char)left right:(char)right up:(char)up down:(char)down
{
    return [SKTexture textureWithImageNamed:self.fileName];
}

- (UIImage *)getImage:(char)ch left:(char)left right:(char)right up:(char)up down:(char)down
{
    NSString *path = [[NSBundle mainBundle] pathForResource:self.fileName ofType:@"png"];
    
    return [UIImage imageWithContentsOfFile:path];
}

@end
