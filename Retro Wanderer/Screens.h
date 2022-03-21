//
//  Screens.h
//  Retro Wanderer
//
//  Created by Andrew Wallace on 8/20/20.
//  Copyright © 2020 Teleportaloo. All rights reserved.
//

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Screens : NSObject

+ (Screens *)sharedInstance;

- (NSInteger)screensAvailable:(NSDictionary *)acheivements;
- (NSInteger)screenOrdinalCount;
- (int)maxScreenNum;
- (int)screenFileNumberFromOrdinal:(NSInteger)ordinal;
- (NSString *)visableScreenNameFromOrdinal:(NSInteger)ordinal;
- (NSString *)visableScreenNameFromNum:(int)num;
- (BOOL)startNewLineAfterOrdinal:(NSInteger)ordinal;
- (NSInteger)ordinalFromNum:(int)num;
- (NSArray<NSArray<NSNumber *> *> *)screens:(NSInteger)highest lineWidth:(NSInteger)lineWidth;


@end

NS_ASSUME_NONNULL_END
