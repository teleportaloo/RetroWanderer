/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "ScreenSelector.h"
#import "GameViewController.h"
#import "Screens.h"


@interface ScreenSelector ()

@end

@implementation ScreenSelector

- (void)buttonTouched:(id)button {
    int screen = 0;

    for (UIButton *item in self.screenButtons) {
        if (item == button) {
            [self dismissViewControllerAnimated:YES completion:
             ^{
                 [self.gameView changeToScreenOrdinal:screen review:NO];
             }];
            break;
        }

        screen++;
    }
}

- (int)initButton:(UIButton *)button ordinal:(int)ordinal {
    int completed = 0;
    NSString *name = [Screens.sharedInstance visableScreenNameFromOrdinal:ordinal];
    int num = [Screens.sharedInstance screenFileNumberFromOrdinal:ordinal];

    [button setTitle:name forState:UIControlStateNormal];

    NSDictionary *achievement = [self.gameView achievementForScreenNum:num];

    button.titleLabel.font = self.screenButton.titleLabel.font;
    [button setTitleColor:[self.screenButton titleColorForState:UIControlStateNormal]
                 forState:UIControlStateNormal];

    if (self.gameView.currentScreenOrdinal == ordinal) {
        [button setTitleColor:[UIColor redColor]
                     forState:UIControlStateNormal];
    } else {
        [button setTitleColor:[UIColor blackColor]
                     forState:UIControlStateNormal];
    }

    if (achievement) {
        [button setBackgroundColor:[UIColor greenColor]];
        completed = 1;
    } else {
        [button setBackgroundColor:[UIColor brownColor]];
    }

    [button addTarget:self action:@selector(buttonTouched:) forControlEvents:UIControlEventTouchUpInside];
    return completed;
}

- (CGRect)positionButtonFromInitialFrame:(CGRect)initialFrame x:(int)x y:(int)y {
    const CGFloat xGap = 5.0;
    const CGFloat yGap = 5.0;

    return CGRectMake(initialFrame.origin.x + x * (xGap + initialFrame.size.width),
                      initialFrame.origin.y + y * (yGap + initialFrame.size.height),
                      initialFrame.size.width,
                      initialFrame.size.height);
}

- (void)viewDidLoad {
    [super viewDidLoad];

    CGRect initialFrame = self.screenButton.frame;


    self.screenButtons = [NSMutableArray array];
    [self.screenButtons addObject:self.screenButton];

    self.view.backgroundColor = [UIColor grayColor];

    int screen = 0;
    int completed = 0;

    completed += [self initButton:self.screenButton ordinal:screen];

    UIButton *button = nil;

    NSArray<NSArray<NSNumber *> *> *rows = [Screens.sharedInstance screens:self.gameView.highestOrdinal lineWidth:7];

    for (int y = 1; y < rows.count; y++) {
        for (int x = 0; x < rows[y].count; x++) {
            button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.frame = [self positionButtonFromInitialFrame:initialFrame x:x y:y];
            screen++;
            button.layer.cornerRadius = 5;
            button.layer.masksToBounds = YES;
            completed += [self initButton:button ordinal:screen];
            [self.screenButtons addObject:button];
            [self.view addSubview:button];
        }
    }

    /*
       if (self.gameView.highest > kMaxScreen)
       {
        button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = [self positionButtonFromInitialFrame:initialFrame x:5 y:11];
        button.layer.cornerRadius = 5;
        button.layer.masksToBounds = YES;
        screen++;
        completed+=[self initButton:button ordinal:screen];
        [self.screenButtons addObject:button];
        [self.view addSubview:button];
       }
     */



    [self.percentageDone setText:[NSString stringWithFormat:@"%2.0f%% done", ((float)completed * 100.0) / (Screens.sharedInstance.screenOrdinalCount + 1)]];

    [self.view layoutSubviews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
   }
 */

@end
