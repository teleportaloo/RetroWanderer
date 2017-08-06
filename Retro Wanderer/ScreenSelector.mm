/***************************************************************************
 *  Copyright 2017 -   Andrew Wallace                                       *
 *                                                                          *
 *  This program is free software; you can redistribute it and/or modify    *
 *  it under the terms of the GNU General Public License as published by    *
 *  the Free Software Foundation; either version 2 of the License, or       *
 *  (at your option) any later version.                                     *
 *                                                                          *
 *  This program is distributed in the hope that it will be useful,         *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of          *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           *
 *  GNU General Public License for more details.                            *
 *                                                                          *
 *  You should have received a copy of the GNU General Public License       *
 *  along with this program; if not, write to the Free Software             *
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA               *
 *  02111-1307, USA.                                                        *
 ***************************************************************************/

#import "ScreenSelector.h"
#import "GameViewController.h"


@interface ScreenSelector ()

@end

@implementation ScreenSelector

- (void)buttonTouched:(id)button
{
    int screen = 0;
    for (UIButton *item in self.screenButtons)
    {
        if (item == button)
        {
            [self dismissViewControllerAnimated:YES completion:
             ^{
                 [self.gameView changeToScreen:screen review:NO];
             }];
            break;
        }
        screen++;
    }
}

- (int)initButton:(UIButton *)button screen:(int)num
{
    int completed = 0;
    [button setTitle:[NSString stringWithFormat:@"%d", num] forState:UIControlStateNormal];
    
    NSDictionary *achievement = self.gameView.achievements[[NSString stringWithFormat:@"%d", num]];
    
    button.titleLabel.font = self.screenButton.titleLabel.font;
    [button setTitleColor:[self.screenButton titleColorForState:UIControlStateNormal]
                            forState:UIControlStateNormal];
    
    
    
    if (self.gameView.currentScreen == num)
    {
        [button setTitleColor:[UIColor redColor]
                     forState:UIControlStateNormal];
    }
    else
    {
        [button setTitleColor:[UIColor blackColor]
                     forState:UIControlStateNormal];
    }
    
    if (achievement)
    {
        [button setBackgroundColor:[UIColor greenColor]];
        completed = 1;
    }
    else
    {
        [button setBackgroundColor:[UIColor brownColor]];
    }
    
    [button addTarget:self action:@selector(buttonTouched:) forControlEvents:UIControlEventTouchUpInside];
    return completed;
}

- (CGRect)positionButtonFromInitialFrame:(CGRect)initialFrame x:(int)x y:(int)y
{
    const CGFloat xGap = 5.0;
    const CGFloat yGap = 5.0;
    
    return CGRectMake(initialFrame.origin.x + x * (xGap+initialFrame.size.width),
                      initialFrame.origin.y + y * (yGap+initialFrame.size.height),
                      initialFrame.size.width,
                      initialFrame.size.height);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect initialFrame = self.screenButton.frame;
    
    
    self.screenButtons = [NSMutableArray array];
    [self.screenButtons addObject:self.screenButton];
    
    int screen = 0;
    int completed = 0;
    
    completed += [self initButton:self.screenButton screen:screen];
    
    UIButton *button = nil;
    
    for (int y=1; y<11; y++)
    {
        for (int x=0; x<6; x++)
        {
            button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.frame = [self positionButtonFromInitialFrame:initialFrame x:x y:y];
            screen++;
            completed+=[self initButton:button screen:screen];
            [self.screenButtons addObject:button];
            [self.view addSubview:button];
            
        }
    }
    
    if (self.gameView.highest > kMaxScreen)
    {
        button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = [self positionButtonFromInitialFrame:initialFrame x:5 y:11];
        screen++;
        completed+=[self initButton:button screen:screen];
        [self.screenButtons addObject:button];
        [self.view addSubview:button];
    }
    
    [self.percentageDone setText:[NSString stringWithFormat:@"%2.0f%% done", ((float)completed*100.0)/(kMaxScreen+1)]];
    
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
