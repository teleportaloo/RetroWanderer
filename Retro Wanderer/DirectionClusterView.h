/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>


#define kMoveKeyUp    'k'
#define kMoveKeyDown  'j'
#define kMoveKeyLeft  'h'
#define kMoveKeyRight 'l'
#define kMoveKeySkip  ' '
#define kMoveQuit     'q'
#define kMoveNone     0
#define kMoveKeyStep  '.'

@interface DirectionClusterView : UIView

@property (nonatomic) char buttonTouched;
@property (nonatomic, retain) NSDictionary<NSNumber *, NSArray<NSValue *> *> *areas;
@property (nonatomic, retain) NSDictionary<NSNumber *, NSAttributedString *> *text;
@property (nonatomic, retain) NSDictionary<NSNumber *, NSValue *> *textRect;
@property (nonatomic) bool controlsNeverFade;
@property (nonatomic) bool stepMode;
@property (nonatomic) bool NoLines;

@property (nonatomic) CGPoint lastTouched;

@property (nonatomic, retain) UIColor *buttonColor;


- (void)showControls;
- (void)touched:(char)direction;
- (void)fadeOut;


@end
