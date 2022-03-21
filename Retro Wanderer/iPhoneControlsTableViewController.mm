/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "iPhoneControlsTableViewController.h"
#import "SWRevealViewController/SWRevealViewController.h"
#import "GameViewControlleriPhone.h"
#import "SettingsTableViewController.h"
#import "ScreenSelectorTable.h"
#import "NSString+formatting.h"

@interface iPhoneControlsTableViewController ()

@end

@implementation iPhoneControlsTableViewController

#define kSettings     @"Settings"
#define kHighScores   @"High Scores"
#define kAcheivements @"Achievements"
#define kScore        @"Total score:"


- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    _game = (GameViewControlleriPhone *)self.revealViewController.frontViewController;

    self.title = @"Retro Wanderer";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    self.rowsInOrder = [NSMutableArray array];


    self.titles = @{
        @"title1": @"Game Center",
        @"title2": @"Preferences"
    };

    [self.rowsInOrder addObject:kScore];

    for (NSString *cell in @[kSaveCheckpoint, kStart, kStop, kStartOver]) {
        if (_game.cellActions[cell]) {
            [self.rowsInOrder addObject:cell];
        }
    }

    if (_game.gameCenter) {
        [self.rowsInOrder addObject:@"title1"];
        [self.rowsInOrder addObject:kHighScores];
        [self.rowsInOrder addObject:kAcheivements];
    }

    [self.rowsInOrder addObject:@"title2"];
    [self.rowsInOrder addObject:kSettings];


    self.pushAction = @{
        kSettings:
        ^{
            UIViewController *settings = [[SettingsTableViewController alloc] init];

            [self.navigationController pushViewController:settings animated:YES];
        }
    };

    self.closeAction = @{
        kHighScores:
        ^{
            [self->_game actionShowHighScores];
        },
        kAcheivements:
        ^{
            [self->_game actionShowAchievements];
        }
    };

    self.processAction = @{
        kScore:
        ^{
            return [NSString stringWithFormat:@"%@ #b%ld#D", kScore, [self->_game totalScore]];
        }
    };

    self.sectionStart = [NSMutableArray array];

    if (self.titles[self.rowsInOrder.firstObject] == nil) {
        [self.sectionStart addObject:@-1];
    }

    for (int i = 0; i < self.rowsInOrder.count; i++) {
        if (self.titles[self.rowsInOrder[i]] != nil) {
            [self.sectionStart addObject:@(i)];
        }
    }

    return self.sectionStart.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section + 1 < self.sectionStart.count) {
        return self.sectionStart[section + 1].integerValue - self.sectionStart[section].integerValue - 1;
    }

    return self.rowsInOrder.count - self.sectionStart[section].integerValue - 1;
}

- (NSInteger)indexForPath:(NSIndexPath *)indexPath {
    return indexPath.row +  self.sectionStart[indexPath.section].integerValue + 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSInteger start = self.sectionStart[section].integerValue;

    if (start >= 0) {
        return self.titles[self.rowsInOrder[self.sectionStart[section].integerValue]];
    }

    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"1"];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"1"];
    }

    NSString *item = self.rowsInOrder [[self indexForPath:indexPath]];
    bool maybePush = self.pushAction[item] != nil;
    // NSString *linkImage   = self.linkImages[maybeCharacter];



    NSString *stringToFormat = item;

    ProcessAction action = self.processAction[item];

    if (action != nil) {
        stringToFormat = action();
    }

    stringToFormat = [_game cellText:stringToFormat buttonOnRight:YES];

    cell.textLabel.attributedText = [stringToFormat formatAttributedStringRegularFont:[UIFont systemFontOfSize:18]];
    cell.textLabel.numberOfLines = 0;

    if (maybePush) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    cell.textLabel.textAlignment = NSTextAlignmentLeft;

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //minimum size of your cell, it should be single line of label if you are not clear min. then return UITableViewAutomaticDimension;
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *item = self.rowsInOrder [[self indexForPath:indexPath]];
    SelectAction pushAction = self.pushAction[item];
    SelectAction closeAction = self.closeAction[item];
    ButtonAction buttonAction = _game.cellActions[item];

    if (pushAction) {
        pushAction();
    } else if (closeAction) {
        [self.revealViewController revealToggleAnimated:YES];
        closeAction();
    } else if (buttonAction) {
        [self.revealViewController revealToggleAnimated:YES];
        buttonAction();
    }
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
