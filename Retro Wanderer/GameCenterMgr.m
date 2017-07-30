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

#import "GameCenterMgr.h"
#import "AppDelegate.h"
#import "DebugLogging.h"

#define LEADERBOARD_ID @"RetroWanderer"

@interface GameCenterMgr()

@property (nonatomic, strong) UIViewController *presentationController;

@end


@implementation GameCenterMgr

#pragma mark Singelton

static GameCenterMgr *sharedManager = nil;

+ (instancetype)sharedManager {
    static GameCenterMgr *sharedManager;

    if (!sharedManager)
    {
        sharedManager = [[GameCenterMgr alloc] init];
    }
    return sharedManager;
}

+ (void)noGameCenter
{
    sharedManager = nil;
}

#pragma mark Initialization

- (id)init {
    self = [super init];
    if (self) {
        AppDelegate *del = (AppDelegate*) [[UIApplication sharedApplication] delegate];
        self.presentationController = del.window.rootViewController;
    }
    return self;
}

#pragma mark Player Authentication


- (void)authenticatePlayer:(dispatch_block_t)success{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    
    [localPlayer setAuthenticateHandler:
     ^(UIViewController *viewController, NSError *error) {
         if (viewController != nil) {
             [self.presentationController
              presentViewController:viewController
              animated:YES completion:nil];
         } else if ([GKLocalPlayer localPlayer].authenticated) {
             if (success)
             {
                 success();
             }
             
         } else
         {
             LOG_NSERROR(error);
         }
    }];
}

#pragma mark Leaderboard and Achievement handling

- (void)showLeaderboard
{
    GKGameCenterViewController *gcViewController = [[GKGameCenterViewController alloc] init];
    gcViewController.gameCenterDelegate = self;
    gcViewController.viewState = GKGameCenterViewControllerStateLeaderboards;
    gcViewController.leaderboardIdentifier = LEADERBOARD_ID;
    
    [self.presentationController presentViewController:gcViewController
                                              animated:YES completion:nil];
}

- (void)showAchievements
{
    GKGameCenterViewController *gcViewController = [[GKGameCenterViewController alloc] init];
    gcViewController.gameCenterDelegate = self;
    gcViewController.viewState = GKGameCenterViewControllerStateAchievements;
    // gcViewController.leaderboardIdentifier = LEADERBOARD_ID;
    
    [self.presentationController presentViewController:gcViewController
                                              animated:YES completion:nil];
}

- (void)reportScore:(NSInteger)score {
    GKScore *gScore = [[GKScore alloc] initWithLeaderboardIdentifier:LEADERBOARD_ID];
    gScore.value = score;
    gScore.context = 0;
    
    [GKScore reportScores:@[gScore] withCompletionHandler:^(NSError *error) {
        if (!error) {
            DEBUG_LOG(@"Score reported successfully!");
        }
        else {
            DEBUG_LOG(@"Unable to report score");
        }
    }];
}

#pragma mark GameKit Delegate Methods

- (void)gameCenterViewControllerDidFinish:
(GKGameCenterViewController *)gameCenterViewController {
    [gameCenterViewController
     dismissViewControllerAnimated:YES completion:nil];
}


- (void)reportAchievements:(NSDictionary *)achievements
{
    // First do the number of screens ones
    static NSDictionary *screenCounts = nil;
    static NSDictionary *specificScreens = nil;
    
    
    if (screenCounts == 0)
    {
        NSURL *file = [[NSBundle mainBundle]
                       URLForResource:@"ScreenCountAchievements" withExtension:@"plist"];
        
        screenCounts = [NSDictionary dictionaryWithContentsOfURL:file];
        
    }
    
    if (specificScreens == 0)
    {
        NSURL *file = [[NSBundle mainBundle]
                       URLForResource:@"ScreenNumberAchievements" withExtension:@"plist"];
        
        specificScreens = [NSDictionary dictionaryWithContentsOfURL:file];
    }
    
    NSInteger screenCount = achievements.count;
    
    NSMutableArray *gameCenterAchs = [[NSMutableArray alloc] init];
    
    [screenCounts enumerateKeysAndObjectsUsingBlock: ^void (NSString* refName, NSNumber *screens, BOOL *stop)
     {
         if (screens.integerValue <= screenCount && screens.integerValue > 0)
         {
             GKAchievement *ach = [[GKAchievement alloc] initWithIdentifier:refName];
             ach.percentComplete = (screenCount / screens.integerValue) * 100 ;
             [gameCenterAchs addObject:ach];
         }
         
     }];
    
    
    [specificScreens enumerateKeysAndObjectsUsingBlock: ^void (NSString* refName, NSNumber* screen, BOOL *stop)
     {
         if (achievements[[NSString stringWithFormat:@"%d", screen.intValue]]!=0)
         {
             GKAchievement *ach = [[GKAchievement alloc] initWithIdentifier:refName];
             ach.percentComplete = 100 ;
             [gameCenterAchs addObject:ach];
         }
     }];
    
    [GKAchievement reportAchievements:gameCenterAchs withCompletionHandler:^(NSError *error) {
        LOG_NSERROR(error);
    }];
}

@end
