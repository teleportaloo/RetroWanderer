/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "AugmentedSegmentControl.h"

@implementation AugmentedSegmentControl

/*
   // Only override drawRect: if you perform custom drawing.
   // An empty implementation adversely affects performance during animation.
   - (void)drawRect:(CGRect)rect {
    // Drawing code
   }
 */


- (void)fixColors {
    NSDictionary *normalColor = nil;
    NSDictionary *selectedColor = nil;


    if (@available(iOS 13.0, *)) {
        normalColor = @{ NSForegroundColorAttributeName: [UIColor whiteColor] };
        selectedColor = @{ NSForegroundColorAttributeName: [UIColor labelColor] };
    } else {
        normalColor = @{ NSForegroundColorAttributeName: [UIColor whiteColor] };
        selectedColor = @{ NSForegroundColorAttributeName: [UIColor whiteColor] };
    }

    [self setTitleTextAttributes:normalColor forState:UIControlStateNormal];
    [self setTitleTextAttributes:selectedColor forState:UIControlStateSelected];
}

- (void)setSelectedSegmentIndex:(NSInteger)index {
    if (self.originalTitles != nil) {
        NSInteger button = index + 1;

        if (button >= self.originalTitles.count) {
            button = 1;
        }

        [self setTitle:[NSString stringWithFormat:@"%@ %@", self.firstSegmentButton, self.originalTitles.firstObject] forSegmentAtIndex:0];

        for (NSInteger i = 1; i < self.originalTitles.count; i++) {
            if (i == button) {
                [self setTitle:[NSString stringWithFormat:@"%@ %@", self.otherSegmentButtons, self.originalTitles[i]] forSegmentAtIndex:i];
            } else {
                [self setTitle:self.originalTitles[i] forSegmentAtIndex:i];
            }
        }
    }

    [super setSelectedSegmentIndex:index];
}

@end
