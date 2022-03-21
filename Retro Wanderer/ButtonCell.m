/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "ButtonCell.h"

#define kButtonSide      (40)
#define kButtonGap       (10)
#define kButtonRowHeight (50)


@implementation ButtonCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.buttonWidth = kButtonSide;
        self.buttonHeight = kButtonSide;
        self.rowHeight = kButtonRowHeight;
        self.buttonGap = kButtonGap;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)createButtons {
    if (self.buttons != nil) {
        for (UIButton *button in self.buttons) {
            [button removeFromSuperview];
        }

        self.buttons = nil;
    }

    self.buttons = [NSMutableArray array];

    for (int i = 0; i < self.numberOfButtons; i++) {
        CGRect frame = CGRectMake(self.buttonGap + (self.buttonGap + self.buttonWidth) * i,  (self.rowHeight - self.buttonHeight) / 2, self.buttonWidth, self.buttonHeight);
        UIButton *button = [[UIButton alloc] initWithFrame:frame];
        button.layer.cornerRadius = 5;
        button.layer.masksToBounds = YES;
        self.buttons[i] = button;
        [button addTarget:self action:@selector(buttonTouched:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:button];
    }

    CGRect labelFrame = CGRectMake(self.buttonGap + (self.buttonGap + self.buttonWidth), (self.rowHeight - self.buttonHeight) / 2, (self.buttonWidth + self.buttonGap) * (self.numberOfButtons - 1) - self.buttonGap, self.buttonHeight);

    self.rightLabel = [[UILabel alloc] initWithFrame:labelFrame];

    [self.contentView addSubview:self.rightLabel];

    [self layoutSubviews];
}

- (void)buttonTouched:(id)sender {
    UIButton *touched = (UIButton *)sender;

    for (int i = 0; i < self.buttons.count; i++) {
        if (self.buttons[i] == touched) {
            self.action(i);
            break;
        }
    }
}

+ (CGFloat)cellHeight {
    return kButtonRowHeight;
}

@end
