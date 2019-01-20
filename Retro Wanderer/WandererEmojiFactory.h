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
#import "WandererTextureFactory.h"

@interface WandererEmojiFactory : WandererTextureFactory

@property (nonatomic, retain) NSString * emoji;
@property (nonatomic, retain) UIColor *fgColor;
@property (nonatomic, retain) UIColor *bgColor;

+ (instancetype)withEmoji:(NSString *)emoji;
+ (instancetype)withEmoji:(NSString *)emoji fg:(UIColor *)fgColor;
+ (instancetype)withEmoji:(NSString *)emoji bg:(UIColor *)bgColor;

@end
