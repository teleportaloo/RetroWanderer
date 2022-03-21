/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (formatting)

- (NSAttributedString *)formatAttributedStringRegularFont:(UIFont *)regularFont;
+ (NSString *)stringWithChar:(unichar)ch;

@end


@interface NSAttributedString (formatting)

+ (NSAttributedString *)string:(NSString *)string withAttributes:(NSDictionary *)attr;

@end
