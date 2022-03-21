/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "ScreenSelectorTable.h"
#import "ButtonCell.h"
#import "GameViewController.h"
#import "SWRevealViewController/SWRevealViewController.h"
#import "Screens.h"

#define kInitialSection 0
#define kMatrixSection  1
#define kSections       2

@interface ScreenSelectorTable ()

@property (nonatomic, retain) NSArray<NSArray<NSNumber *> *> *rows;

@end

@implementation ScreenSelectorTable

#define kButtonsPerCell 5

- (void)dealloc {
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.rows = [Screens.sharedInstance screens:self.gameView.highestOrdinal lineWidth:kButtonsPerCell];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    self.title = @"Screens";

    if (self.revealViewController != nil) {
        self.gameView = (GameViewController *)self.revealViewController.frontViewController;
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
    switch (section) {
        case kInitialSection:
            return 1;

        default:
            return self.rows.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ButtonCell *cell = nil;

    UIColor *bgc = [UIColor grayColor];

    __weak typeof(self) weakSelf = self;

    switch (indexPath.section) {
        default:
        case kInitialSection: {
            static NSString *strRowId = @"next/prev";
            cell = [tableView dequeueReusableCellWithIdentifier:strRowId];

            if (cell == nil) {
                cell = [[ButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strRowId];
                cell.numberOfButtons = 2;
                cell.buttonWidth = 115;

                [cell createButtons];

                for (UIButton *button in cell.buttons) {
                    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                    button.backgroundColor = [UIColor yellowColor];
                }

                cell.backgroundColor = bgc;
            }

            if (self.gameView.showPrevScreen) {
                NSString *text = [self.gameView cellText:kPrevText buttonOnRight:NO];
                [cell.buttons[0] setTitle:text forState:UIControlStateNormal];
                cell.buttons[0].hidden = NO;
            } else {
                cell.buttons[0].hidden = YES;
            }

            if (self.gameView.showNextScreen) {
                NSString *text = [self.gameView cellText:kNextText buttonOnRight:YES];
                [cell.buttons[1] setTitle:text forState:UIControlStateNormal];
                cell.buttons[1].hidden = NO;
            } else {
                cell.buttons[1].hidden = YES;
            }

            cell.action = ^(int button)
            {
                [weakSelf.revealViewController setFrontViewPosition:FrontViewPositionLeft animated:YES];

                if (button == 0) {
                    [weakSelf.gameView changeToScreenOrdinal:weakSelf.gameView.currentScreenOrdinal - 1 review:NO];
                } else if (button == 1) {
                    [weakSelf.gameView changeToScreenOrdinal:weakSelf.gameView.currentScreenOrdinal + 1 review:NO];
                }
            };

            break;
        }

        case kMatrixSection: {
            {
                static NSString *strRowId = @"1";
                cell = [tableView dequeueReusableCellWithIdentifier:strRowId];

                if (cell == nil) {
                    cell = [[ButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strRowId];
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.backgroundColor = bgc;
                }

                NSArray<NSNumber *> *thisRow = self.rows[indexPath.row];

                cell.numberOfButtons = (int)thisRow.count;

                [cell createButtons];

                for (int i = 0; i < thisRow.count; i++) {
                    [self initButton:cell.buttons[i] screen:(int)thisRow[i].integerValue];

                    cell.buttons[i].hidden = NO;
                }

                cell.rightLabel.hidden = YES;

                cell.action = ^(int button) {
                    [weakSelf.revealViewController setFrontViewPosition:FrontViewPositionLeft animated:YES];
                    [weakSelf.gameView changeToScreenOrdinal:thisRow[button].integerValue review:NO];
                };
            }
        }
    }
    return cell;
}

- (int)initButton:(UIButton *)button screen:(int)ordinal {
    int completed = 0;


    NSString *name = [Screens.sharedInstance visableScreenNameFromOrdinal:ordinal];
    int num = [Screens.sharedInstance screenFileNumberFromOrdinal:ordinal];

    [button setTitle:name forState:UIControlStateNormal];

    NSDictionary *achievement = [self.gameView achievementForScreenNum:num];

    // button.titleLabel.font = self.screenButton.titleLabel.font;
    //[button setTitleColor:[self.screenButton titleColorForState:UIControlStateNormal]
    //             forState:UIControlStateNormal];

    button.titleLabel.font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:20];

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

    return completed;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
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
