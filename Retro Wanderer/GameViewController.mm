/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "GameViewController.h"
#import "GameScene.h"
#import <AudioToolbox/AudioToolbox.h>
#import "ScreenSelector.h"
#import "GameCenterMgr.h"
#import "HelpScreen.h"
#import "DebugLogging.h"
#import "SettingsTableViewController.h"
#import "AugmentedSegmentControl.h"
#import "DirectionClusterControl.h"
#import "NSString+formatting.h"
#import "Screens.h"

#define kCurrentLevel            @"current_level"
//#define kAnimationDuration  @"animation_duration"
#define kAnimationDurationV      (0.05)
//#define kRapidFireDuration  @"rapid_fire_duration"
#define kRapidFireDurationV      (0.1)

#define kDonateProductIdentifier @"org.teleportaloo.RetroWanderer.donation1a"
#define kDonated                 @"donated"

#define kGameCenter              @"game_center"
#define kSounds                  @"sounds"
#define kStartPlaybackSpeed      @"start_playback_speed"
#define kStyle                   @"style"
#define kLeftHanded              @"left_handed"
#define kNextScreenAfterPlayback @"next_screen_after_playback"
#define kShowHelp                @"show_help"
#define kAchievements            @"achievements2.plist"
#define kMoves                   @"moves"
#define kDate                    @"date"


#define kSavedMoves              @"moves%d.plist"
#define kSavedMovesKeys          @"keys"


#define kSegStep                 0
#define kSegSlowMo               1
#define kSegSlow                 2
#define kSegFast                 3
@implementation GameViewController

@dynamic currentScreenOrdinal;
@synthesize gameCenter = _gameCenter;

- (int)screenNum {
    return [Screens.sharedInstance screenFileNumberFromOrdinal:_ordinal];
}

- (void)initScreen {
    int maxmoves = 0;

    _unsavedMoves = NO;
    [self actionButtonUp];

    if (_ordinal > self.highestOrdinal) {
        _ordinal = self.highestOrdinal;
    }

    NSString *screenPath = [[NSBundle mainBundle] pathForResource:@"screen" ofType:@"1"];

    NSString *partialScreenPath = [screenPath substringToIndex:screenPath.length - 1];

    self.buttonActionMap = [NSMutableDictionary dictionary];
    self.cellTextButton = [NSMutableDictionary dictionary];

    _screen_score = 0;

    if (rscreen(self.screenNum, &maxmoves, [partialScreenPath cStringUsingEncoding:NSUTF8StringEncoding])) {
        _game.howdead = (char *)"a non-existant screen";
    } else {
        int num = self.screenNum;
        initscreen(&num, &_screen_score, &_bell, maxmoves, (char *)"kjhl", (game *)&_game);

        self.keyStrokes = [NSMutableString string];
        self.savedKeyStrokes = [self getSavedMoves:num];
        self.playbackPosition = 0;
        [self updateButtons];
        [self.display flashingPlayer];
        self.display.normalFlashing = YES;
    }
}

- (long)calculateTotalScore {
    __block long total = 0;

    [self.achievements enumerateKeysAndObjectsUsingBlock: ^void (NSString *key, NSDictionary *achievement, BOOL *stop)
                           {
                               NSNumber *score = achievement[kAchievementScore];

                               if (score != nil) {
                                   total += score.longValue;
                               }
                           }];

    return total;
}

- (void)saveLevel {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
    [[NSUserDefaults standardUserDefaults] setObject:@(self.screenNum) forKey:kCurrentLevel];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self getSettings:NO];
}

- (void)setButtonForController:(UIButton *)button title:(NSString *)title buttonName:(NSString *)buttonName keyName:(NSString *)keyName buttonOnRight:(bool)buttonOnRight space:(NSString *)space {
    [self setButtonForController:button title:title buttonName:buttonName keyName:(NSString *)keyName buttonOnRight:buttonOnRight controllerFont:nil regularFont:nil space:space];
}

- (NSString *)cellText:(NSString *)text buttonOnRight:(bool)right {
    NSString *button = self.cellTextButton[text];

    if (!button) {
        return text;
    } else if (!right) {
        return [NSString stringWithFormat:@"%@ %@", button, text];
    }

    return [NSString stringWithFormat:@"%@ %@", text, button];
}

- (void)setButtonForCell:(NSString *)cellText buttonName:(NSString *)buttonName action:(ButtonAction)action {
    if (self.controller) {
        self.cellTextButton[cellText] = buttonName;
        self.buttonActionMap[buttonName] = action;
    } else {
        self.cellTextButton[cellText] = nil;
        self.buttonActionMap[buttonName] = nil;
    }
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures {
    return UIRectEdgeAll;
}

- (void)setButtonForController:(UIButton *)button title:(NSString *)title buttonName:(NSString *)buttonName keyName:(NSString *)keyName buttonOnRight:(bool)buttonOnRight controllerFont:(UIFont *)controllerFont regularFont:(UIFont *)regularFont space:(NSString *)space {
    __weak typeof(self) weakSelf = self;

    self.buttonActionMap[keyName] = ^{
        if (!button.hidden && button.enabled) {
            NSArray<NSString *> *actions = [button actionsForTarget:weakSelf forControlEvent:UIControlEventTouchUpInside];

            if (actions != nil && actions.count > 0) {
                SEL sel = NSSelectorFromString(actions.firstObject);
                IMP imp = [weakSelf methodForSelector:sel];
                void (*func)(id, SEL, id) = (void (*)(id, SEL, id))imp;
                func(weakSelf, sel, button);
            }
        }
    };

    if (space == nil) {
        space = @"";
    }

    if (self.controller) {
        [button setTitle:buttonOnRight ? [NSString stringWithFormat:@"%@%@ %@%@", space, title, buttonName, space] : [NSString stringWithFormat:@"%@%@ %@%@", space, buttonName, title, space] forState:UIControlStateNormal];

        if (controllerFont) {
            button.titleLabel.font = controllerFont;
        }

        button.titleLabel.adjustsFontSizeToFitWidth = YES;

        self.buttonActionMap[buttonName] = self.buttonActionMap[keyName];
    } else {
        [button setTitle:[NSString stringWithFormat:@"%@%@%@", space, title, space] forState:UIControlStateNormal];
        self.buttonActionMap[buttonName] = nil;

        if (regularFont) {
            button.titleLabel.font = regularFont;
        }

        button.titleLabel.adjustsFontSizeToFitWidth = NO;
    }
}

- (void)setButtonsForSeg:(AugmentedSegmentControl *)control titles:(NSArray<NSString *> *)titles firstButton:(NSString *)first restButton:(NSString *)rest restKey:(NSString *)key {
    __weak typeof(self) weakSelf = self;

    self.buttonActionMap[key] = ^{
        switch (control.selectedSegmentIndex) {
            case kSegStep:
                control.selectedSegmentIndex = kSegSlowMo;
                break;

            case kSegSlowMo:
                control.selectedSegmentIndex = kSegSlow;
                break;

            case kSegSlow:
                control.selectedSegmentIndex = kSegFast;
                break;

            case kSegFast:
                control.selectedSegmentIndex = kSegSlowMo;
                break;
        }

        NSArray<NSString *> *actions = [control actionsForTarget:weakSelf forControlEvent:UIControlEventValueChanged];

        if (actions != nil && actions.count > 0) {
            SEL sel = NSSelectorFromString(actions.firstObject);
            IMP imp = [weakSelf methodForSelector:sel];
            void (*func)(id, SEL, id) = (void (*)(id, SEL, id))imp;
            func(weakSelf, sel, control);
        }
    };

    if (self.controller) {
        control.originalTitles = titles;
        control.firstSegmentButton = first;
        control.otherSegmentButtons = rest;

        // Assume first button is already sorted, and the other two are the same


        self.buttonActionMap[first] = nil;       // Button A is special. :-)


        self.buttonActionMap[rest] = self.buttonActionMap[key];
    } else {
        control.originalTitles = nil;
        control.firstSegmentButton = nil;
        control.otherSegmentButtons = nil;

        for (int i = 0; i < titles.count; i++) {
            [control setTitle:titles[i] forSegmentAtIndex:i];
        }

        self.buttonActionMap[first] = nil;
        self.buttonActionMap[rest] = nil;
    }

    [control setSelectedSegmentIndex:control.selectedSegmentIndex];
}

- (void)hideSegment:(UISegmentedControl *)ctrl; {
    ctrl.hidden = YES;
    self.buttonActionMap[kButtonU] = nil;
    self.buttonActionMap[kButtonL] = nil;
    self.buttonActionMap[kButtonR] = nil;
    [self getSettings:NO];
}

- (NSDictionary *)achievementForScreenNum:(int)num {
    return self.achievements [[NSString stringWithFormat:@"%d", num]];
}

- (void)updateButtons {
}

- (NSInteger)nextDoneScreen {
    NSInteger nextOrdinal = _ordinal + 1;

    int nextNum = [Screens.sharedInstance screenFileNumberFromOrdinal:nextOrdinal];

    while (nextOrdinal < self.highestOrdinal && [self achievementForScreenNum:nextNum] == nil) {
        nextOrdinal++;
        nextNum = [Screens.sharedInstance screenFileNumberFromOrdinal:nextOrdinal];
    }

    if ([self achievementForScreenNum:nextNum] == nil || nextOrdinal == self.highestOrdinal) {
        nextOrdinal = -1;
    }

    return nextOrdinal;
}

- (NSInteger)nextUndoneScreen {
    NSInteger next = _ordinal + 1;

    int nextNum = [Screens.sharedInstance screenFileNumberFromOrdinal:next];

    while (next < self.highestOrdinal && [self achievementForScreenNum:nextNum] != nil) {
        next++;
        nextNum = [Screens.sharedInstance screenFileNumberFromOrdinal:next];
    }

    if ([self achievementForScreenNum:nextNum] != nil) {
        next = -1;
    }

    return next;
}

- (void)nextScreen {
    if (_ordinal < self.highestOrdinal) {
        _ordinal++;
        [self saveLevel];
        [self setStateRecording];
        [self initScreen];
    }
}

- (void)changeToScreenOrdinal:(NSInteger)ordinal review:(bool)review {
    if (_unsavedMoves && self.playbackState != PlaybackDone) {
        NSString *title = nil;
        switch (ordinal - _ordinal) {
            case -1:
                title = @"Previous screen";
                break;

            case 1:
                title = @"Next screen";
                break;

            default:
                title = @"Change to screen";
                break;
        }

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:@"You will lose all unsaved progress on this screen."
                                                                preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[self actionWithTitle:@"OK" style:UIAlertActionStyleDestructive
                                    buttonName:kButtonA
                                       keyName:kKeyReturn
                                       handler:^(UIAlertAction *action) {
                                           [self stopPlayback:^{
                                                     self->_ordinal = ordinal;
                                                     [self saveLevel];
                                                     [self initScreen];

                                                     if (review) {
                                                     [self requestReview];
                                                     }
                                           }];
                                       }]];

        [alert addAction:[self actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                    buttonName:kButtonX
                                       keyName:UIKeyInputEscape
                                       handler:^(UIAlertAction *action) {
                                           if (review) {
                                               [self requestReview];
                                           }
                                       }]];

        [self presentViewController:alert animated:YES completion:nil];
    } else {
        _ordinal = ordinal;
        [self saveLevel];
        [self scheduleNextAction:NextActionInitScreen move:0];

        if (review) {
            [self requestReview];
        }
    }
}

- (UIAlertAction *)actionWithTitle:(NSString *)title
                             style:(UIAlertActionStyle)style
                        buttonName:(NSString *)buttonName
                           keyName:(NSString *)key
                           handler:(AlertBlock)handler {
    __block GameViewController *weakSelf = self;

    AlertBlock metaHandler = ^(UIAlertAction *action) {
        void (^ completionBlock)(void) = ^{
            [weakSelf.alertActionMap removeAllObjects];

            if (handler) {
                handler(action);
            }
        };

        if (weakSelf.presentedViewController) {
            [weakSelf dismissViewControllerAnimated:YES completion:completionBlock];
        } else {
            completionBlock();
        }
    };

    self.alertActionMap[key] = metaHandler;

    if (self.controller) {
        self.alertActionMap[buttonName] = metaHandler;
        return [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@ %@", buttonName, title] style:style handler:metaHandler];
    }

    return [UIAlertAction actionWithTitle:title style:style handler:handler];
}

- (void)requestReview {
    Class reviewController = (NSClassFromString(@"SKStoreReviewController"));

    if (reviewController != nil) {
        [SKStoreReviewController requestReview];
    }
}

- (void)displayPlaybackMoves:(int)moves {
}

- (void)displayBusyText:(NSString *)text {
}

- (void)postPlayback {
    _unsavedMoves = NO;
    self.keyStrokes = [self.playbackKeyStrokes mutableCopy];
    [self actionButtonUp];
    [self setStateRecording];
    [self updateButtons];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:kNextScreenAfterPlayback]) {
        if (self->_game.finished) {
            NSInteger next = [self nextDoneScreen];

            if (next > 0) {
                self->_unsavedMoves = NO;
                _ordinal = next;
                [self saveLevel];
                [self scheduleNextAction:NextActionInitScreenAndPlayback move:0];
            }
        }
    }
}

- (void)makeMove:(char)key {
    if (self.presentedViewController == nil) {
        if (self.display.normalFlashing) {
            self.display.normalFlashing = NO;

            if (self.playbackState == PlaybackStepping) {
                [self.display playbackPlayer];
            } else {
                [self.display normalPlayer];
            }
        }

        __block bool playbackDone = NO;

        if (self.playbackState == PlaybackRecording) {
            if (self.keyStrokes) {
                if (self.keyStrokes.length < 10000) {
                    [self.keyStrokes appendFormat:@"%c", key];
                } else {
                    self.playbackState = PlaybackOverrun;
                }
            }
        }

        if (self.playbackState == PlaybackStepping && self.playbackKeyStrokes != nil) {
            if (self.playbackPosition < self.playbackKeyStrokes.length && key != kMoveQuit) {
                key = (char)[self.playbackKeyStrokes characterAtIndex:self.playbackPosition];

                [self displayPlaybackMoves:(int)(self.playbackKeyStrokes.length - self.playbackPosition)];
                self.playbackPosition++;
            } else {
                playbackDone = YES;
            }
        }

        if (self.playbackState != PlaybackDone && !playbackDone) {
            int num = self.screenNum;
            char *howDead = onemove(&num, &_screen_score, &_bell, (char *)"kjhl", (game *)&_game, key);

            __weak typeof(self) weakSelf = self;

            [self.display runSequenceWithCompletion:^{
                              NSString *dead = nil;

                              if (howDead) {
                              dead = [NSString stringWithUTF8String:howDead];
                              }

                              if (dead != nil && self.playbackState != PlaybackStepping) {
                              if (self->_game.quit) {
                              [weakSelf setStateRecording];
                              [weakSelf initScreen];
                              } else {
                              [self.display deadPlayer];
                              [self.display ad_sound:kChMine];


                              UIAlertController *alert = [UIAlertController       alertControllerWithTitle:@"You are dead."
                                                                                             message:[NSString stringWithFormat:@"You were killed by %@", dead]
                                                                                      preferredStyle:UIAlertControllerStyleAlert];

                              [alert addAction:[self       actionWithTitle:@"Start over" style:UIAlertActionStyleDefault
                                                          buttonName:kButtonA
                                                             keyName:kKeyReturn
                                                             handler:^(UIAlertAction *action) {
                                                                 [weakSelf setStateRecording];
                                                                 [weakSelf initScreen];
                                                             }
                              ]];

                              if (self.keyStrokes && self.keyStrokes.length > 1) {
                              [alert addAction:[self   actionWithTitle:@"Playback moves to just before you died" style:UIAlertActionStyleDefault
                                                          buttonName:kButtonX
                                                             keyName:kKeyReturn
                                                             handler:^(UIAlertAction *action) {
                                                                 [weakSelf startPlaybackWithKeyStrokes:[self.keyStrokes substringToIndex:self.keyStrokes.length - 1]];
                                                             }
                              ]];
                              }

                              [alert addAction:[self       actionWithTitle:@"Show me the screen" style:UIAlertActionStyleDefault
                                                          buttonName:kButtonB
                                                             keyName:UIKeyInputEscape
                                                             handler:^(UIAlertAction *action) {
                                                                 self.playbackState = PlaybackDead;
                                                                 [self updateButtons];
                                                             }
                              ]];

                              [self presentViewController:alert animated:YES completion:nil];
                              }
                              } else if (self->_game.finished) {
                              NSString *key = [NSString stringWithFormat:@"%d", self.screenNum];
                              bool better = NO;
                              bool increased = NO;
                              playbackDone = NO;
                              [self.display happyPlayer];

                              if (self.achievements[key] == nil) {
                              self.achievements[key] = @{
                              kAchievementDate: [NSDate date],
                              kAchievementScore: @(self->_screen_score)
                              };

                              [weakSelf mergeAchievement:self.screenNum remote:[NSUbiquitousKeyValueStore defaultStore] localChanged:nil];
                              [weakSelf saveAchievements];
                              [weakSelf writeSavedMoves];
                              increased = YES;
                              } else if (self.keyStrokes.length > 0) {
                              NSNumber *previousScore = weakSelf.achievements[key][kAchievementScore];

                              if (self->_screen_score > previousScore.longValue
                              || (self->_screen_score == previousScore.longLongValue && self.keyStrokes.length < self.savedKeyStrokes.length)) {
                              weakSelf.achievements[key] = @{
                                kAchievementDate: [NSDate date],
                                kAchievementScore: @(self->_screen_score)
                              };

                              [weakSelf saveAchievements];
                              [weakSelf writeSavedMoves];
                              better = YES;
                              }
                              }

                              DEBUG_LOGO(self.achievements);

                              self->_total_score = [self calculateTotalScore];

                              if (self->_gameCenter && self->_total_score > 0) {
                              [[GameCenterMgr sharedManager] reportScore:self->_total_score];
                              [[GameCenterMgr sharedManager] reportAchievements:self.achievements];
                              }

                              if (self.playbackState != PlaybackStepping) {
                              NSString *message = nil;

                              NSString *name = [Screens.sharedInstance visableScreenNameFromOrdinal:self->_ordinal];

                              if (better) {
                              message = [NSString stringWithFormat:@"Screen %@ completed, better than last time. The total score is now %ld!", name, self->_total_score];
                              } else if (increased) {
                              message = [NSString stringWithFormat:@"Screen %@ completed. The total score is now %ld!", name, self->_total_score];
                              } else {
                              message = [NSString stringWithFormat:@"Screen %@ completed, but the total score is unchanged.", name];
                              }

                              UIAlertController *alert = [UIAlertController       alertControllerWithTitle:@"You did it!"
                                                                                             message:message
                                                                                      preferredStyle:UIAlertControllerStyleAlert];

                              UIAlertAction *action = nil;

                              action = [weakSelf       actionWithTitle:@"Playback moves" style:UIAlertActionStyleDefault
                                                      buttonName:kButtonY
                                                         keyName:kKeyP
                                                         handler:^(UIAlertAction *action) {
                                                             [self startPlaybackWithKeyStrokes:self.savedKeyStrokes];
                                                         }
                              ];


                              [alert addAction:action];

                              NSInteger next = [self nextUndoneScreen];

                              if (next > 0) {
                              action = [weakSelf   actionWithTitle:@"Next Uncompleted Screen" style:UIAlertActionStyleDestructive
                                                      buttonName:kButtonA
                                                         keyName:kKeyN
                                                         handler:^(UIAlertAction *action) {
                                                             self->_unsavedMoves = NO;
                                                             [self changeToScreenOrdinal:next review:YES];
                                                         }
                                ];
                              } else {
                              action = [weakSelf   actionWithTitle:@"OK" style:UIAlertActionStyleDestructive
                                                      buttonName:kButtonA
                                                         keyName:kKeyReturn
                                                         handler:^(UIAlertAction *action) {
                                                             [self requestReview];
                                                         }

                                ];
                              }

                              [alert addAction:action];

                              [self presentViewController:alert animated:YES completion:nil];
                              } else {
                              [self postPlayback];
                              }
                              } else {
                              if (!self->_unsavedMoves) {
                              self->_unsavedMoves = YES;
                              [weakSelf updateButtons];
                              }
                              }

                              if (playbackDone) {
                              [self postPlayback];
                              }
                          }];


#ifdef DEBUGLOGGING
            [self displayBusyText:[NSString stringWithFormat:@"A-%d F-%lu C-%lu", self.display.animationCount, (unsigned long)self.display.fastMoveCache.count, (unsigned long)self.display.cacheHits]];
#endif
        }

        if (playbackDone) {
            [self postPlayback];
        }
    }
}

- (NSString *)getMovesFileName:(int)screen {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths.firstObject;
    NSString *fullPathName = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:kSavedMoves, screen]];

    return fullPathName;
}

- (NSString *)getSavedMoves:(int)screen {
    NSString *fullPathName = [self getMovesFileName:screen];

    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPathName]) {
        NSDictionary *savedMoves = [NSDictionary dictionaryWithContentsOfFile:fullPathName];

        NSString *raw = savedMoves[kSavedMovesKeys];

        NSMutableString *expanded = [NSMutableString string];

        int repeat = 0;
        unichar ch = 0;

        for (int i = 0; i < raw.length; i++) {
            ch = [raw characterAtIndex:i];

            if (ch >= '0' && ch <= '9') {
                repeat = repeat * 10 + (ch - '0');
            } else {
                if (repeat == 0) {
                    [expanded appendString:[NSString stringWithCharacters:&ch length:1]];
                } else {
                    for (int j = 0; j < repeat; j++) {
                        [expanded appendString:[NSString stringWithCharacters:&ch length:1]];
                    }
                }

                repeat = 0;
            }
        }

        //NSLog(@"original   %@", raw);
        //NSLog(@"expanded   %@", expanded);

        return expanded;
    }

    return nil;
}

+ (void)write:(NSMutableString *)compressed ch:(unichar)ch repeat:(int)repeat {
    if (repeat == 1) {
        [compressed appendString:[NSString stringWithCharacters:&ch length:1]];
    } else if (repeat == 2) {
        [compressed appendFormat:@"%c%c", ch, ch];
    } else {
        [compressed appendFormat:@"%d%c", repeat, ch];
    }
}

- (void)writeSavedMoves {
    [self writeSavedMoves:self.keyStrokes screen:self.screenNum];
    self.savedKeyStrokes = [self.keyStrokes copy];
    [self mergeMove:self.screenNum remote:[NSUbiquitousKeyValueStore defaultStore]];
}

- (void)writeSavedMoves:(NSString *)moves screen:(int)screen {
    if (moves && moves.length > 0) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = paths.firstObject;
        NSString *fullPathName = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:kSavedMoves, screen]];

        NSMutableString *compressed = [NSMutableString string];

        int repeat = 0;
        unichar ch = 0;
        unichar lastch = [moves characterAtIndex:0];

        for (int i = 0; i < moves.length; i++) {
            ch = [moves characterAtIndex:i];

            // We may be passing an already RLE string through here to the
            // cloud so don't do it again.
            if (ch == lastch && !isnumber(ch)) {
                repeat++;
            } else {
                [GameViewController write:compressed ch:lastch repeat:repeat];
                repeat = 1;
            }

            lastch = ch;
        }

        [GameViewController write:compressed ch:ch repeat:repeat];

        //NSLog(@"original   %@", self.keyStrokes);
        // NSLog(@"compressed %@", compressed);

        NSDictionary *savedMoves = @{ kSavedMovesKeys: compressed };


        [savedMoves writeToFile:fullPathName atomically:YES];
    }
}

- (void)getAchievements {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths.firstObject;
    NSString *fullPathName = [documentsDirectory stringByAppendingPathComponent:kAchievements];

    if (![[NSFileManager defaultManager] fileExistsAtPath:fullPathName]) {
        self.achievements = [NSMutableDictionary dictionary];

        [self.achievements writeToFile:fullPathName atomically:YES];
    } else {
        self.achievements = [NSMutableDictionary dictionaryWithContentsOfFile:fullPathName];
    }
}

- (void)saveAchievements {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths.firstObject;
    NSString *fullPathName = [documentsDirectory stringByAppendingPathComponent:kAchievements];

    if (![self.achievements writeToFile:fullPathName atomically:YES]) {
        ERROR_LOG(@"not saved\n");
    }
}

- (void)handleChangeInUserSettings:(id)obj {
    [self getSettings:NO];
}

- (bool)showHelpOnce {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    bool showHelp = NO;

    if ([defaults boolForKey:kShowHelp]) {
        showHelp = YES;
        [defaults setBool:NO forKey:kShowHelp];
    }

    return showHelp;
}

- (void)displayLeftHanded:(bool)left {
}

- (void)displayGameCenter:(bool)enabled {
}

- (void)displayDonated:(bool)donated capable:(bool)capable processing:(bool)processing {
}

- (void)getSettings:(bool)sync {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (sync) {
        [defaults synchronize];
    }

    _donated = [defaults boolForKey:kDonated];

    if (self.playbackState != PlaybackStepping) {
        self.display.animationDuration = kAnimationDurationV;
        self.rapidFireDuration = kRapidFireDurationV;
        self.display.playerDuration = self.rapidFireDuration;
    }

    _startPlaybackSpeed = (int)[defaults integerForKey:kStartPlaybackSpeed];
    self.display.sounds = [defaults boolForKey:kSounds];

    DEBUG_LOGF(self.display.animationDuration);
    DEBUG_LOGF(self.rapidFireDuration);

    // NSLog(@"duration %f\n", self.display.animationDuration);

    int num = (int)[defaults integerForKey:kCurrentLevel];

    _ordinal = [Screens.sharedInstance ordinalFromNum:num];

    bool oldGameCenter = _gameCenter;

    _gameCenter = [defaults boolForKey:kGameCenter];

    if (!_gameCenter) {
        [GameCenterMgr noGameCenter];
    } else if (!oldGameCenter) {
        [[GameCenterMgr sharedManager] authenticatePlayer:^{
                                           if (self->_total_score > 0) {
                                           [[GameCenterMgr sharedManager] reportScore:self->_total_score];
                                           [[GameCenterMgr sharedManager] reportAchievements:self.achievements];
                                           }
                                       }];
    }

    tileStyle oldRetro = WandererTile.style;

    [WandererTile setStyle:(tileStyle)[defaults integerForKey:kStyle]];

    if (oldRetro != WandererTile.style) {
        if (!_busy) {
            [self.display ad_init_completed];
        } else {
            _reinitForRetro = YES;
        }
    }

    [self displayLeftHanded:[[NSUserDefaults standardUserDefaults] boolForKey:kLeftHanded] && self.view];

    [self displayGameCenter:_gameCenter];

    [self displayDonated:_donated capable:[SKPaymentQueue canMakePayments] processing:NO];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleChangeInUserSettings:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

- (bool)showPrevScreen {
    return (_ordinal > 0);
}

- (bool)showNextScreen {
    return ((_ordinal + 1) < self.highestOrdinal);
}

- (void)displaySetLabels {
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self toggleHardwareController:YES];


    // For testing donations
    /*
     #ifdef DEBUGLOGGING
       [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDonated];
       DEBUG_LOG(@"Remvoed donation!");

       // NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
       // [defaults setBool:YES forKey:kShowHelp];
     #endif
     */

    [self getAchievements];

    self.alertActionMap = [NSMutableDictionary dictionary];

    // Load the SKScene from 'GameScene.sks'
    GameScene *scene = (GameScene *)[SKScene nodeWithFileNamed:@"GameScene"];

    // Set the scale mode to scale to fit the window
    scene.scaleMode = SKSceneScaleModeAspectFit;
    scene.controller = self;
    self.spriteView.allowsTransparency = YES;
    scene.backgroundColor = [UIColor clearColor];

    // Present the scene
    [self.spriteView presentScene:scene];

    DEBUG_ONLY(
        self.spriteView.showsFPS = YES;
        self.spriteView.showsNodeCount = YES;
        self.spriteView.showsDrawCount = YES;
        self.spriteView.showsQuadCount = YES;
        )

    NSURL *defaultPrefsFile = [[NSBundle mainBundle]
                               URLForResource:@"DefaultPreferences" withExtension:@"plist"];
    NSDictionary *defaultPrefs = [NSDictionary dictionaryWithContentsOfURL:defaultPrefsFile];

    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultPrefs];

    self.display = [[SpriteDisplay alloc] init];

    [self getSettings:YES];

    self.display.boardLayer = scene.boardLayer;



    self.display.view = self.spriteView;
    self.display.delegate = self;

    [self.view sendSubviewToBack:self.spriteView];

    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionTapped:)];

    [[self view] addGestureRecognizer:recognizer];

    memset(&_game, 0, sizeof(_game));

    [self scheduleNextAction:NextActionInitScreen move:0];

    _total_score = [self calculateTotalScore];


    // iCloud
    //  Observer to catch changes from iCloud
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];

    if (store != nil) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        self.observerObj =   [center addObserverForName:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                 object:store
                                                  queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
                                                                                         DEBUG_LOG(@"NSUbiquitousKeyValueStoreDidChangeExternallyNotification");
                                                                                         NSDictionary *userInfo = [notification userInfo];
                                                                                         DEBUG_LOGO(userInfo);

                                                                                         NSNumber *reason = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangeReasonKey];

                                                                                         switch (reason.intValue) {
                                                                                         case NSUbiquitousKeyValueStoreAccountChange:
                                                                                         case NSUbiquitousKeyValueStoreServerChange:
                                                                                         [self mergeCloud];
                                                                                         [self updateButtons];
                                                                                         break;

                                                                                         case NSUbiquitousKeyValueStoreInitialSyncChange:
                                                                                         break;

                                                                                         case NSUbiquitousKeyValueStoreQuotaViolationChange:
                                                                                         break;
                                                                                         }
                                                                                     }];


        [store setString:@"v" forKey:@"testKey"];
        [store synchronize];

        [self mergeCloud];

        [self updateButtons];
    }

    [self.view becomeFirstResponder];

#if TARGET_OS_UIKITFORMAC
#define KeyCommandD(I, A, D) [UIKeyCommand keyCommandWithInput:I modifierFlags:0 action:A]
#else
#define KeyCommandD(I, A, D) [UIKeyCommand keyCommandWithInput:I modifierFlags:0 action:A discoverabilityTitle:D]
#endif
#define KeyCommandU(I, A)    [UIKeyCommand keyCommandWithInput:I modifierFlags:0 action:A]


    self.keyCommands = @[
        KeyCommandD(UIKeyInputUpArrow,                       @selector(keyboardUp:),         @"Up"),
        KeyCommandD([NSString stringWithChar:kMoveKeyUp],    @selector(keyboardUp:),         @"Up"),
        KeyCommandD(UIKeyInputDownArrow,                     @selector(keyboardDown:),       @"Down"),
        KeyCommandD([NSString stringWithChar:kMoveKeyDown],  @selector(keyboardDown:),       @"Down"),
        KeyCommandD(UIKeyInputLeftArrow,                     @selector(keyboardLeft:),       @"Left"),
        KeyCommandD([NSString stringWithChar:kMoveKeyLeft],  @selector(keyboardLeft:),       @"Left"),
        KeyCommandD(UIKeyInputRightArrow,                    @selector(keyboardRight:),      @"Right"),
        KeyCommandD([NSString stringWithChar:kMoveKeyRight], @selector(keyboardRight:),     @"Right"),
        KeyCommandD([NSString stringWithChar:kMoveKeySkip],  @selector(keyboardSkip:),      @"Skip"),
        KeyCommandD(UIKeyInputEscape,                        @selector(keyboardAction:),    @"Start over"),
        KeyCommandU(kKeyReturn,                              @selector(keyboardAction:)),
        KeyCommandU(kKeyR,                                   @selector(keyboardAction:)),
        KeyCommandD(kKeyP,                                   @selector(keyboardAction:),    @"Start playback"),
        KeyCommandD(kKeyX,                                   @selector(keyboardAction:),    @"Playback speed"),
        KeyCommandD(kKeyS,                                   @selector(keyboardAction:),    @"Save checkpoint"),
        KeyCommandD(kKeyD,                                   @selector(keyboardAction:),    @"Stop playback"),
        KeyCommandD(kKeyQ,                                   @selector(keyboardAction:),    @"Previous Screen"),
        KeyCommandD(kKeyW,                                   @selector(keyboardAction:),    @"Next Screen")
    ];
}

- (void)viewDidLayoutSubviews {
    if (self.display.diamondsLabel == nil) {
        [self displaySetLabels];
    }
}

- (void)controlClusterTouchedUp:(id)sender event:(UIEvent *)event {
    if (!_busyTouched) {
        [self actionButtonUp];
    }

    if ([sender isKindOfClass:[DirectionClusterControl class]]) {
        [((DirectionClusterControl *)sender).upperView fadeOut];
    }
}

- (void)controlClusterTouched:(DirectionClusterControl *)sender event:(UIEvent *)event {
    char move = [sender getDirectionTouchedforEvent:event];

    if (!_busy ||
        (move == kMoveKeyStep && self.playbackState == PlaybackStepping
         && self.getDisplayPlaybackSpeed != kSegStep)) {
        [self actionDirection:move];
        [sender.upperView touched:move];
        _busyTouched = NO;
    } else {
        _busyTouched = YES;
    }
}

- (void)mergeCloud {
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];

    DEBUG_LOGO([store.dictionaryRepresentation allKeys]);

#if 0
    NSArray *keys = [store.dictionaryRepresentation allKeys];

    for (NSString *key in keys) {
        [store removeObjectForKey:key];
    }

#endif

    if ([self mergeAchievements:store]) {
        DEBUG_LOG(@"iCloud: Updated store with achievements\n");
    }

    if ([self mergeMoves:store]) {
        DEBUG_LOG(@"iCloud: Updated store with moves\n");
    }
}

- (bool)mergeAchievements:(NSUbiquitousKeyValueStore *)store {
    bool cloudChanged = NO;
    bool localChanged = NO;
    int screenNum;

    for (NSInteger ordinal = 0; ordinal < Screens.sharedInstance.screenOrdinalCount; ordinal++) {
        screenNum = [Screens.sharedInstance screenFileNumberFromOrdinal:ordinal];

        if ([self mergeAchievement:screenNum remote:store localChanged:&localChanged]) {
            cloudChanged = YES;
        }
    }

    if (localChanged) {
        [self saveAchievements];
    }

    return cloudChanged;
}

- (bool)mergeAchievement:(int)i remote:(NSUbiquitousKeyValueStore *)store localChanged:(bool *)localChanged {
    if (store == nil) {
        return NO;
    }

    bool cloudChanged = NO;
    NSString *localKey = [NSString stringWithFormat:@"%d", i];
    NSString *cloudScoreKey = [NSString stringWithFormat:@"Score%d", i];
    NSString *cloudDateKey = [NSString stringWithFormat:@"ScoreDate%d", i];

    NSDictionary *local = self.achievements[localKey];
    NSNumber *cloudScore = [store objectForKey:cloudScoreKey];
    NSDate *cloudDate = [store objectForKey:cloudDateKey];
    NSNumber *localScore = local ? local[kAchievementScore] : nil;
    NSNumber *localDate = local ? local[kDate] : nil;


    bool copyToRemote = NO;
    bool copyToLocal = NO;

    if (local == nil && cloudScore != nil) {
        copyToLocal = YES;
    } else if (local != nil && cloudScore == nil) {
        copyToRemote = YES;
    } else {
        if (localScore && cloudScore && localScore.intValue < cloudScore.intValue) {
            copyToLocal = YES;
        }

        if (localScore && cloudScore && localScore.intValue > cloudScore.intValue) {
            copyToRemote = YES;
        }
    }

    if (copyToRemote && localDate) {
        DEBUG_LOG(@"iCloud: Achievement %d uploaded to cloud\n", i);
        [store setObject:localScore forKey:cloudScoreKey];
        [store setObject:localDate forKey:cloudDateKey];

        cloudChanged = YES;
    }

    if (copyToLocal) {
        DEBUG_LOG(@"iCloud: Achievement %d downloaded from cloud\n", i);
        self.achievements[localKey] = @{ kAchievementScore: cloudScore,
                                         kDate: cloudDate };

        if (localChanged) {
            *localChanged = YES;
        }
    }

    return cloudChanged;
}

- (bool)mergeMoves:(NSUbiquitousKeyValueStore *)store {
    bool cloudChanged = NO;
    int screenNum;

    for (NSInteger ordinal = 0; ordinal < Screens.sharedInstance.screenOrdinalCount; ordinal++) {
        screenNum = [Screens.sharedInstance screenFileNumberFromOrdinal:ordinal];

        if ([self mergeMove:screenNum remote:store]) {
            cloudChanged = YES;
        }
    }

    return cloudChanged;
}

- (bool)mergeMove:(int)i remote:(NSUbiquitousKeyValueStore *)store {
    if (store == nil) {
        return NO;
    }

    bool cloudChanged = NO;
    NSString *localMoves = [self getSavedMoves:i];
    NSDate *localDate = nil;
    NSError *error = nil;
    NSURL *fileUrl = [NSURL fileURLWithPath:[self getMovesFileName:i]];
    NSString *remoteMoves = nil;
    NSDate *remoteDate = nil;


    if (localMoves != nil) {
        [fileUrl getResourceValue:&localDate forKey:NSURLContentModificationDateKey error:&error];

        if (error) {
            localDate = [NSDate dateWithTimeIntervalSince1970:0];
        }
    }

    NSString *cloudMovesKey = [NSString stringWithFormat:@"Moves%d", i];
    NSString *cloudDateKey = [NSString stringWithFormat:@"MovesDate%d", i];


    bool copyToRemote = NO;
    bool copyToLocal = NO;


    remoteMoves = [store objectForKey:cloudMovesKey];
    remoteDate = [store objectForKey:cloudDateKey];

    if (remoteMoves == nil && localMoves != nil) {
        copyToRemote = YES;
    } else if (remoteMoves != nil && localMoves == nil) {
        copyToLocal = YES;
    } else { // both exist.  Gulp
        if (remoteMoves == nil || remoteDate == nil) {
            if (localMoves != nil && localDate != nil) {
                copyToRemote = YES;
            }
        } else {
            NSTimeInterval diff = [remoteDate timeIntervalSinceDate:localDate];

            if (diff < 0) {
                copyToRemote = YES;
            }

            if (diff > 0) {
                copyToLocal = YES;
            }
        }
    }

    if (copyToRemote) {
        if (localMoves && localDate) {
            DEBUG_LOG(@"iCloud: Moves %d uploaded to cloud\n", i);

            [store setObject:localMoves forKey:cloudMovesKey];
            [store setObject:localDate forKey:cloudDateKey];
            cloudChanged = YES;
        }
    }

    if (copyToLocal) {
        if (remoteMoves && remoteDate) {
            DEBUG_LOG(@"iCloud: Moves %d downloaded from cloud\n", i);

            [self writeSavedMoves:remoteMoves screen:i];
            [fileUrl setResourceValue:remoteDate forKey:NSURLContentModificationDateKey error:&error];
        }
    }

    return cloudChanged;
}

- (void)scheduleNextAction:(NextAction)action move:(char)move {
    @synchronized(self) {
        self.nextMove = move;
        self.nextAction = action;
    }
}

- (void)processNextAction {
    if (!_busy) {
        @synchronized(self) {
            switch (self.nextAction) {
                case NextActionInitScreenAndPlayback:
                    [self setStateRecording];
                    [self initScreen];
                    [self saveLevel];
                    self.nextAction = NextActionPlayback;
                    break;

                case NextActionInitScreen:
                    [self setStateRecording];
                    [self initScreen];
                    [self saveLevel];
                    self.nextAction = NextActionDoNothing;
                    break;

                case NextActionMove:
                    // DEBUG_LOG(@"NextActionMove");
                    [self makeMove:self.nextMove];

                    if (self.nextAction == NextActionMove) {
                        self.nextAction = NextActionDoNothing;
                        self.nextMove = 0;
                    }

                    break;

                case NextActionDoNothing:
                    break;

                case NextActionPlayback:
                    self.nextAction = NextActionDoNothing;
                    [self actionPlayback];
                    break;
            }
        }
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)scheduleMove:(char)move {
    if (self.nextAction == NextActionDoNothing) {
        [self scheduleNextAction:NextActionMove move:move];
    }
}

- (void)schedulePlayback {
    [self scheduleNextAction:NextActionPlayback move:0];
}

- (void)actionSaveCheckpoint {
    if (self.savedKeyStrokes) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Checkpoint"
                                                                       message:@"Replace the checkpoint for this screen?"
                                                                preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[self actionWithTitle:@"OK" style:UIAlertActionStyleDestructive
                                    buttonName:kButtonA
                                       keyName:kKeyReturn
                                       handler:^(UIAlertAction *action) {
                                           [self writeSavedMoves];
                                           self->_unsavedMoves = NO;
                                           [self updateButtons];
                                       }]];

        [alert addAction:[self actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                    buttonName:kButtonX
                                       keyName:UIKeyInputEscape
                                       handler:nil]];

        [self presentViewController:alert animated:YES completion:nil];
    } else {
        [self writeSavedMoves];
        [self updateButtons];
    }
}

- (void)displayPlaybackSpeed:(int)playbackSpeed {
}

- (void)startPlaybackWithKeyStrokes:(NSString *)keyStrokes {
    self.playbackState = PlaybackStepping;
    self.playbackKeyStrokes = keyStrokes;

    [self displayPlaybackSpeed:_startPlaybackSpeed];
    [self initScreen];
    [self actionPlaybackSpeedChanged];

    [self displayPlaybackMoves:(int)(self.playbackKeyStrokes.length - self.playbackPosition)];
    [self.display playbackPlayer];
    self.display.normalFlashing = NO;
}

- (void)stopPlayback:(dispatch_block_t)block {
    if (self.playbackState != PlaybackRecording) {
        [self actionButtonUp];
        self.playbackState = PlaybackRecording;
        __weak typeof(self) weakSelf = self;
        [self.display cancelSequenceWithCompletion:^{
                          weakSelf.keyStrokes = [[weakSelf.playbackKeyStrokes substringToIndex:weakSelf.playbackPosition] mutableCopy];
                          [weakSelf setStateRecording];
                          [weakSelf updateButtons];

                          if (block) {
                          block();
                          }
                      }];
    } else if (block) {
        block();
    }
}

- (void)actionPlayback {
    switch (self.playbackState) {
        case PlaybackStepping:
            // Copy where we are now into the recording buffer
            [self stopPlayback:nil];
            break;

        case PlaybackDead:
        case PlaybackOverrun:
        case PlaybackRecording:

            if (self.savedKeyStrokes != nil) {
                if (!_unsavedMoves && self.playbackState != PlaybackDone) {
                    [self startPlaybackWithKeyStrokes:self.savedKeyStrokes];
                } else {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Playback to last checkpoint"
                                                                                   message:@"You will lose any unsaved progress on this screen."
                                                                            preferredStyle:UIAlertControllerStyleAlert];

                    [alert addAction:[self actionWithTitle:@"OK" style:UIAlertActionStyleDestructive
                                                buttonName:kButtonA
                                                   keyName:kKeyReturn
                                                   handler:^(UIAlertAction *action) {
                                                       [self.display cancelSequenceWithCompletion:^{
                                                                         [self startPlaybackWithKeyStrokes:self.savedKeyStrokes];
                                                       }];
                                                   }]];

                    [alert addAction:[self actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                buttonName:kButtonX
                                                   keyName:UIKeyInputEscape
                                                   handler:nil]];

                    [self presentViewController:alert animated:YES completion:nil];
                }
            }

            break;

        case PlaybackDone:
            break;
    }
}

- (void)fire {
    [self scheduleMove:self.rapidFireDirection];

    if (_initialRapidFire) {
        [self.rapidFireTimer invalidate];
        self.rapidFireTimer = [NSTimer scheduledTimerWithTimeInterval:self.rapidFireDuration target:self selector:@selector(rapidFire:) userInfo:nil repeats:YES];
        _initialRapidFire = NO;
    }
}

- (void)rapidFire:(id)arg {
    DEBUG_FUNC();

    if (self.rapidFireControllerButton) {
        if (self.controllerConnected && self.rapidFireControllerButton.pressed && self.rapidFireDirection) {
            [self fire];
        } else {
            [self actionButtonUp];
        }
    } else {
        [self fire];
    }
}

- (void)scheduleRapidFire:(GCControllerButtonInput *)controllerButton direction:(char)rapidFireDirection {
    self.rapidFireDirection = rapidFireDirection;
    self.rapidFireControllerButton = controllerButton;

    if (self.rapidFireTimer != nil) {
        [self.rapidFireTimer invalidate];
    }

    _initialRapidFire = YES;

    // initial timer is for a little longer
    self.rapidFireTimer = [NSTimer scheduledTimerWithTimeInterval:self.rapidFireDuration * 1.5 target:self selector:@selector(rapidFire:) userInfo:nil repeats:NO];
}

- (void)actionButtonUp {
    DEBUG_FUNC();
    self.rapidFireControllerButton = nil;
    [self.rapidFireTimer invalidate];
    self.rapidFireTimer = nil;
    self.rapidFireDirection = 0;
}

- (void)actionDirection:(char)direction {
    [self scheduleMove:direction];
    [self scheduleRapidFire:nil direction:direction];
}

- (void)keyboardAction:(UIKeyCommand *)key {
    if (self.alertActionMap[key.input] != nil) {
        self.alertActionMap[key.input](nil);
    } else if (self.buttonActionMap[key.input] != nil) {
        self.buttonActionMap[key.input]();
    }
}

- (void)keyboardUp:(id)arg {
    if (self.presentedViewController == nil) {
        [self scheduleMove:kMoveKeyUp];
        [self actionButtonUp];
    }
}

- (void)keyboardDown:(id)arg {
    if (self.presentedViewController == nil) {
        [self scheduleMove:kMoveKeyDown];
        [self actionButtonUp];
    }
}

- (void)keyboardLeft:(id)arg {
    if (self.presentedViewController == nil) {
        [self scheduleMove:kMoveKeyLeft];
        [self actionButtonUp];
    }
}

- (void)keyboardRight:(id)arg {
    if (self.presentedViewController == nil) {
        [self scheduleMove:kMoveKeyRight];
        [self actionButtonUp];
    }
}

- (void)keyboardSkip:(UIKeyCommand *)arg {
    if (self.presentedViewController == nil) {
        if (self.playbackState == PlaybackStepping && self.getDisplayPlaybackSpeed != kSegStep) {
            [self displayPlaybackSpeed:kSegStep];
            [self actionPlaybackSpeedChanged];
        }

        [self scheduleMove:kMoveKeySkip];
        [self actionButtonUp];
    } else {
        [self keyboardAction:arg];
    }
}

- (void)actionStartOver {
    if (self.playbackState == PlaybackDead) {
        [self setStateRecording];
        [self initScreen];
    } else if (_unsavedMoves && self.playbackState != PlaybackDone) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Start this screen over"
                                                                       message:@"You will lose any unsaved progress for this screen."
                                                                preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[self actionWithTitle:@"OK" style:UIAlertActionStyleDestructive
                                    buttonName:kButtonA
                                       keyName:kKeyReturn
                                       handler:^(UIAlertAction *action) {
                                           [self stopPlayback:^{
                                                     [self makeMove:kMoveQuit];
                                           }];
                                       }]];

        [alert addAction:[self actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                    buttonName:kButtonX
                                       keyName:UIKeyInputEscape
                                       handler:nil]];

        [self presentViewController:alert animated:YES completion:nil];
    } else if (self.playbackState == PlaybackDone) {
        if (self.savedKeyStrokes != nil) {
            [self setStateRecording];
            [self initScreen];
        }
    } else {
        [self scheduleMove:kMoveQuit];
    }
}

- (void)actionNext {
    if (_ordinal < self.highestOrdinal) {
        [self changeToScreenOrdinal:_ordinal + 1 review:NO];
    }
}

- (void)setStateRecording {
    self.playbackState = PlaybackRecording;
    [self.display normalPlayer];
}

- (void)actionPrevious {
    if (_ordinal > 0) {
        [self changeToScreenOrdinal:_ordinal - 1 review:NO];
    }
}

#define BUTTON_BOUNCE -0.3

- (NSDate *)keyStroke:(char)ch last:(NSDate *)date value:(float)value pressed:(bool)pressed button:(GCControllerButtonInput *)button {
    //    NSLog(@"%c %f %f %d\n",ch, [date timeIntervalSinceNow], value, pressed);

    if ((pressed && (date == nil || [date timeIntervalSinceNow] < BUTTON_BOUNCE)) && self.view.userInteractionEnabled && self.presentedViewController == nil) {
        [self scheduleMove:ch];

        if (button) {
            [self scheduleRapidFire:button direction:ch];
        }

        return [NSDate date];
    }

    return date;
}

- (int)getDisplayPlaybackSpeed {
    return 0;  // self.playbackSpeedSeg.selectedSegmentIndex
}

- (void)clearController {
    if (self.controller) {
        [self.controller.extendedGamepad.dpad.up setValueChangedHandler:nil];
        [self.controller.extendedGamepad.dpad.down setValueChangedHandler:nil];
        [self.controller.extendedGamepad.dpad.left setValueChangedHandler:nil];
        [self.controller.extendedGamepad.dpad.right setValueChangedHandler:nil];
#if !TARGET_OS_UIKITFORMAC
        [self.controller setControllerPausedHandler:nil];
#else
        [self.controller.extendedGamepad.buttonMenu setValueChangedHandler:nil];
#endif
        [self.controller.extendedGamepad.rightShoulder setValueChangedHandler:nil];
        [self.controller.extendedGamepad.leftShoulder setValueChangedHandler:nil];
        [self.controller.extendedGamepad.buttonA setValueChangedHandler:nil];
        [self.controller.extendedGamepad.buttonB setValueChangedHandler:nil];
        [self.controller.extendedGamepad.buttonX setValueChangedHandler:nil];
        [self.controller.extendedGamepad.buttonY setValueChangedHandler:nil];

        self.controller = nil;
    }
}

#define BUTTON_LOG(X) DEBUG_LOG(@"Button: %@ pressed %d value %f delta %f blocked %d\n", X, pressed, value, [depressedDate timeIntervalSinceNow], [depressedDate timeIntervalSinceNow] >= BUTTON_BOUNCE)
- (bool)setupControler {
    NSArray *controllers = [GCController controllers];

    if (controllers != nil && controllers.count > 0) {
        self.controller = controllers[0];

        if (self.controller.extendedGamepad) {
            self.controllerConnected = YES;

            __weak typeof(self) weakSelf = self;
            __block NSDate *depressedDate = [NSDate date];

            [self.controller.extendedGamepad.dpad.up setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                                                         BUTTON_LOG(kButtonU);

                                                         if (weakSelf.buttonActionMap[kButtonU]) {
                                                         if (pressed &&  [depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE) {
                                                         (weakSelf.buttonActionMap[kButtonU])();
                                                         depressedDate = [NSDate date];
                                                         }
                                                         } else if (self.playbackState == PlaybackRecording) {
                                                         depressedDate = [weakSelf keyStroke:kMoveKeyUp last:depressedDate value:value pressed:pressed button:button];
                                                         }
                                                     }];

            [self.controller.extendedGamepad.dpad.down setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                                                           BUTTON_LOG(kButtonD);

                                                           if (self.playbackState == PlaybackRecording) {
                                                           depressedDate = [weakSelf keyStroke:kMoveKeyDown last:depressedDate value:value pressed:pressed button:button];
                                                           }
                                                       }];


            [self.controller.extendedGamepad.dpad.left setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                                                           BUTTON_LOG(kButtonL);

                                                           if (weakSelf.buttonActionMap[kButtonL]) {
                                                           if (pressed &&  [depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE) {
                                                           (weakSelf.buttonActionMap[kButtonL])();
                                                           depressedDate = [NSDate date];
                                                           }
                                                           } else if (self.playbackState == PlaybackRecording) {
                                                           depressedDate = [weakSelf keyStroke:kMoveKeyLeft last:depressedDate value:value pressed:pressed button:button];
                                                           }
                                                       }];

            [self.controller.extendedGamepad.dpad.right setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                                                            BUTTON_LOG(kButtonR);

                                                            if (weakSelf.buttonActionMap[kButtonR]) {
                                                            if (pressed &&  [depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE) {
                                                            (weakSelf.buttonActionMap[kButtonR])();
                                                            depressedDate = [NSDate date];
                                                            }
                                                            } else if (self.playbackState == PlaybackRecording) {
                                                            depressedDate = [weakSelf keyStroke:kMoveKeyRight last:depressedDate value:value pressed:pressed button:button];
                                                            }
                                                        }];

#if !TARGET_OS_UIKITFORMAC
            [self.controller setControllerPausedHandler: ^ (GCController * controller)
#else
            [self.controller.extendedGamepad.buttonMenu setValueChangedHandler: ^(GCControllerButtonInput *button, float value, BOOL pressed)
#endif

                                                            {
                                                            #if !TARGET_OS_UIKITFORMAC
                                                            #ifdef DEBUGLOGGING
                                                                bool pressed = YES;
                                                                float value = 0.0;
                                                            #endif
                                                            #endif
                                                                BUTTON_LOG(kButtonPause);

                                                                if ([depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE) {
                                                                    depressedDate = [NSDate date];

                                                                    if (weakSelf.presentedViewController == nil) {
                                                                        if (weakSelf.buttonActionMap[kButtonPause]) {
                                                                            (weakSelf.buttonActionMap[kButtonPause])();
                                                                        }
                                                                    }
                                                                }
                                                            }];

            [self.controller.extendedGamepad.rightShoulder setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                                                               BUTTON_LOG(kButtonR1);

                                                               if (pressed &&  [depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE) {
                                                               if (weakSelf.presentedViewController == nil) {
                                                               if (weakSelf.buttonActionMap[kButtonR1]) {
                                                               (weakSelf.buttonActionMap[kButtonR1])();
                                                               }
                                                               }

                                                               depressedDate = [NSDate date];
                                                               }
                                                           }];

            [self.controller.extendedGamepad.leftShoulder setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                                                              BUTTON_LOG(kButtonL1);

                                                              if (pressed && [depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE) {
                                                              if (weakSelf.presentedViewController == nil) {
                                                              if (weakSelf.buttonActionMap[kButtonL1]) {
                                                              (weakSelf.buttonActionMap[kButtonL1])();
                                                              }
                                                              }

                                                              depressedDate = [NSDate date];
                                                              }
                                                          }];

            [self.controller.extendedGamepad.rightTrigger setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                                                              BUTTON_LOG(kButtonR2);

                                                              if (pressed && [depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE) {
                                                              if (weakSelf.presentedViewController == nil) {
                                                              if (weakSelf.buttonActionMap[kButtonR2]) {
                                                              (weakSelf.buttonActionMap[kButtonR2])();
                                                              }
                                                              }

                                                              depressedDate = [NSDate date];
                                                              }
                                                          }];

            [self.controller.extendedGamepad.leftTrigger setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                                                             BUTTON_LOG(kButtonL2);

                                                             if (pressed && [depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE) {
                                                             if (weakSelf.presentedViewController == nil) {
                                                             if (weakSelf.buttonActionMap[kButtonL2]) {
                                                             (weakSelf.buttonActionMap[kButtonL2])();
                                                             }
                                                             }

                                                             depressedDate = [NSDate date];
                                                             }
                                                         }];

            [self.controller.extendedGamepad.buttonA setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                                                         BUTTON_LOG(kButtonA);

                                                         if (weakSelf.presentedViewController) {
                                                         if (pressed && [depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE) {
                                                         if (weakSelf.alertActionMap[kButtonA]) {
                                                         (weakSelf.alertActionMap[kButtonA])(nil);
                                                         }

                                                         depressedDate = [NSDate date];
                                                         }
                                                         } else if (self.playbackState != PlaybackStepping || self.getDisplayPlaybackSpeed == kSegStep) {
                                                         depressedDate = [weakSelf keyStroke:kMoveKeySkip last:depressedDate value:value pressed:pressed button:button];
                                                         } else if (self.playbackState == PlaybackStepping && self.getDisplayPlaybackSpeed != kSegStep) {
                                                         [self displayPlaybackSpeed:kSegStep];
                                                         [self actionPlaybackSpeedChanged];
                                                         }
                                                     }];

            [self.controller.extendedGamepad.buttonB setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                                                         BUTTON_LOG(kButtonB);

                                                         if (pressed && [depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE) {
                                                         if (weakSelf.presentedViewController) {
                                                         if (weakSelf.alertActionMap[kButtonB]) {
                                                         (weakSelf.alertActionMap[kButtonB])(nil);
                                                         }
                                                         } else {
                                                         if (weakSelf.buttonActionMap[kButtonB]) {
                                                         (weakSelf.buttonActionMap[kButtonB])();
                                                         }
                                                         }

                                                         depressedDate = [NSDate date];
                                                         }
                                                     }];

            [self.controller.extendedGamepad.buttonX setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                                                         BUTTON_LOG(kButtonX);

                                                         if (pressed && [depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE) {
                                                         if (weakSelf.presentedViewController) {
                                                         if (weakSelf.alertActionMap[kButtonX]) {
                                                         (weakSelf.alertActionMap[kButtonX])(nil);
                                                         }
                                                         } else {
                                                         if (weakSelf.buttonActionMap[kButtonX]) {
                                                         (weakSelf.buttonActionMap[kButtonX])();
                                                         }
                                                         }

                                                         depressedDate = [NSDate date];
                                                         }
                                                     }];

            [self.controller.extendedGamepad.buttonY setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                                                         BUTTON_LOG(kButtonY);

                                                         if (pressed && [depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE) {
                                                         if (weakSelf.presentedViewController) {
                                                         if (weakSelf.alertActionMap[kButtonY]) {
                                                         (weakSelf.alertActionMap[kButtonY])(nil);
                                                         }
                                                         } else {
                                                         if (weakSelf.buttonActionMap[kButtonY]) {
                                                         (weakSelf.buttonActionMap[kButtonY])();
                                                         }
                                                         }

                                                         depressedDate = [NSDate date];
                                                         }
                                                     }];
        }

        return YES;
    }

    self.controllerConnected = NO;
    return NO;
}

- (void)controllerDiscovered:(NSNotification *)connectedNotification {
    [self setupControler];
    [self updateButtons];
}

- (void)controllerGone:(NSNotification *)connectedNotification {
    [self clearController];
    self.controllerConnected = NO;
    [self.buttonActionMap removeAllObjects];
    [self updateButtons];
}

- (void)toggleHardwareController:(BOOL)useHardware {
    if (useHardware) {
        [self setupControler];
        {
            if ([[GCController controllers] count] == 0) {
                [GCController startWirelessControllerDiscoveryWithCompletionHandler:nil];

                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(controllerDiscovered:)
                                                             name:GCControllerDidConnectNotification
                                                           object:nil];

                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(controllerGone:)
                                                             name:GCControllerDidDisconnectNotification
                                                           object:nil];
            }
        }
    }
}

- (void)actionSwipeRight {
    [self scheduleMove:kMoveKeyRight];
}

- (void)actionSwipeLeft {
    [self scheduleMove:kMoveKeyLeft];
}

- (void)actionSwipeUp {
    [self scheduleMove:kMoveKeyUp];
}

- (void)actionSwipeDown {
    [self scheduleMove:kMoveKeyDown];
}

- (void)actionTapped:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        /*
           CGPoint screenOpposite = CGPointMake(self.display.boardLayer.position.x + kTileWidth*kBoardWidth, self.display.boardLayer.position.y + kTileHeight*kBoardHeight);

           CGPoint origin    = [self.spriteView convertPoint:self.display.boardLayer.position fromScene:self.spriteView.scene];
           CGPoint opposite  = [self.spriteView convertPoint:screenOpposite fromScene:self.spriteView.scene];

           origin = CGPointOffsetted(origin, self.spriteView.frame.origin);
           opposite = CGPointOffsetted(opposite, self.spriteView.frame.origin);
         */

        CGPoint scenePoint = [self.spriteView convertPoint:[sender locationInView:self.self.spriteView] toScene:self.spriteView.scene];

        CGRect gameRect = CGRectMake(self.display.boardLayer.position.x, self.display.boardLayer.position.y, kTileWidth * kBoardWidth, kTileHeight * kBoardHeight);

        // Origin is bottom left

        if (CGRectContainsPoint(gameRect, scenePoint)) {
            [self scheduleMove:kMoveKeySkip];
        }
    }
}

- (void)showBusy:(bool)busy {
}

- (void)animationsStarted {
    _busy = YES;

    if (self.busyTimer != nil) {
        [self.busyTimer invalidate];
        self.busyTimer = nil;;
    } else {
        [self showBusy:YES];
    }
}

- (void)animationsDone {
    _busy = NO;

    if (_reinitForRetro) {
        _reinitForRetro = NO;
        [self.display ad_init_completed];
    }

    self.busyTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:NO block:^(NSTimer *timer) {
                                                                                 self.busyTimer = nil;
                                                                                 [self showBusy:NO];
                                                                             }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showScreenSelector"]) {
        ScreenSelector *controller = (ScreenSelector *)segue.destinationViewController;
        controller.gameView = self;
    }
}

- (NSInteger)currentScreenOrdinal {
    return _ordinal;
}

- (NSInteger)highestOrdinal {
    return [Screens.sharedInstance screensAvailable:self.achievements];
}

- (long)totalScore {
    return _total_score;
}

- (void)actionShowHighScores {
    if (_gameCenter) {
        [[GameCenterMgr sharedManager] showLeaderboard];
    }
}

- (void)actionShowAchievements {
    if (_gameCenter) {
        [[GameCenterMgr sharedManager] showAchievements];
    }
}

- (void)actionPlaybackSpeedChanged {
    if (self.playbackState == PlaybackStepping) {
        // NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        switch (self.getDisplayPlaybackSpeed) {
            case kSegStep:
                [self actionButtonUp];
                self.display.animationDuration = kAnimationDurationV;
                self.rapidFireDuration = kRapidFireDurationV;
                self.display.playerDuration = self.rapidFireDuration;
                break;

            case kSegSlowMo:
                self.display.animationDuration = kRapidFireDurationV;
                self.rapidFireDuration = kRapidFireDurationV;
                self.display.playerDuration = self.rapidFireDuration;
                [self scheduleRapidFire:nil direction:kMoveKeySkip];
                break;

            case kSegSlow:
                self.display.animationDuration = kAnimationDurationV;
                self.rapidFireDuration = kRapidFireDurationV;
                self.display.playerDuration = self.rapidFireDuration;
                [self scheduleRapidFire:nil direction:kMoveKeySkip];
                break;

            case kSegFast:
                self.display.playerDuration = 0;
                self.display.animationDuration = 0;
                self.rapidFireDuration = 0;
                [self scheduleRapidFire:nil direction:kMoveKeySkip];
                break;
        }
        [self updateButtons];
    }
}

#pragma mark In app purchases

- (void)donated {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setBool:YES forKey:kDonated];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)actionDonate {
    if ([SKPaymentQueue canMakePayments]) {
        SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:kDonateProductIdentifier]];
        productsRequest.delegate = self;
        [productsRequest start];
        // self.donateButton.titleLabel.text=@"Working...";
        // self.donateButton.enabled = NO;
        [self displayDonated:_donated capable:[SKPaymentQueue canMakePayments] processing:YES];
    }
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    dispatch_async(dispatch_get_main_queue(), ^{
        SKProduct *validProduct = nil;
        NSInteger count = [response.products count];

        if (count > 0) {
            validProduct = [response.products objectAtIndex:0];

            NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
            [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
            [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
            [numberFormatter setLocale:validProduct.priceLocale];

            //      NSLocale* storeLocale = validProduct.priceLocale;
            //      NSString *storeCountry = (NSString*)CFLocaleGetValue((CFLocaleRef)storeLocale, kCFLocaleCountryCode);
            NSString *price = [numberFormatter stringFromNumber:validProduct.price];

            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Donate"
                                                                           message:[NSString stringWithFormat:@"If you like this app, would you donate %@ to the developer? The features of the app will rename the same, but the 'Donate!' button will disappear.",
                                                                                    price]
                                                                    preferredStyle:UIAlertControllerStyleAlert];

            [alert addAction:[self actionWithTitle:@"OK" style:UIAlertActionStyleDestructive
                                        buttonName:kButtonA
                                           keyName:kKeyReturn
                                           handler:^(UIAlertAction *action) {
                                               [self purchase:validProduct];
                                           }]];

            [alert addAction:[self actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                        buttonName:kButtonX
                                           keyName:UIKeyInputEscape
                                           handler:^(UIAlertAction *action) {
                                               [self displayDonated:self->_donated capable:[SKPaymentQueue canMakePayments] processing:NO];
                                           }]];


            [alert addAction:[self actionWithTitle:@"Restore Purchases" style:UIAlertActionStyleDefault
                                        buttonName:kButtonY
                                           keyName:kKeyR
                                           handler:^(UIAlertAction *action) {
                                               [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
                                               [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
                                           }]];

            [self presentViewController:alert animated:YES completion:nil];
        } else if (!validProduct) {
            // NSLog(@"No products available");
            //this is called if your product id is not valid, this shouldn't be called unless that happens.
            [self displayDonated:self->_donated capable:[SKPaymentQueue canMakePayments] processing:NO];
            DEBUG_LOG(@"Bad ids %@", response.invalidProductIdentifiers.debugDescription);
        }
    });

    // self.donateButton.titleLabel.text=@"Donate!";
    // self.donateButton.enabled = YES;
}

- (void)purchase:(SKProduct *)product {
    SKPayment *payment = [SKPayment paymentWithProduct:product];

    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

// Sent when an error is encountered while adding transactions from the user's purchase history back to the queue.
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        LOG_NSERROR(error);
        [self displayDonated:self->_donated capable:[SKPaymentQueue canMakePayments] processing:NO];

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Transaction error"
                                                                       message:error.localizedDescription
                                                                preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[self actionWithTitle:@"OK" style:UIAlertActionStyleDestructive
                                    buttonName:kButtonA
                                       keyName:kKeyReturn
                                       handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    dispatch_async(dispatch_get_main_queue(), ^{
        DEBUG_LOG(@"received restored transactions: %lu", (unsigned long)queue.transactions.count);

        bool restored = NO;

        for (SKPaymentTransaction *transaction in queue.transactions) {
            if (transaction.transactionState == SKPaymentTransactionStateRestored) {
                //called when the user successfully restores a purchase
                DEBUG_LOG(@"Transaction state -> Restored");
                restored = YES;
                [self donated];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            }
        }

        [self displayDonated:self->_donated capable:[SKPaymentQueue canMakePayments] processing:NO];

        if (!restored) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Donation"
                                                                           message:@"Sorry, could not find a donation to restore."
                                                                    preferredStyle:UIAlertControllerStyleAlert];

            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];


            [self presentViewController:alert animated:YES completion:nil];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Donation"
                                                                           message:@"Restored! Thanks."
                                                                    preferredStyle:UIAlertControllerStyleAlert];

            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];


            [self presentViewController:alert animated:YES completion:nil];
        }
    });
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (SKPaymentTransaction *transaction in transactions) {
            //if you have multiple in app purchases in your app,
            //you can get the product identifier of this transaction
            //by using transaction.payment.productIdentifier
            //
            //then, check the identifier against the product IDs
            //that you have defined to check which product the user
            //just purchased

            switch (transaction.transactionState) {
                case SKPaymentTransactionStatePurchasing:
                    DEBUG_LOG(@"Transaction state -> Purchasing");
                    //called when the user is in the process of purchasing, do not add any of your own code here.
                    break;

                case SKPaymentTransactionStateDeferred:
                    break;

                case SKPaymentTransactionStatePurchased:
                    //this is called when the user has successfully purchased the package (Cha-Ching!)
                    [self donated]; //you can add your code for what you want to happen when the user buys the purchase here, for this tutorial we use removing ads
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                    DEBUG_LOG(@"Transaction state -> Purchased");
                    [self displayDonated:self->_donated capable:[SKPaymentQueue canMakePayments] processing:NO];
                    break;

                case SKPaymentTransactionStateRestored:
                    DEBUG_LOG(@"Transaction state -> Restored");
                    //add the same code as you did from SKPaymentTransactionStatePurchased here
                    [self donated];
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                    [self displayDonated:self->_donated capable:[SKPaymentQueue canMakePayments] processing:NO];
                    break;

                case SKPaymentTransactionStateFailed:
                    //called when the transaction does not finish
                    DEBUG_LOGO(transaction);
                    LOG_NSERROR(transaction.error);

                    if (transaction.error.code == SKErrorPaymentCancelled) {
                        DEBUG_LOG(@"Transaction state -> Cancelled");
                        //the user cancelled the payment ;(
                    } else {
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Transaction error"
                                                                                       message:transaction.error.localizedDescription
                                                                                preferredStyle:UIAlertControllerStyleAlert];

                        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];


                        [self presentViewController:alert animated:YES completion:nil];
                    }

                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                    [self displayDonated:self->_donated capable:[SKPaymentQueue canMakePayments] processing:NO];
                    break;
            }
        }
    });
}

- (AugmentedSegmentControl *)speedSegment {
    return nil;
}

@end
