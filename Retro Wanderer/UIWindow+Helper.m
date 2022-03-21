//
//  UIWindow+Helper.m
//  Automata
//
//  Created by Andrew Wallace on 7/12/20.
//

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "UIWindow+Helper.h"

@implementation UIWindow (Helper)

- (UIViewController *)visibleViewController {
    UIViewController *rootViewController = self.rootViewController;

    return [UIWindow getVisibleViewControllerFrom:rootViewController];
}

+ (UIViewController *)getVisibleViewControllerFrom:(UIViewController *)vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [UIWindow getVisibleViewControllerFrom:[((UINavigationController *)vc) visibleViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [UIWindow getVisibleViewControllerFrom:[((UITabBarController *)vc) selectedViewController]];
    } else {
        if (vc.presentedViewController) {
            return [UIWindow getVisibleViewControllerFrom:vc.presentedViewController];
        } else {
            return vc;
        }
    }
}

+ (UIWindow *)firstKeyWindow {
#if !TARGET_OS_UIKITFORMAC
    return UIApplication.sharedApplication.keyWindow;

#else
    return [UIApplication.sharedApplication.windows filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (UIWindow *object, NSDictionary *bindings) {
                                                                                                 return object.isKeyWindow;
                                                                                             }]].firstObject;

#endif
}

@end
