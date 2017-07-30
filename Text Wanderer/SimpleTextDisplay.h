//
//  SimpleTextDisplay.h
//  Text Wanderer
//
//  Created by Andrew Wallace on 5/3/17.
//  Copyright © 2017 Teleportaloo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "abstracted_display_objc.h"

#define kHeight 18
#define kWidth  42

@interface SimpleTextDisplay : NSObject <AbstractedDisplay>
{
    unichar _screen[kHeight][kWidth+1];
}

@property (nonatomic, retain) UILabel* mainLabel;
@property (nonatomic, retain) UILabel* scoreLabel;
@property (nonatomic, retain) UILabel* diamondsLabel;
@property (nonatomic, retain) UILabel* maxMovesLabel;
@property (nonatomic, retain) UILabel* monsterLabel;
@property (nonatomic, retain) UILabel* nameLabel;
@property (nonatomic, retain) UILabel* screenNumberLabel;


@end
