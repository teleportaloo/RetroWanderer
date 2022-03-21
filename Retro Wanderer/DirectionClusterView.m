/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "DirectionClusterView.h"
#import "NSString+formatting.h"


#define kShapeVx 4

@implementation DirectionClusterView

- (void)showControls {
    self.buttonTouched = kMoveNone;

    if (self.stepMode) {
        self.buttonTouched = kMoveKeyStep;
    }

    self.backgroundColor = self.buttonColor;
    self.alpha = 1.0;

    [self setNeedsDisplay];

    if (!self.controlsNeverFade) {
        [UIView animateWithDuration:2.0 animations:^{
                                            self.alpha = 0.0;
                                        } completion:^(BOOL finished) {
                                          }];
    }
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        CGFloat w = self.frame.size.width;
        CGFloat h = self.frame.size.height;

        CGFloat w3 = w / 3;
        CGFloat h3 = h / 3;

        CGFloat w23 = 2 * w / 3;
        CGFloat h23 = 2 * h / 3;


        CGPoint otl = CGPointMake(0,  0);
        CGPoint otr = CGPointMake(w,  0);

        CGPoint obl = CGPointMake(0,  h);
        CGPoint obr = CGPointMake(w,  h);

        CGPoint itl = CGPointMake(w3, h3);
        CGPoint itr = CGPointMake(w23, h3);

        CGPoint ibl = CGPointMake(w3,  h23);
        CGPoint ibr = CGPointMake(w23, h23);


        self.areas = @{
            @(kMoveKeyUp): @[ [NSValue valueWithCGPoint:otl],  [NSValue valueWithCGPoint:otr],
                              [NSValue valueWithCGPoint:itr],  [NSValue valueWithCGPoint:itl] ],
            @(kMoveKeyLeft): @[ [NSValue valueWithCGPoint:otl],  [NSValue valueWithCGPoint:itl],
                                [NSValue valueWithCGPoint:ibl],  [NSValue valueWithCGPoint:obl] ],
            @(kMoveKeyDown): @[ [NSValue valueWithCGPoint:obl],  [NSValue valueWithCGPoint:ibl],
                                [NSValue valueWithCGPoint:ibr],  [NSValue valueWithCGPoint:obr] ],
            @(kMoveKeyRight): @[ [NSValue valueWithCGPoint:otr],  [NSValue valueWithCGPoint:itr],
                                 [NSValue valueWithCGPoint:ibr],  [NSValue valueWithCGPoint:obr] ],
            @(kMoveKeySkip): @[ [NSValue valueWithCGPoint:itr],  [NSValue valueWithCGPoint:ibr],
                                [NSValue valueWithCGPoint:ibl],  [NSValue valueWithCGPoint:itl] ],
            @(kMoveKeyStep): @[ [NSValue valueWithCGPoint:otl],  [NSValue valueWithCGPoint:otr],
                                [NSValue valueWithCGPoint:obr],  [NSValue valueWithCGPoint:obl] ]
        };


        UIFont *font = [UIFont systemFontOfSize:40];
        UIFont *bigFont = [UIFont systemFontOfSize:100];

        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        NSDictionary *attributes = @{ NSFontAttributeName: font,    NSForegroundColorAttributeName: [UIColor darkGrayColor], NSParagraphStyleAttributeName: paragraphStyle };
        NSDictionary *attributesBig = @{ NSFontAttributeName: bigFont, NSForegroundColorAttributeName: [UIColor darkGrayColor], NSParagraphStyleAttributeName: paragraphStyle };


        self.text = @{
            @(kMoveKeyUp): [NSAttributedString string:@"↑" withAttributes:attributes],
            @(kMoveKeyLeft): [NSAttributedString string:@"←" withAttributes:attributes],
            @(kMoveKeyDown): [NSAttributedString string:@"↓" withAttributes:attributes],
            @(kMoveKeyRight): [NSAttributedString string:@"→" withAttributes:attributes],
            @(kMoveKeySkip): [NSAttributedString string:@"●" withAttributes:attributes],
            @(kMoveKeyStep): [NSAttributedString string:@"⇢" withAttributes:attributesBig]
        };

        self.textRect = @{
            @(kMoveKeyUp): [NSValue valueWithCGRect:CGRectMake(w3, 0, w3, h3)],
            @(kMoveKeyLeft): [NSValue valueWithCGRect:CGRectMake(0, h3, w3, h3)],
            @(kMoveKeyDown): [NSValue valueWithCGRect:CGRectMake(w3, h23, w3, h3)],
            @(kMoveKeyRight): [NSValue valueWithCGRect:CGRectMake(w23, h3, w3, h3)],
            @(kMoveKeySkip): [NSValue valueWithCGRect:CGRectMake(w3, h3, w3, h3)],
            @(kMoveKeyStep): [NSValue valueWithCGRect:CGRectMake(0, 0, w, h)],
        };

        self.backgroundColor = [UIColor clearColor];
        self.alpha = 0.0;
    }

    return self;
}

- (void)drawButton:(char)direction {
    CGContextRef context = UIGraphicsGetCurrentContext();

    NSArray<NSValue *> *vertices = self.areas[@(direction)];

    const CGFloat *components = CGColorGetComponents(self.buttonColor.CGColor);

    // printf("%f %f %f\n", components[0], components[1], components[2]);
    CGContextSetRGBFillColor(context, components[0], components[1], components[2], components[3]);
    CGContextSetStrokeColorWithColor(context, self.buttonColor.CGColor);

    CGContextMoveToPoint(context, vertices[0].CGPointValue.x,  vertices[0].CGPointValue.y);

    for (int i = 1; i < kShapeVx; i++) {
        CGContextAddLineToPoint(context, vertices[i].CGPointValue.x,  vertices[i].CGPointValue.y);
    }

    CGContextFillPath(context);

    [self characterInRect:self.textRect[@(direction)].CGRectValue text:self.text[@(direction)]];
}

- (void)clear {
    self.buttonTouched = kMoveNone;
}

- (void)touched:(char)direction {
    self.buttonTouched = direction;

    if (self.stepMode) {
        self.buttonTouched = kMoveKeyStep;
    }

    self.backgroundColor = [UIColor clearColor];
    self.alpha = 0.5;

    [self setNeedsDisplay];
}

- (void)characterInRect:(CGRect)rect text:(NSAttributedString *)text {
    NSStringDrawingOptions options = NSStringDrawingTruncatesLastVisibleLine |
        NSStringDrawingUsesLineFragmentOrigin;


    CGRect textRect = [text boundingRectWithSize:rect.size options:options context:nil];

    [text drawWithRect:CGRectMake(rect.origin.x + (rect.size.width - textRect.size.width) / 2,
                                  rect.origin.y + (rect.size.height - textRect.size.height) / 2,
                                  textRect.size.width,
                                  textRect.size.height)
               options:options context:nil];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGFloat w = self.frame.size.width;
    CGFloat h = self.frame.size.height;

    CGFloat w3 = w / 3;
    CGFloat h3 = h / 3;

    CGFloat w23 = 2 * w / 3;
    CGFloat h23 = 2 * h / 3;


    if (self.buttonTouched == kMoveNone) {
        if (!self.NoLines) {
            // Drawing code
            static CGFloat dash [] = { 5.0, 5.0 };

            CGContextSetStrokeColorWithColor(context, [UIColor darkGrayColor].CGColor);

            CGContextSetLineDash(context, 5.0, dash, 2);
            CGContextSetLineWidth(context, 1.0);



            CGContextMoveToPoint(context, 0,   0);
            CGContextAddLineToPoint(context, w3,  h3);
            CGContextAddLineToPoint(context, w23, h3);
            CGContextAddLineToPoint(context, w,   0);

            CGContextMoveToPoint(context, w23, h3);
            CGContextAddLineToPoint(context, w23, h23);

            CGContextMoveToPoint(context, w3, h3);
            CGContextAddLineToPoint(context, w3, h23);


            CGContextMoveToPoint(context, 0,  h);
            CGContextAddLineToPoint(context, w3, h23);
            CGContextAddLineToPoint(context, w23, h23);
            CGContextAddLineToPoint(context, w,  h);


            CGContextMoveToPoint(context, 0, 0);
            CGContextAddLineToPoint(context, 0, h);
            CGContextAddLineToPoint(context, w, h);
            CGContextAddLineToPoint(context, w, 0);
            CGContextAddLineToPoint(context, 0, 0);


            CGContextDrawPath(context, kCGPathStroke);
        }

        [self characterInRect:CGRectMake(w3, 0, w3, h3) text:self.text[@(kMoveKeyUp)]];
        [self characterInRect:CGRectMake(0, h3, w3, h3) text:self.text[@(kMoveKeyLeft)]];
        [self characterInRect:CGRectMake(w23, h3, w3, h3) text:self.text[@(kMoveKeyRight)]];
        [self characterInRect:CGRectMake(w3, h23, w3, h3) text:self.text[@(kMoveKeyDown)]];
        [self characterInRect:CGRectMake(w3, h3, w3, h3) text:self.text[@(kMoveKeySkip)]];
    } else {
        // Draw curves between the midpoints of the polygon's sides with the
        // vertex as the control point.

        [self drawButton:self.buttonTouched];
    }

#if 0

    if (self.lastTouched.x != 0.0 && self.lastTouched.y != 0.0) {
        UIColor *col = [UIColor blueColor];

        CGContextSetStrokeColorWithColor(context, col.CGColor);
        CGContextSetFillColorWithColor(context,   col.CGColor);
#define MARGIN 20

        CGContextAddEllipseInRect(context, CGRectMake(self.lastTouched.x - MARGIN, self.lastTouched.y - MARGIN, MARGIN * 2, MARGIN * 2));

        CGContextFillPath(context);
    }

#endif
}

- (void)fadeOut {
    [UIView animateWithDuration:1.0 animations:^{
                                        self.alpha = 0.0;
                                    } completion:^(BOOL finished) {
                                      }];
}

@end
