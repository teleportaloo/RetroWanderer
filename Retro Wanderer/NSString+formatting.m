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

#import "NSString+formatting.h"

@implementation NSString (formatting)


+ (NSString*)stringWithChar:(unichar)ch
{
    return [NSString stringWithCharacters:&ch length:1];
}

- (void)addSegmentToString:(UIFont *)font bold:(bool)boldText italic:(bool)italicText color:(UIColor *)color substring:(NSString *)substring string:(NSMutableAttributedString**)string
{
    UIFont *newFont = font;
    
    Class fontDesc = (NSClassFromString(@"UIFontDescriptor"));
    
    if ((boldText || italicText) && fontDesc !=nil)
    {
        UIFontDescriptor *fontDescriptor = font.fontDescriptor;
        // DEBUG_LOGO(fontDescriptor);
        uint32_t existingTraitsWithNewTrait = (boldText ? UIFontDescriptorTraitBold : 0 ) | (italicText ? UIFontDescriptorTraitItalic : 0);
        fontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:existingTraitsWithNewTrait];
        // DEBUG_LOGO(fontDescriptor);
        UIFont *updatedFont = [UIFont fontWithDescriptor:fontDescriptor size:font.pointSize];
        newFont = updatedFont;
    }
    
    NSDictionary *attributes = @{NSForegroundColorAttributeName :color,
                                 NSFontAttributeName            :newFont};
    
    
    NSAttributedString  *segment =  [[NSAttributedString alloc] initWithString:substring attributes:attributes];
    [*string appendAttributedString:segment];
}

// Use # as escape characters
// #b - bold text on or off
// #i - italic text on or off
// #X For colors see the items just below

- (NSAttributedString*)formatAttributedStringRegularFont:(UIFont *)regularFont
{
    NSMutableAttributedString *string = [NSMutableAttributedString alloc].init;
    NSString *substring = nil;
    
    static NSDictionary *colors = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colors = @{
                   @"0" : [UIColor blackColor],
                   @"O" : [UIColor orangeColor],
                   @"G" : [UIColor greenColor],
                   @"A" : [UIColor grayColor],
                   @"R" : [UIColor redColor],
                   @"B" : [UIColor blueColor],
                   @"Y" : [UIColor yellowColor],
                   @"W" : [UIColor whiteColor] };
        
    });
    
    bool boldText   = NO;
    bool italicText = NO;
    unichar c;
    UIColor *currentColor = [UIColor blackColor];
    
    NSScanner *escapeScanner = [NSScanner scannerWithString:self];
    
    escapeScanner.charactersToBeSkipped = nil;
    
    while (!escapeScanner.isAtEnd)
    {
        [escapeScanner scanUpToString:@"#" intoString:&substring];
        
        // DEBUG_LOGS(substring);
        
        if (!escapeScanner.isAtEnd)
        {
            escapeScanner.scanLocation++;
        }
        
        if (!escapeScanner.isAtEnd)
        {
            c = [self characterAtIndex:escapeScanner.scanLocation];
            escapeScanner.scanLocation++;
            
            if (c=='#')
            {
                if (substring)
                {
                    substring = [substring stringByAppendingString:@"#"];
                }
                else
                {
                    substring = @"#";
                }
            }
            
            if (substring && substring.length > 0)
            {
                [self addSegmentToString:regularFont bold:boldText italic:italicText color:currentColor substring:substring string:&string];
                substring = nil;
            }
            
            if (c=='b')
            {
                boldText = !boldText;
            }
            else if (c=='i')
            {
                italicText = !italicText;
            }
            else if (c!='#')
            {
                NSString *colorKey = [NSString stringWithCharacters:&c length:1];
                
                UIColor *newColor = colors[colorKey];
                
                if (newColor!=nil)
                {
                    currentColor = newColor;
                }
            }
        }
        else
        {
            [self addSegmentToString:regularFont bold:boldText italic:italicText color:currentColor substring:substring string:&string];
            substring = nil;
        }
    }
    
    return string;
}


@end


@implementation NSAttributedString (formatting)

+ (NSAttributedString*)string:(NSString *)string withAttributes:(NSDictionary*)attr
{
    return [[NSAttributedString alloc] initWithString:string attributes:attr];
}



@end
