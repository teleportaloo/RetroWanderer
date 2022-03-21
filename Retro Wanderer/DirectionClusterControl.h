/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>

#import "DirectionClusterView.h"

@interface DirectionClusterControl : UIControl

@property (nonatomic, retain) DirectionClusterView *upperView;
@property (nonatomic, retain) DirectionClusterView *lowerView;

@property (nonatomic) bool left;
@property (nonatomic) bool right;

@property (nonatomic) bool topGuides;
@property (nonatomic) bool leftGuides;
@property (nonatomic) bool rightGuides;
@property (nonatomic) bool bottomGuides;

- (char)getDirectionTouchedforEvent:(UIEvent *)event;

- (void)showLowerView;

@end
