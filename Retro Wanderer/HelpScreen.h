/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>

typedef void (^HelpAction)(void);

@interface HelpScreen : UITableViewController

@property (nonatomic, retain) NSArray<NSString *> *rowsInOrder;
@property (nonatomic, retain) NSDictionary<NSString *, NSString *> *textForCharacter;
@property (nonatomic, retain) NSDictionary<NSString *, NSString *> *links;
@property (nonatomic, retain) NSDictionary<NSString *, NSString *> *linkText;
@property (nonatomic, retain) NSDictionary<NSString *, NSString *> *linkImages;
@property (nonatomic, retain) NSDictionary<NSString *, NSString *> *titles;
@property (nonatomic, retain) NSMutableArray<NSNumber *> *sectionStart;
@property (nonatomic, copy) HelpAction action;
@property (nonatomic) bool iPad;
@property (nonatomic, retain) NSMutableDictionary<NSString *, NSDictionary *> *achievements;

@end
