//
//  Screens.m
//  Retro Wanderer
//
//  Created by Andrew Wallace on 8/20/20.
//  Copyright © 2020 Teleportaloo. All rights reserved.
//

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Screens.h"

#define kNames   @"names"
#define kOrder   @"order"
#define kNewLine @"new_line"

@interface Screens () {
    int _maxScreenNum;
}

@property (nonatomic, retain) NSDictionary *screenInfo;
@property (nonatomic, retain) NSArray<NSNumber *> *ordering;

@end

@implementation Screens

+ (Screens *)sharedInstance {
    static Screens *singleton = nil;

    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        singleton = [[Screens alloc] init];
    });
    return singleton;
}

+ (NSString *)ordinalString:(NSInteger)ordinal {
    return [NSString stringWithFormat:@"%ld", (long)ordinal];
}

- (Screens *)init {
    if ((self = [super init])) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"screens" ofType:@"plist"];

        self.screenInfo = [NSDictionary dictionaryWithContentsOfFile:filePath];
        self.ordering = self.screenInfo[kOrder];

        _maxScreenNum = 0;

        for (NSNumber *ordinal in self.ordering) {
            if (ordinal.integerValue > _maxScreenNum) {
                _maxScreenNum = ordinal.intValue;
            }
        }
    }

    return self;
}

- (NSInteger)screenOrdinalCount {
    return self.ordering.count;
}

- (int)maxScreenNum {
    return _maxScreenNum;
}

- (NSInteger)screensAvailable:(NSDictionary *)acheivements {
    NSNumber *max = self.screenInfo[@"max_regular"];

    NSInteger screenCount = acheivements.count;

    if (screenCount >= max.integerValue) {
        return self.ordering.count;
    }

    return max.integerValue;
}

- (int)screenFileNumberFromOrdinal:(NSInteger)ordinal {
    if (ordinal < self.ordering.count) {
        return (int)self.ordering[ordinal].integerValue;
    }

    return 0;
}

- (NSString *)visableScreenNameFromNum:(int)num {
    NSDictionary *names = self.screenInfo[kNames];
    NSString *numStr = [Screens ordinalString:num];
    NSString *name = names[numStr];

    if (name) {
        return name;
    }

    return numStr;
}

- (NSString *)visableScreenNameFromOrdinal:(NSInteger)ordinal {
    int num = [self screenFileNumberFromOrdinal:ordinal];

    return [self visableScreenNameFromNum:num];
}

- (BOOL)startNewLineAfterOrdinal:(NSInteger)ordinal {
    NSDictionary *newLines = self.screenInfo[kNewLine];
    NSInteger screen = [self screenFileNumberFromOrdinal:ordinal];
    NSString *screenStr = [Screens ordinalString:screen];
    NSNumber *newLine = newLines[screenStr];

    if (newLine != nil) {
        return newLine.boolValue;
    }

    return NO;
}

- (NSInteger)ordinalFromNum:(int)num {
    for (int i = 0; i < self.ordering.count; i++) {
        if (self.ordering[i].integerValue == num) {
            return i;
        }
    }

    return 0;
}

- (NSArray<NSArray<NSNumber *> *> *)screens:(NSInteger)highest lineWidth:(NSInteger)lineWidth {
    NSMutableArray<NSMutableArray<NSNumber *> *> *rows = [NSMutableArray array];

    rows[0] = [NSMutableArray array];

    int x = 0;

    for (NSInteger ordinal = 0; ordinal < highest; ordinal++) {
        [rows.lastObject addObject:@(ordinal)];

        x++;

        if (x >= lineWidth || [self startNewLineAfterOrdinal:ordinal]) {
            [rows addObject:[NSMutableArray array]];
            x = 0;
        }
    }

    for (NSInteger i = 0; i < rows.count;) {
        if (rows[i].count > 0) {
            i++;
        } else {
            [rows removeObjectAtIndex:i];
        }
    }

    return rows;
}

@end
