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

#import "ScreenSelectorTable.h"
#import "ButtonCell.h"
#import "GameViewController.h"
#import "SWRevealViewController/SWRevealViewController.h"

#define kInitialSection     0
#define kMatrixSection      1
#define kSections           2

@interface ScreenSelectorTable ()

@end

@implementation ScreenSelectorTable

#define kButtonsPerCell 5
#define kFullRows (int)((60.0 + (kButtonsPerCell/2.0)) / kButtonsPerCell)

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.title = @"Screens";
    
    if (self.revealViewController != nil)
    {
        self.gameView = (GameViewController*)self.revealViewController.frontViewController;
    }
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    switch (section)
    {
        case kInitialSection:
            return 1;
        default:
            return 1 + kFullRows + (self.screen61 ? 1 : 0);
    }
    return 0;
}

- (bool)screen61
{
    return (self.gameView.highest > kMaxScreen);
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ButtonCell *cell = nil;
    
    switch (indexPath.section)
    {
        default:
        case kInitialSection:
        {
            static NSString * strRowId = @"next/prev";
            cell = [tableView dequeueReusableCellWithIdentifier:strRowId];
            
            if (cell == nil)
            {
                cell = [[ButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strRowId];
                cell.numberOfButtons = 2;
                cell.buttonWidth = 115;
                
                [cell createButtons];
                
                for (UIButton *button in cell.buttons)
                {
                    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                    button.backgroundColor = [UIColor yellowColor];
                }
            }
            
            
            
            
            
            if (self.gameView.showPrevScreen)
            {
                NSString *text = [self.gameView cellText:kPrevText buttonOnRight:NO];
                [cell.buttons[0] setTitle:text  forState:UIControlStateNormal];
                cell.buttons[0].hidden = NO;
            }
            else
            {
                cell.buttons[0].hidden = YES;
            }
            
            if (self.gameView.showNextScreen)
            {
                NSString *text = [self.gameView cellText:kNextText buttonOnRight:YES];
                [cell.buttons[1] setTitle:text forState:UIControlStateNormal];
                cell.buttons[1].hidden = NO;
            }
            else
            {
                cell.buttons[1].hidden = YES;
            }
            
            cell.action = ^(int button)
            {
                [self.revealViewController setFrontViewPosition:FrontViewPositionLeft animated:YES];
                
                if (button == 0)
                {
                    [self.gameView changeToScreen:self.gameView.currentScreen-1 review:NO];
                }
                else if (button == 1)
                {
                    [self.gameView changeToScreen:self.gameView.currentScreen+1 review:NO];
                    
                }
            };
            
            break;
        }
        case kMatrixSection:
        {
            if (indexPath.row == 0)
            {
                static NSString * strRowId = @"0";
                cell = [tableView dequeueReusableCellWithIdentifier:strRowId];
                
                if (cell == nil)
                {
                    cell = [[ButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strRowId];
                    cell.numberOfButtons = kButtonsPerCell;
                    
                    [cell createButtons];
                }
                
                [self initButton:cell.buttons[0] screen:0];
                
                
                for (int i=1; i< kButtonsPerCell; i++)
                {
                    cell.buttons[i].hidden = YES;
                }
                cell.rightLabel.text = @"percentage";
                
                int completed = 0;
                
                for (int i=0; i< kMaxScreen+1; i++)
                {
                    NSDictionary *achievement = self.gameView.achievements[[NSString stringWithFormat:@"%d", i]];
                    
                    if (achievement)
                    {
                        completed++;
                    }
                    
                }
                
                cell.rightLabel.text = [NSString stringWithFormat:@"%2.0f%% done", ((float)completed*100.0)/(kMaxScreen+1)];
                cell.rightLabel.textAlignment = NSTextAlignmentRight;
                
                cell.action = ^(int button)
                {
                    [self.revealViewController setFrontViewPosition:FrontViewPositionLeft animated:YES];
                    [self.gameView changeToScreen:0 review:NO];
                };
                
            }
            else if (indexPath.row == kFullRows+1)
            {
                static NSString * strRowId = @"61";
                cell = [tableView dequeueReusableCellWithIdentifier:strRowId];
                
                if (cell == nil)
                {
                    cell = [[ButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strRowId];
                    cell.numberOfButtons = kButtonsPerCell;
                    
                    [cell createButtons];
                    
                    [self initButton:cell.buttons[kButtonsPerCell-1] screen:61];
                    
                    for (int i=0; i< kButtonsPerCell-1; i++)
                    {
                        cell.buttons[i].hidden = YES;
                    }
                    cell.rightLabel.hidden = YES;
                    
                    cell.action = ^(int button)
                    {
                        [self.revealViewController setFrontViewPosition:FrontViewPositionLeft animated:YES];
                        [self.gameView changeToScreen:61 review:NO];
                    };
                    
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                }
            }
            else
            {
                static NSString * strRowId = @"1";
                cell = [tableView dequeueReusableCellWithIdentifier:strRowId];
                
                if (cell == nil)
                {
                    cell = [[ButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strRowId];
                    cell.numberOfButtons = kButtonsPerCell;
                    
                    [cell createButtons];
                    
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                }
                
                
                for (int i=0; i< kButtonsPerCell; i++)
                {
                    [self initButton:cell.buttons[i] screen:(int)(i + (kButtonsPerCell * (indexPath.row-1)) +1)];
                    
                    cell.buttons[i].hidden = NO;
                }
                
                cell.rightLabel.hidden = YES;
                
                cell.action = ^(int button)
                {
                    [self.revealViewController setFrontViewPosition:FrontViewPositionLeft animated:YES];
                    [self.gameView changeToScreen:(int)(button + (kButtonsPerCell * (indexPath.row-1)) +1) review:NO];
                };
            }
        }
            
    }
    return cell;
}


- (int)initButton:(UIButton *)button screen:(int)num
{
    int completed = 0;
    [button setTitle:[NSString stringWithFormat:@"%d", num] forState:UIControlStateNormal];
    
    NSDictionary *achievement = self.gameView.achievements[[NSString stringWithFormat:@"%d", num]];
    
    // button.titleLabel.font = self.screenButton.titleLabel.font;
    //[button setTitleColor:[self.screenButton titleColorForState:UIControlStateNormal]
    //             forState:UIControlStateNormal];
    
    button.titleLabel.font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:20];
    
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
    return completed;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ButtonCell.cellHeight;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
