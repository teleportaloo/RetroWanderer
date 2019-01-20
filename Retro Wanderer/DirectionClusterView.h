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

#import <UIKit/UIKit.h>


#define kMoveKeyUp          'k'
#define kMoveKeyDown        'j'
#define kMoveKeyLeft        'h'
#define kMoveKeyRight       'l'
#define kMoveKeySkip        ' '
#define kMoveQuit           'q'
#define kMoveNone           0
#define kMoveKeyStep         '.'

@interface DirectionClusterView : UIView

@property (nonatomic) char buttonTouched;
@property (nonatomic, retain) NSDictionary<NSNumber *, NSArray<NSValue *>*> * areas;
@property (nonatomic, retain) NSDictionary<NSNumber *, NSAttributedString *> * text;
@property (nonatomic, retain) NSDictionary<NSNumber *, NSValue *> * textRect;
@property (nonatomic) bool controlsNeverFade;
@property (nonatomic) bool stepMode;
@property (nonatomic) bool NoLines;

@property (nonatomic, retain) UIColor *buttonColor;


- (void)showControls;
- (void)touched:(char)direction;
- (void)fadeOut;


@end
