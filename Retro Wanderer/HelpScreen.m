/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "HelpScreen.h"
#import "WandererTile.h"
#import <Social/Social.h>
#import "SWRevealViewController/SWRevealViewController.h"
#import "NSString+formatting.h"
#import "GameCenterMgr.h"
#import "Screens.h"

@interface HelpScreen ()

@end

@implementation HelpScreen

- (void)openURL:(NSString *)link {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link] options:@{} completionHandler:^(BOOL success) {
                                                                                          if (success) {
                                                                                          NSIndexPath *ip = self.tableView.indexPathForSelectedRow;

                                                                                          if (ip != nil) {
                                                                                          [self.tableView deselectRowAtIndexPath:ip animated:YES];
                                                                                          }
                                                                                          }
                                                                                      }];
}

- (void)facebook {
    static NSString *fbid = @"fb://profile/176036722924346";
    static NSString *fbpath = @"https://m.facebook.com/RetroWanderer";

    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:fbid]]) {
        [self openURL:fbid];
    } else {
        [self openURL:fbpath];
    }
}

- (void)log {
    NSMutableString *csv = [NSMutableString stringWithString:@"Screen, Date, Time, Score\n"];
    NSMutableArray<NSString *> *screenNums = [NSMutableArray array];

    for (int ordinal = 0; ordinal < Screens.sharedInstance.screenOrdinalCount; ordinal++) {
        screenNums[ordinal] = [NSString stringWithFormat:@"%d", (int)[Screens.sharedInstance screenFileNumberFromOrdinal:ordinal]];
    }

    [screenNums sortUsingComparator:^NSComparisonResult (NSString *obj1, NSString *obj2) {
                    NSDictionary *a1 = self.achievements[obj1];
                    NSDictionary *a2 = self.achievements[obj2];

                    if (a1 == nil && a2 == nil) {
                    return obj1.intValue - obj2.intValue;
                    }

                    if (a1 == nil) {
                    return -1;
                    }

                    if (a2 == nil) {
                    return 1;
                    }

                    return [(NSDate *)a1[kAchievementDate] timeIntervalSinceDate:(NSDate *)a2[kAchievementDate]];
                }];

    for (int screen = 0; screen < Screens.sharedInstance.screenOrdinalCount; screen++) {
        NSDictionary *achievement = self.achievements[screenNums[screen]];

        if (achievement) {
            NSNumber *score = achievement[kAchievementScore];
            NSDate *date = achievement[kAchievementDate];

            [NSDateFormatter defaultFormatterBehavior];

            [csv appendFormat:@"%@,%@,%d\n",
             [Screens.sharedInstance visableScreenNameFromNum:screenNums[screen].intValue],
             [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle],
             score.intValue];
        }
    }

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths.firstObject;
    NSString *fullPathName = [documentsDirectory stringByAppendingPathComponent:@"Retro Wanderer.csv"];

    if ([csv writeToFile:fullPathName atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
        NSArray *activities = @[[NSURL fileURLWithPath:fullPathName]];

        UIActivityViewController *activityViewControntroller = [[UIActivityViewController alloc] initWithActivityItems:activities applicationActivities:nil];
        activityViewControntroller.excludedActivityTypes = @[];

        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            activityViewControntroller.popoverPresentationController.sourceView = self.view.superview;
            activityViewControntroller.popoverPresentationController.sourceRect = self.view.superview.frame;
        }

        UIViewController *presenter = self.presentingViewController;

        if (self.presentingViewController) {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                                                                                 [presenter presentViewController:activityViewControntroller animated:YES completion:^{
                                                                                 }];
                                                                             }];
        } else {
            [self presentViewController:activityViewControntroller animated:YES completion:^{
                                                                                }];
        }
    }

    NSLog(@"%@", csv);
}

- (void)tweet {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Twitter"
                                                                   message:@"@RetroWanderer"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIViewController *presenter = self.presentingViewController;

    void (^ openURL)(NSString *url) = nil;

    if (presenter == nil) {
        presenter = self;

        openURL = ^(NSString *url) {
            [self openURL:url];
        };
    } else {
        openURL = ^(NSString *url) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil];
        };
    }

    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]]) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Show in Twitter app" style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    NSString *twitter = @"twitter://user?screen_name=RetroWanderer";
                                                    openURL(twitter);
                                                }]];
    } else {
        NSString *twitterWeb = @"https://mobile.twitter.com/@RetroWanderer";

        [alert addAction:[UIAlertAction actionWithTitle:@"Show Twitter on the web" style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    openURL(twitterWeb);
                                                }]];
    }

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                            handler:nil]];

    if (self.presentingViewController) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                                                                             [presenter presentViewController:alert animated:YES completion:nil];
                                                                         }];
    } else {
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-string-concatenation"

    self.sectionStart = [NSMutableArray array];

    self.rowsInOrder = @[@"title0",
                         @"Retro Wanderer is an old puzzle platform game similar to Boulderdash, Repton, XOR and others. Each of the 60 screens is a separate puzzle, nothing is random.",
                         @"title1",
                         @"@", @"*", @"X",
                         @"#", @"C", @":", @"T", @"=", @"|", @"O", @"<", @">", @"+", @"S", @"!", @"/", @"\\", @"M", @"^",
                         @"Touch 💾#B#bSave checkpoint#b#D to save where you are, then ▶️#B#bStart playback#b#D to play it back again. Each screen is saved separately.",
                         @"The game will remember the moves for each screen you finish.",
                         self.iPad ? @"Use a game controller! Buttons and dialog options are mapped to buttons on the controller too. To use an external keyboard, hold ⌘ to see the keys."
                                   : @"Use a game controller! Buttons and dialog options are mapped to buttons on the controller too.",
                         @"title3",
                         @"link4",
                         @"#iiOS port by #BAndrew Wallace#B#i",
                         @"title2",
                         @"link2",
                         @"link3",
                         @"link0",
                         @"log"
    ];
#pragma clang diagnostic pop

    self.textForCharacter = @{ @"*": @"You must collect all this treasure...",
                               @"X": @"...only then can you go home.",
                               @"@":  self.iPad ? @"This is you, swipe to move, or use the control pad. Touch the middle to stay put. Controls will appear briefly at the start. Optimized for an MFi game controller or keyboard."
                                                : @"This is you, touch the gameboard to move as there are left and right control pads that will appear when you touch them. Controls will appear briefly at the start. Optimized for an MFi game controller. ",
                               @"#": @"Solid rock.",
                               @"=": @"More rock.",
                               @"|": @"Even more rock.",
                               @"C": @"Time capsule (#G5 points#D, #B+250#D extra moves).",
                               @":": @"Passable earth (#G1 point#D).",
                               @"T": @"Teleport (#G50 points#D for using it).",
                               @"O": @"Boulder (falls down, other boulders and arrows fall off of it). You can push them left or right.",
                               @"<": @"Arrow - runs #Rleft#D. You can push them up or down...",
                               @">": @"Arrow - runs #Rright#D. You can push them up or down too.",
                               @"+": @"Cage - holds baby monster and changes into diamonds.",
                               @"S": @"Baby monster (kills you)\nWhen a baby monster hits a cage it is captured and you get #G50 points#D. The cage also becomes a diamond.",
                               @"!": @"#R#bInstant#b annihilation#D.",
                               @"/": @"Slopes (boulders, balloons and arrows will slide off).",
                               @"\\": @"Slopes (boulders, balloons and arrows  will slide off).",
                               @"M": @"#b#RMonster#D#b (eats you up whole. Yum Yum Yum...) (#G100 points#D - kill with a boulder or arrow).",
                               @"^": @"Balloon - rises, and is popped by arrows. It does #i#bnot#b#i kill you." };

    self.links = @{ @"link0": @"https://github.com/teleportaloo/RetroWanderer",
                    @"link2": @"@tweet",
                    @"link3": @"@facebook",
                    @"link4": @"https://github.com/teleportaloo/RetroWanderer/blob/github1.0/README.markdown",
                    @"log": @"@log" };

    self.linkText = @{ @"link0": [NSString stringWithFormat:@"Version %@ source code & credits", [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"]],
                       @"link2": @"Twitter",
                       @"link3": @"Facebook",
                       @"link4": @"Original by #BSteven Shipway#D, screens developed by many others",
                       @"log": @"Share acheivements" };

    self.linkImages = @{
        @"link2": @"Twitter.png",
        @"link3": @"Facebook.png",
        @"link0": @"github.png"
    };


    self.titles = @{
        @"title0": @"#iRetro#i #bW A N D E R E R#b",
        @"title1": @"How to play",
        @"title2": @"Links",
        @"title3": @"#bCredits#b"
    };

    for (int i = 0; i < self.rowsInOrder.count; i++) {
        if (self.titles[self.rowsInOrder[i]] != nil) {
            [self.sectionStart addObject:@(i)];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"1"];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"1"];
    }

    NSString *maybeCharacter = self.rowsInOrder [[self indexForPath:indexPath]];
    NSString *textForCharacter = self.textForCharacter[maybeCharacter];
    NSString *maybeLink = self.links[maybeCharacter];
    NSString *linkText = self.linkText[maybeCharacter];
    NSString *linkImage = self.linkImages[maybeCharacter];

    NSString *stringToFormat = maybeCharacter;

    if (textForCharacter) {
        stringToFormat = textForCharacter;
    } else if (linkText) {
        stringToFormat = linkText;
    }

    cell.textLabel.attributedText = [stringToFormat formatAttributedStringRegularFont:[UIFont systemFontOfSize:18]];
    cell.textLabel.numberOfLines = 0;

    if (textForCharacter) {
        WandererTile *tile = [WandererTile initTileFromCh:[maybeCharacter characterAtIndex:0]];
        cell.imageView.image = tile.image;

        if (WandererTile.style == kStyleRetro) {
            cell.imageView.backgroundColor = [UIColor blackColor];
        } else {
            cell.imageView.backgroundColor = nil;
        }
    } else {
        cell.imageView.image = nil;
    }

    if (maybeLink) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    cell.textLabel.textAlignment = NSTextAlignmentLeft;

    if (linkImage) {
        NSString *path = [[NSBundle mainBundle] pathForResource:linkImage ofType:nil];

        cell.imageView.image = [UIImage imageWithContentsOfFile:path];
        cell.imageView.backgroundColor = nil;
    }

    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
    /* Create custom view to display section header... */
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, tableView.frame.size.width, 18)];

    [label setFont:[UIFont systemFontOfSize:18]];

    /* Section header is in 0th index... */

    label.attributedText = [self.titles[self.rowsInOrder[self.sectionStart[section].integerValue]] formatAttributedStringRegularFont:[UIFont systemFontOfSize:18]];
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    [view addSubview:label];
    [view setBackgroundColor:[UIColor grayColor]]; //your background color...
    return view;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.titles[self.rowsInOrder[self.sectionStart[section].integerValue]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *maybeCharacter = self.rowsInOrder [[self indexForPath:indexPath]];
    NSString *maybeLink = self.links[maybeCharacter];

    if ([maybeLink characterAtIndex:0] == '@') {
        NSString *selector = [maybeLink substringFromIndex:1];

        SEL action = NSSelectorFromString(selector);

        if ([self respondsToSelector:action]) {
            IMP imp = [self methodForSelector:action];
            void (*func)(id, SEL) = (void (*)(id, SEL))imp;
            func(self, action);
        }
    } else if (maybeLink != nil) {
        [self openURL:maybeLink];
    }

    if (self.action) {
        self.action();
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //minimum size of your cell, it should be single line of label if you are not clear min. then return UITableViewAutomaticDimension;
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
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
