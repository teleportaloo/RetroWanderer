/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "DirectionClusterView.h"
#import "DirectionClusterControl.h"

@implementation DirectionClusterControl

- (void)initializeFrame:(CGRect)frame {
    self.upperView = [[DirectionClusterView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    self.upperView.userInteractionEnabled = NO;
    self.upperView.buttonColor = [UIColor orangeColor];
    [self addSubview:self.upperView];
    [self layoutSubviews];
    self.backgroundColor = [UIColor clearColor];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initializeFrame:frame];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initializeFrame:self.frame];
    }

    return self;
}

- (void)showLowerView {
    if (self.lowerView != nil) {
        [self.lowerView removeFromSuperview];
    }

    self.lowerView = [[DirectionClusterView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    self.lowerView.userInteractionEnabled = NO;
    self.lowerView.buttonColor = [UIColor orangeColor];
    self.lowerView.controlsNeverFade = YES;
    [self.lowerView showControls];

    self.upperView.buttonColor = [UIColor blueColor];

    [self insertSubview:self.lowerView belowSubview:self.upperView];
    [self layoutSubviews];
}

- (char)getDirectionTouchedforEvent:(UIEvent *)event {
    UITouch *touch = [[event touchesForView:self] anyObject];
    CGPoint location = [touch locationInView:self];
    // NSLog(@"Location in button: %f, %f", location.x, location.y);

    // Divide into 3 quadrants.  5 are easy
    CGPoint relativePoint = location;

    relativePoint.x /= self.frame.size.width;
    relativePoint.y /= self.frame.size.height;

    char move = kMoveKeySkip;

    // Origin is bottom left

    const CGFloat GAME_LEFT = (1.0 / 3.0);
    const CGFloat GAME_RIGHT = (2.0 / 3.0);
    const CGFloat GAME_UP = (1.0 / 3.0);
    const CGFloat GAME_DOWN = (2.0 / 3.0);

    if (self.lowerView) {
        self.lowerView.lastTouched = location;
        [self.lowerView setNeedsDisplay];
    }

    if (self.upperView.stepMode) {
        return kMoveKeyStep;
    }

    if (relativePoint.x <= GAME_LEFT) {
        if (relativePoint.y <= GAME_UP) {
            if (relativePoint.x < relativePoint.y) {
                move = kMoveKeyLeft;
            } else {
                move = kMoveKeyUp;
            }
        } else if (relativePoint.y >= GAME_DOWN) {
            if ((GAME_LEFT - relativePoint.x) < (relativePoint.y - GAME_DOWN)) {
                move = kMoveKeyDown;
            } else {
                move = kMoveKeyLeft;
            }
        } else {
            move = kMoveKeyLeft;
        }
    } else if (relativePoint.x >= GAME_RIGHT) {
        if (relativePoint.y <= GAME_UP) {
            if ((GAME_LEFT - (relativePoint.x - GAME_RIGHT)) < relativePoint.y) {
                move = kMoveKeyRight;
            } else {
                move = kMoveKeyUp;
            }
        } else if (relativePoint.y >= GAME_DOWN) {
            if (relativePoint.x < relativePoint.y) {
                move = kMoveKeyDown;
            } else {
                move = kMoveKeyRight;
            }
        } else {
            move = kMoveKeyRight;
        }
    } else {
        if (relativePoint.y <= GAME_UP) {
            move = kMoveKeyUp;
        } else if (relativePoint.y >= GAME_DOWN) {
            move = kMoveKeyDown;
        } else {
            move = kMoveKeySkip;
        }
    }

    return move;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();

    UIColor *stroke = [UIColor blueColor];

    CGContextSetStrokeColorWithColor(context, stroke.CGColor);

    CGFloat w = self.frame.size.width;
    CGFloat h = self.frame.size.height;

    CGFloat w3 = w / 3;
    CGFloat h3 = h / 3;

    CGFloat w23 = 2 * w / 3;
    CGFloat h23 = 2 * h / 3;

    const CGFloat r = 5;

    const CGFloat lineh = h / 18;
    const CGFloat linew = w / 21;

    const CGFloat inseth = lineh / 2;
    const CGFloat insetw = linew / 2;


    // Guides
    UIColor *blobCol = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.25];

    CGContextSetStrokeColorWithColor(context, blobCol.CGColor);
    CGContextSetFillColorWithColor(context,   blobCol.CGColor);

#define BlobRect(X, Y) CGRectMake((X)-r, (Y)-r, r * 2, r * 2)

    if (self.right) {
        CGContextAddEllipseInRect(context, BlobRect(0, inseth));
        CGContextAddEllipseInRect(context, BlobRect(0, h - inseth));
    }

    if (self.left) {
        CGContextAddEllipseInRect(context, BlobRect(w, inseth));
        CGContextAddEllipseInRect(context, BlobRect(w, h - inseth));
    }

    CGContextFillPath(context);

    blobCol = [UIColor colorWithRed:0 green:0 blue:1.0 alpha:0.25];

    CGContextSetStrokeColorWithColor(context, blobCol.CGColor);
    CGContextSetFillColorWithColor(context,   blobCol.CGColor);

    if (self.topGuides) {
        CGContextAddEllipseInRect(context, BlobRect(w3, inseth));
        CGContextAddEllipseInRect(context, BlobRect(w23, inseth));
    }

    if (self.bottomGuides) {
        CGContextAddEllipseInRect(context, BlobRect(w3,  h - inseth));
        CGContextAddEllipseInRect(context, BlobRect(w23, h - inseth));
    }

    if (self.leftGuides) {
        CGContextAddEllipseInRect(context, BlobRect(insetw,  h3));
        CGContextAddEllipseInRect(context, BlobRect(insetw,  h23));
    }

    if (self.rightGuides) {
        CGContextAddEllipseInRect(context, BlobRect(w - insetw,  h3));
        CGContextAddEllipseInRect(context, BlobRect(w - insetw,  h23));
    }

    CGContextFillPath(context);
}

@end
