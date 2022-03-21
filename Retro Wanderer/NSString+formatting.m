/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "NSString+formatting.h"

@implementation NSString (formatting)


+ (NSString *)stringWithChar:(unichar)ch {
    return [NSString stringWithCharacters:&ch length:1];
}

- (void)addSegmentToString:(UIFont *)font bold:(bool)boldText italic:(bool)italicText color:(UIColor *)color substring:(NSString *)substring string:(NSMutableAttributedString **)string {
    UIFont *newFont = font;

    Class fontDesc = (NSClassFromString(@"UIFontDescriptor"));

    if ((boldText || italicText) && fontDesc != nil) {
        UIFontDescriptor *fontDescriptor = font.fontDescriptor;
        // DEBUG_LOGO(fontDescriptor);
        uint32_t existingTraitsWithNewTrait = (boldText ? UIFontDescriptorTraitBold : 0) | (italicText ? UIFontDescriptorTraitItalic : 0);
        fontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:existingTraitsWithNewTrait];
        // DEBUG_LOGO(fontDescriptor);
        UIFont *updatedFont = [UIFont fontWithDescriptor:fontDescriptor size:font.pointSize];
        newFont = updatedFont;
    }

    NSDictionary *attributes = @{ NSForegroundColorAttributeName: color,
                                  NSFontAttributeName: newFont };


    NSAttributedString *segment =  [[NSAttributedString alloc] initWithString:substring attributes:attributes];

    [*string appendAttributedString: segment];
}

// Use # as escape characters
// #b - bold text on or off
// #i - italic text on or off
// #X For colors see the items just below

- (UIColor *)modeAwareTextColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor labelColor];
    }

    return [UIColor blackColor];
}

- (NSAttributedString *)formatAttributedStringRegularFont:(UIFont *)regularFont {
    NSMutableAttributedString *string = [NSMutableAttributedString alloc].init;
    NSString *substring = nil;

    static NSDictionary *colors = nil;

    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        colors = @{
            @"0": [UIColor blackColor],
            @"O": [UIColor orangeColor],
            @"G": [UIColor greenColor],
            @"A": [UIColor grayColor],
            @"R": [UIColor redColor],
            @"B": [UIColor blueColor],
            @"Y": [UIColor yellowColor],
            @"W": [UIColor whiteColor]
        };
    });

    bool boldText = NO;
    bool italicText = NO;
    unichar c;
    UIColor *currentColor = [self modeAwareTextColor];

    NSScanner *escapeScanner = [NSScanner scannerWithString:self];

    escapeScanner.charactersToBeSkipped = nil;

    while (!escapeScanner.isAtEnd) {
        [escapeScanner scanUpToString:@"#" intoString:&substring];

        // DEBUG_LOGS(substring);

        if (!escapeScanner.isAtEnd) {
            escapeScanner.scanLocation++;
        }

        if (!escapeScanner.isAtEnd) {
            c = [self characterAtIndex:escapeScanner.scanLocation];
            escapeScanner.scanLocation++;

            if (c == '#') {
                if (substring) {
                    substring = [substring stringByAppendingString:@"#"];
                } else {
                    substring = @"#";
                }
            }

            if (substring && substring.length > 0) {
                [self addSegmentToString:regularFont bold:boldText italic:italicText color:currentColor substring:substring string:&string];
                substring = nil;
            }

            if (c == 'b') {
                boldText = !boldText;
            } else if (c == 'i') {
                italicText = !italicText;
            } else if (c != '#') {
                NSString *colorKey = [NSString stringWithCharacters:&c length:1];

                UIColor *newColor = colors[colorKey];

                if (newColor != nil) {
                    currentColor = newColor;
                } else if ([colorKey isEqualToString:@"D"]) {
                    currentColor = [self modeAwareTextColor];
                }
            }
        } else {
            [self addSegmentToString:regularFont bold:boldText italic:italicText color:currentColor substring:substring string:&string];
            substring = nil;
        }
    }

    return string;
}

@end


@implementation NSAttributedString (formatting)

+ (NSAttributedString *)string:(NSString *)string withAttributes:(NSDictionary *)attr {
    return [[NSAttributedString alloc] initWithString:string attributes:attr];
}

@end
