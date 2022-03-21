/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>

@interface AugmentedSegmentControl : UISegmentedControl

@property (nonatomic, retain) NSArray <NSString *> *originalTitles;
@property (nonatomic, copy) NSString *firstSegmentButton;
@property (nonatomic, copy) NSString *otherSegmentButtons;

- (void)fixColors;

@end
