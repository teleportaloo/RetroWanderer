//
//  AugmentedSegmentControl.m
//  Text Wanderer
//
//  Created by Andrew Wallace on 8/18/17.
//  Copyright © 2017 Teleportaloo. All rights reserved.
//

#import "AugmentedSegmentControl.h"

@implementation AugmentedSegmentControl

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)setSelectedSegmentIndex:(NSInteger)index
{
    
    if (self.originalTitles !=nil)
    {
        NSInteger button = index+1;
        
        if (button >= self.originalTitles.count)
        {
            button = 1;
        }
        
        [self setTitle:[NSString stringWithFormat:@"%@ %@", self.firstSegmentButton, self.originalTitles.firstObject] forSegmentAtIndex:0];
        
        for (NSInteger i=1; i< self.originalTitles.count; i++)
        {
            if (i==button)
            {
                [self setTitle:[NSString stringWithFormat:@"%@ %@", self.otherSegmentButtons, self.originalTitles[i]] forSegmentAtIndex:i];
            }
            else
            {
                [self setTitle:self.originalTitles[i] forSegmentAtIndex:i];
            }
        }
    }
    
    [super setSelectedSegmentIndex:index];
}



@end
