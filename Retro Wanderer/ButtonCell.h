/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>

typedef void (^ButtonCellAction)(int index);

@interface ButtonCell : UITableViewCell

@property (nonatomic) int numberOfButtons;
@property (nonatomic) NSMutableArray<UIButton *> *buttons;
@property (nonatomic) UILabel *rightLabel;
@property (nonatomic) ButtonCellAction action;
@property (nonatomic) CGFloat buttonWidth;
@property (nonatomic) CGFloat buttonHeight;
@property (nonatomic) CGFloat rowHeight;
@property (nonatomic) CGFloat buttonGap;


- (void)createButtons;
+ (CGFloat)cellHeight;


@end
