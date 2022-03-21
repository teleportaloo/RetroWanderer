/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>

@class GameViewControlleriPhone;

#define kStart          @"▶️ Start playback"
#define kStartOver      @"↩️ #RStart over#D"
#define kSaveCheckpoint @"💾 Save checkpoint"
#define kStop           @"⏹ Stop playback"


typedef void (^SelectAction)();
typedef NSString * (^ProcessAction)();

@interface iPhoneControlsTableViewController : UITableViewController {
    GameViewControlleriPhone *_game;   // weak
}

@property (nonatomic, retain) NSMutableArray<NSString *> *rowsInOrder;
@property (nonatomic, retain) NSDictionary<NSString *, NSString *> *titles;
@property (nonatomic, retain) NSDictionary<NSString *, SelectAction> *pushAction;
@property (nonatomic, retain) NSDictionary<NSString *, SelectAction> *closeAction;
@property (nonatomic, retain) NSDictionary<NSString *, ProcessAction> *processAction;
@property (nonatomic, retain) NSMutableArray<NSNumber *> *sectionStart;


@end
