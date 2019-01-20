//
//  AugmentedSegmentControl.h
//  Text Wanderer
//
//  Created by Andrew Wallace on 8/18/17.
//  Copyright © 2017 Teleportaloo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AugmentedSegmentControl : UISegmentedControl

@property (nonatomic, retain) NSArray <NSString *> * originalTitles;
@property (nonatomic, copy) NSString *firstSegmentButton;
@property (nonatomic, copy) NSString *otherSegmentButtons;

@end
