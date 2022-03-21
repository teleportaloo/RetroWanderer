/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WandererBlockFactory.h"
#import "WandererTile.h"

@implementation WandererBlockFactory

static NSCharacterSet *blocks = nil;

- (instancetype)init {
    if ((self = [super init])) {
        static dispatch_once_t onceTokenAndKey;

        dispatch_once(&onceTokenAndKey, ^{
            blocks = [NSCharacterSet characterSetWithCharactersInString:@"|-=#"];
        });
    }

    return self;
}

+ (instancetype)withBg:(UIColor *)bgColor fg:(UIColor *)fgColor {
    WandererBlockFactory *block = [[[self class] alloc] init];

    block.bgColor = bgColor;
    block.fgColor = fgColor;

    return block;
}

+ (instancetype)withFg:(UIColor *)fgColor fileName:(NSString *)fileName; {
    WandererBlockFactory *block = [[[self class] alloc] init];

    block.fgColor = fgColor;
    block.image = [UIImage imageNamed:fileName];

    return block;
}

+ (CGMutablePathRef)newPath:(TileNeighbors)neighbors allLines:(bool)allLines {
#define kX            (0.0)
#define kY            (0.0)
#define kCornerRadius (5.0)
#define kLineWidth    (1.5)

#define kOuterLeft    (kX)
#define kOuterRight   (kX + kTileWidth)
#define kOuterTop     (kY)
#define kOuterBottom  (kY + kTileHeight)
#define kInnerLeft    (kOuterLeft   + kLineWidth)
#define kInnerRight   (kOuterRight  - kLineWidth)
#define kInnerTop     (kOuterTop    + kLineWidth)
#define kInnerBottom  (kOuterBottom - kLineWidth)

    // Rounded in block types
    // #define empty(d)        (d != ch)

    // Rounded unless any block
#define empty(d) (![blocks characterIsMember:d])

    // Squared
    // #define empty(d) NO

    // Rounded
    // #define empty(d) YES

    bool empty_left = empty(neighbors.left);
    bool empty_right = empty(neighbors.right);
    bool empty_up = empty(neighbors.up);
    bool empty_down = empty(neighbors.down);


    CGPoint topLeft = CGPointMake(empty_left ? kInnerLeft : kOuterLeft,   empty_up ? kInnerTop : kOuterTop);
    CGPoint topRight = CGPointMake(empty_right ? kInnerRight : kOuterRight,  empty_up ? kInnerTop : kOuterTop);
    CGPoint bottomRight = CGPointMake(empty_right ? kInnerRight : kOuterRight,  empty_down ? kInnerBottom : kOuterBottom);
    CGPoint bottomLeft = CGPointMake(empty_left ? kInnerLeft : kOuterLeft,   empty_down ? kInnerBottom : kOuterBottom);

    CGMutablePathRef path = CGPathCreateMutable();

#define MaybeLine(C, X, Y) if (allLines || (C)) { CGPathAddLineToPoint(path, NULL, X, Y); } else { CGPathMoveToPoint(path, NULL, X, Y); }

    // move to top left
    if (empty_left && empty_up) {
        CGPathMoveToPoint(path, NULL, topLeft.x + kCornerRadius, topLeft.y);
    } else {
        CGPathMoveToPoint(path, NULL, topLeft.x, topLeft.y);
        MaybeLine(empty_up, topLeft.x + kCornerRadius, topLeft.y);
    }

    // add top line
    MaybeLine(empty_up, topRight.x - kCornerRadius, topRight.y);

    if (empty_right && empty_up) {
        // add top right curve
        CGPathAddQuadCurveToPoint(path, NULL, topRight.x, topRight.y, topRight.x, topRight.y + kCornerRadius);
    } else {
        MaybeLine(empty_up,    topRight.x, topRight.y);
        MaybeLine(empty_right, topRight.x, topRight.y + kCornerRadius);
    }

    // add right line
    MaybeLine(empty_right, bottomRight.x, bottomRight.y - kCornerRadius);

    if (empty_right && empty_down) {
        // add bottom right curve
        CGPathAddQuadCurveToPoint(path, NULL, bottomRight.x, bottomRight.y, bottomRight.x - kCornerRadius, bottomRight.y);
    } else {
        MaybeLine(empty_right, bottomRight.x, bottomRight.y);
        MaybeLine(empty_down, bottomRight.x - kCornerRadius, bottomRight.y);
    }

    // add bottom line
    MaybeLine(empty_down, bottomLeft.x + kCornerRadius, bottomLeft.y);

    if (empty_down && empty_left) {
        // add bottom left curve
        CGPathAddQuadCurveToPoint(path, NULL, bottomLeft.x, bottomLeft.y, bottomLeft.x, bottomLeft.y - kCornerRadius);
    } else {
        MaybeLine(empty_down, bottomLeft.x, bottomLeft.y);
        MaybeLine(empty_left, bottomLeft.x, bottomLeft.y - kCornerRadius);
    }

    // add left line
    MaybeLine(empty_left, topLeft.x, topLeft.y + kCornerRadius);

    if (empty_left && empty_up) {
        // add top left curve
        CGPathAddQuadCurveToPoint(path, NULL, topLeft.x, topLeft.y, topLeft.x + kCornerRadius, topLeft.y);
    } else {
        MaybeLine(empty_left, topLeft.x, topLeft.y);
        MaybeLine(empty_up,   topLeft.x + kCornerRadius, topLeft.y);
    }

    return path;
}

void patternCallback(void *info, CGContextRef context) {
    UIImage *image = (__bridge UIImage *)info;
    CGImageRef imageRef = [image CGImage];

    CGContextDrawImage(context, kTileRect, imageRef);
}

+ (void)patternMake:(CGRect)rect context:(CGContextRef)context image:(UIImage *)image {
    static const CGPatternCallbacks callbacks = { 0, &patternCallback, NULL };

    CGColorSpaceRef patternSpace = CGColorSpaceCreatePattern(NULL);

    CGContextSetFillColorSpace(context, patternSpace);
    CGColorSpaceRelease(patternSpace);
    CGSize patternSize = kTileRect.size;
    CGPatternRef pattern = CGPatternCreate((__bridge void *_Nullable)(image), kTileRect, CGAffineTransformIdentity, patternSize.width, patternSize.height, kCGPatternTilingConstantSpacing, true, &callbacks);
    CGFloat alpha = 1;

    CGContextSetFillPattern(context, pattern, &alpha);
    CGPatternRelease(pattern);
}

+ (UIImage *)roundedBlock:(UIColor *)bg neighbors:(TileNeighbors)neighbors fg:(UIColor *)fg image:(UIImage *)image {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(kTileWidth, kTileHeight), NO, 0);



    CGContextRef context = UIGraphicsGetCurrentContext();

    if (bg != nil) {
        CGContextBeginPath(context);

        CGMutablePathRef path = [WandererBlockFactory newPath:neighbors allLines:YES];

        CGContextAddPath(context, path);
        CGContextSetFillColorWithColor(context, bg.CGColor);
        CGContextSetLineWidth(context, kLineWidth);
        CGContextClosePath(context);
        CGContextDrawPath(context, kCGPathFill);
        CGPathRelease(path);
    }

    if (image != nil) {
        CGContextBeginPath(context);

        CGMutablePathRef path = [WandererBlockFactory newPath:neighbors allLines:YES];

        CGContextAddPath(context, path);

        [WandererBlockFactory patternMake:kTileRect context:context image:image];

        CGContextSetLineWidth(context, kLineWidth);
        CGContextClosePath(context);
        CGContextDrawPath(context, kCGPathFill);
        CGPathRelease(path);
    }

    if (fg != nil) {
        CGContextBeginPath(context);

        CGMutablePathRef path = [WandererBlockFactory newPath:neighbors allLines:NO];

        CGContextAddPath(context, path);
        CGContextSetLineWidth(context, kLineWidth);
        CGContextSetLineJoin(context, kCGLineJoinMiter);
        CGContextSetLineCap(context, kCGLineCapButt);
        CGContextSetBlendMode(context, kCGBlendModeNormal);
        CGContextSetInterpolationQuality(context, kCGInterpolationNone);
        [fg setStroke];
        CGContextDrawPath(context, kCGPathStroke);
        CGPathRelease(path);
    }

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return newImage;
}

- (UIImage *)getImage:(TileNeighbors)neighbors {
    return [WandererBlockFactory roundedBlock:self.bgColor neighbors:(TileNeighbors)neighbors fg:self.fgColor image:self.image];
}

#define kLeftMask  0x1000
#define kRightMask 0x2000
#define kUpMask    0x4000
#define kDownMask  0x8000


- (NSNumber *)key:(TileNeighbors)neighbors {
    bool empty_left = empty(neighbors.left);
    bool empty_right = empty(neighbors.right);
    bool empty_up = empty(neighbors.up);
    bool empty_down = empty(neighbors.down);

    long key = neighbors.tile;

    if (!empty_left) {
        key |= kLeftMask;
    }

    if (!empty_right) {
        key |= kRightMask;
    }

    if (!empty_up) {
        key |= kUpMask;
    }

    if (!empty_down) {
        key |= kDownMask;
    }

    return @(key);
}

@end
