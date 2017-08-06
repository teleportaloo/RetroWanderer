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

#import "GameViewController.h"
#import "GameScene.h"
#import <AudioToolbox/AudioToolbox.h>
#import "ScreenSelector.h"
#import "GameCenterMgr.h"
#import "HelpScreen.h"
#import "DebugLogging.h"
#import "SettingsTableViewController.h"

#define kCurrentLevel       @"current_level"
//#define kAnimationDuration  @"animation_duration"
#define kAnimationDurationV (0.05)
//#define kRapidFireDuration  @"rapid_fire_duration"
#define kRapidFireDurationV (0.1)

#define kDonateProductIdentifier @"org.teleportaloo.RetroWanderer.donation1a"
#define kDonated                @"donated"

#define kGameCenter         @"game_center"
#define kSounds             @"sounds"
#define kStartPlaybackSpeed @"start_playback_speed"
#define kRetro              @"retro"
#define kLeftHanded         @"left_handed"
#define kShowHelp           @"show_help"
#define kAchievements       @"achievements2.plist"


#define kSavedMoves         @"moves%d.plist"
#define kSavedMovesKeys     @"keys"
#define kButtonA            @"(A)"
#define kButtonB            @"(B)"
#define kButtonX            @"(X)"
#define kButtonY            @"(Y)"
#define kButtonL1           @"(L1)"
#define kButtonR1           @"(R1)"
#define kButtonL            @"(←)"
#define kButtonR            @"(→)"
#define kButtonU            @"(↑)"
#define kButtonD            @"(↓)"
#define kButtonPause        @"⏸"
#define kControllerText     @"Controller Connected. Use:\n● D-pad to move,\n● button 'A' to skip.\n"

#define kMoveKeyUp          'k'
#define kMoveKeyDown        'j'
#define kMoveKeyLeft        'h'
#define kMoveKeyRight       'l'
#define kMoveKeySkip        ' '
#define kMoveQuit           'q'



#define kSegStep            0
#define kSegSlowMo          1
#define kSegSlow            2
#define kSegFast            3
@implementation GameViewController

@dynamic currentScreen;

-(void)initScreen
{
    int maxmoves = 0;
    _unsavedMoves = NO;
    [self controlButtonUp:nil];
    
    if (_num>self.highest)
    {
        _num = self.highest;
    }
    
    NSString *screenPath = [[NSBundle mainBundle] pathForResource:@"screen" ofType:@"1"];
    
    NSString *partialScreenPath = [screenPath substringToIndex:screenPath.length-1];
    
    self.buttonActionMap = [NSMutableDictionary dictionary];
    
    _screen_score = 0;
    
    
    if (rscreen(_num,&maxmoves, [partialScreenPath cStringUsingEncoding:NSUTF8StringEncoding]))
    {
        _game.howdead=(char *)"a non-existant screen";
    }
    else
    {
        initscreen(&_num, &_screen_score, &_bell, maxmoves, (char*)"kjhl", (game*)&_game);
        
        self.keyStrokes = [NSMutableString string];
        self.previousKeyStrokes = [self getSavedMoves];
        self.playbackPosition = 0;
        [self updateLevelButtons];
    }
}


- (long)calculateTotalScore
{
    __block long total = 0;
    [self.achievements enumerateKeysAndObjectsUsingBlock: ^void (NSString* key, NSDictionary* achievement, BOOL *stop)
     {
         NSNumber *score = achievement[kAchievementScore];
         if (score!=nil)
         {
             total += score.longValue;
         }
     }];
    
    return total;

}

- (void)saveLevel
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
    [[NSUserDefaults standardUserDefaults] setObject:@(_num)     forKey:kCurrentLevel];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self getSettings];
}

-(void)setButtonForController:(UIButton *)button title:(NSString *)title buttonName:(NSString *)buttonName buttonOnRight:(bool)buttonOnRight
{
    [self setButtonForController:button title:title buttonName:buttonName buttonOnRight:buttonOnRight controllerFont:nil regularFont:nil];
}

-(void)setButtonForController:(UIButton *)button title:(NSString *)title buttonName:(NSString *)buttonName buttonOnRight:(bool)buttonOnRight controllerFont:(UIFont *)controllerFont regularFont:(UIFont *)regularFont
{
    if (self.controller)
    {
        [button setTitle:buttonOnRight ? [NSString stringWithFormat:@"%@ %@", title, buttonName] : [NSString stringWithFormat:@"%@ %@", buttonName, title] forState:UIControlStateNormal];
        
        if (controllerFont)
        {
            button.titleLabel.font = controllerFont;
        }
        
        button.titleLabel.adjustsFontSizeToFitWidth = YES;
        __weak typeof(self) weakSelf = self;
        
        self.buttonActionMap[buttonName]=^{
            
            if (!button.hidden && button.enabled)
            {
                NSArray<NSString*> *actions = [button actionsForTarget:weakSelf forControlEvent:UIControlEventTouchUpInside];
            
                if (actions!=nil && actions.count>0)
                {
                    SEL sel = NSSelectorFromString(actions.firstObject);
                    IMP imp = [weakSelf methodForSelector:sel];
                    void (*func)(id, SEL, id) = (void (*)(id, SEL, id))imp;
                    func(weakSelf, sel, button);
                }
            }
        };
    }
    else
    {
        [button setTitle:title forState:UIControlStateNormal];
        
        if (regularFont)
        {
            button.titleLabel.font = regularFont;
        }
        button.titleLabel.adjustsFontSizeToFitWidth = NO;
    }
}

-(void)setButtonsForSeg:(UISegmentedControl*)control titles:(NSArray<NSString*> *)titles buttonNames:(NSArray<NSString*> *)buttonNames
{
    if (self.controller)
    {
        for (int i = 0; i<buttonNames.count; i++)
        {
            [control setTitle:[NSString stringWithFormat:@"%@ %@", buttonNames[i], titles[i]] forSegmentAtIndex:i];
        }
        
        // Assume first button is already sorted, and the other two are the same
        __weak typeof(self) weakSelf = self;
        
        self.buttonActionMap[buttonNames[0]] = nil;
        self.buttonActionMap[buttonNames[1]]=^{
            
            switch (control.selectedSegmentIndex)
            {
                
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
            
            NSArray<NSString*> *actions = [control actionsForTarget:weakSelf forControlEvent:UIControlEventValueChanged];
            
            if (actions!=nil && actions.count>0)
            {
                SEL sel = NSSelectorFromString(actions.firstObject);
                IMP imp = [weakSelf methodForSelector:sel];
                void (*func)(id, SEL, id) = (void (*)(id, SEL, id))imp;
                func(weakSelf, sel, control);
            }
        };
    }
    else
    {
        for (int i = 0; i<buttonNames.count; i++)
        {
            [control setTitle:titles[i] forSegmentAtIndex:i];
        }
    }
}

-(void)hideSegment
{
    self.playbackSpeedSeg.hidden = YES;
    self.buttonActionMap[kButtonU] = nil;
    self.buttonActionMap[kButtonL] = nil;
    self.buttonActionMap[kButtonR] = nil;
    [self getSettings];
}

- (NSDictionary*)achievementForScreen:(int)num
{
    return self.achievements[[NSString stringWithFormat:@"%d", num]];
}

- (void)updateLevelButtons
{
    
    self.previousButton.hidden = !(_num > 0);
    self.nextButton.hidden = !(_num < self.highest);
    
    [self setButtonForController:self.previousButton title:@"⇤" buttonName:kButtonL1 buttonOnRight:YES controllerFont:[UIFont systemFontOfSize:15] regularFont:[UIFont systemFontOfSize:26]];
    [self setButtonForController:self.nextButton     title:@"⇥" buttonName:kButtonR1 buttonOnRight:NO  controllerFont:[UIFont systemFontOfSize:15] regularFont:[UIFont systemFontOfSize:26]];
    
    NSDictionary *achievement = [self achievementForScreen:_num];
    
    if (achievement)
    {
        NSDate *firstDone = achievement[kAchievementDate];
        NSNumber *score   = achievement[kAchievementScore];
        
        if (firstDone)
        {
            self.achievementLabel.text = [NSString stringWithFormat:@"Completed on %@ with screen score: %ld",
                                          [NSDateFormatter localizedStringFromDate:firstDone
                                                                         dateStyle:NSDateFormatterShortStyle
                                                                         timeStyle:NSDateFormatterShortStyle],
                                          score!=nil ? score.longValue : 0
                                          ];
        }
    }
    else
    {
        self.achievementLabel.text = @"";
    }
    
    self.totalScoreLabel.text = [NSString stringWithFormat:@"Total score: %ld", _total_score];
    
    switch (self.playbackState)
    {
        case PlaybackStepping:
            self.playbackButton.hidden = NO;
            [self setButtonForController:self.playbackButton title:@"Stop playback" buttonName:kButtonPause buttonOnRight:YES];
            self.buttonActionMap[kButtonY] = nil;
            
            [self setButtonsForSeg:self.playbackSpeedSeg titles:@[@"Step", @"Slow Mo", @"Normal", @"Fast"] buttonNames:@[kButtonA, kButtonX, kButtonX, kButtonX]];
            self.playbackSpeedSeg.hidden = NO;
            self.saveCheckpointButton.hidden = YES;
            self.playbackMoves.hidden = NO;
            if (self.controllerConnected)
            {
                self.controllerLabel.text = @"Controller Connected. Use D-pad or Button 'A' to playback next move.";
                self.controllerLabel.hidden = NO;
            }
            else
            {
                self.controllerLabel.hidden = YES;
            }
            break;
        case PlaybackOverrun:
        case PlaybackRecording:
            if (self.previousKeyStrokes)
            {
                [self setButtonForController:self.playbackButton title:@"Start playback" buttonName:kButtonY buttonOnRight:YES];
                self.playbackButton.hidden = NO;
                self.buttonActionMap[kButtonPause] = nil;
            }
            else
            {
                self.playbackButton.hidden = YES;
            }
            [self hideSegment];
            self.saveCheckpointButton.hidden = !_unsavedMoves;
            [self setButtonForController:self.saveCheckpointButton title:@"Save checkpoint" buttonName:kButtonX buttonOnRight:YES];
            self.playbackMoves.hidden = YES;
            if (self.controllerConnected)
            {
                self.controllerLabel.text = kControllerText;
                self.controllerLabel.hidden = NO;
            }
            else
            {
                self.controllerLabel.hidden = YES;
            }

            break;
        case PlaybackDone:
            self.playbackButton.hidden = YES;
            [self hideSegment];
            self.saveCheckpointButton.hidden = !_unsavedMoves;
            [self setButtonForController:self.saveCheckpointButton title:@"Save checkpoint" buttonName:kButtonX buttonOnRight:YES];
            self.playbackMoves.hidden = YES;
            break;
    }
    
    [self setButtonForController:self.startOverButton title:@"Start over" buttonName:kButtonB buttonOnRight:YES];
    
    self.startOverButton.hidden = !((self.keyStrokes.length!=0) || self.playbackState==PlaybackDone);
    
    if (!self.controllerConnected)
    {
        self.controllerLabel.hidden = YES;
        
        if (self.playbackState!=PlaybackStepping && self.playbackState!=PlaybackDone)
        {
            
            self.upButton.hidden = NO;
            self.downButton.hidden = NO;
            self.leftButton.hidden = NO;
            self.rightButton.hidden = NO;
            self.stayButton.hidden = NO;
            self.stepButton.hidden = YES;
            
            
        }
        else if (self.playbackSpeedSeg.selectedSegmentIndex != kSegStep)
        {
            self.upButton.hidden = YES;
            self.downButton.hidden = YES;
            self.leftButton.hidden = YES;
            self.rightButton.hidden = YES;
            self.stayButton.hidden = YES;
            self.stepButton.hidden = YES;
            
        }
        else
        {
            self.upButton.hidden = YES;
            self.downButton.hidden = YES;
            self.leftButton.hidden = YES;
            self.rightButton.hidden = YES;
            self.stayButton.hidden = YES;
            self.stepButton.hidden = NO;
        }
    }
    else
    {
        self.controllerLabel.hidden = NO;
        
        self.upButton.hidden    = YES;
        self.downButton.hidden  = YES;
        self.leftButton.hidden  = YES;
        self.rightButton.hidden = YES;
        self.stayButton.hidden  = YES;
        
    }
}

- (int)nextUndoneScreen
{
    int next = _num+1;
    
    while (next < self.highest && [self achievementForScreen:next]!=nil)
    {
        next++;
    }
    
    if ([self achievementForScreen:next]!=nil)
    {
        next = -1;
    }
    
    return next;
}

- (void)nextScreen
{
    if (_num < self.highest)
    {
        _num++;
        [self saveLevel];
        [self playbackRecording];
        [self initScreen];
        
    }
}

- (void)changeToScreen:(int)screen review:(bool)review
{
    if (_unsavedMoves && self.playbackState!=PlaybackDone)
    {
        NSString *title = nil;
        switch(screen-_num)
        {
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
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:@"You will lose all unsaved progress on this screen."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[self actionWithTitle:@"OK" style:UIAlertActionStyleDestructive
                                    buttonName:kButtonA
                                       handler:^(UIAlertAction * action) {
                                           [self stopPlayback:^{
                                               _num = screen;
                                               [self saveLevel];
                                               [self initScreen];
                                               
                                               if (review)
                                               {
                                                   [self requestReview];
                                               }
                                           }];
                                       }]];
        
        [alert addAction:[self actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                    buttonName:kButtonX
                                       handler:^(UIAlertAction * action) {
                                           if (review)
                                           {
                                               [self requestReview];
                                           }
                                       }]];
        
        [self presentViewController:alert animated:YES completion:nil];
        
    }
    else
    {
        _num = screen;
        [self saveLevel];
        [self scheduleNextAction:NextActionInitScreen move:0];
        
        if (review)
        {
            [self requestReview];
        }
    }
}

- (UIAlertAction *)actionWithTitle:(NSString *)title
                             style:(UIAlertActionStyle)style
                        buttonName:(NSString *)buttonName
                           handler:(AlertBlock)handler
{
    if (self.controller)
    {
        __block GameViewController*weakSelf = self;
        
        AlertBlock metaHandler = ^(UIAlertAction * action) {
            
            void (^completionBlock)(void) = ^{
                
                [weakSelf.alertActionMap removeAllObjects];
                
                if (handler)
                {
                    handler(action);
                }
            };
            
            if (weakSelf.presentedViewController)
            {
                [weakSelf dismissViewControllerAnimated:YES completion:completionBlock];
            }
            else
            {
                completionBlock();
            }
        };

    
        self.alertActionMap[buttonName] = metaHandler;
    
        return [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@ %@", buttonName, title] style:style handler: metaHandler];
    }
    return [UIAlertAction actionWithTitle:title style:style handler: handler];
}

-(void)requestReview
{
    Class reviewController  = (NSClassFromString(@"SKStoreReviewController"));
    
    if (reviewController !=nil)
    {
        [SKStoreReviewController requestReview];
    }
}

-(void)makeMove:(char)key
{
    
    if (self.presentedViewController==nil)
    {
        __block bool checkpointDone = NO;
        
        if (self.playbackState == PlaybackRecording)
        {
            if (self.keyStrokes)
            {
                if (self.keyStrokes.length < 10000)
                {
                    [self.keyStrokes appendFormat:@"%c", key];
                }
                else
                {
                    self.playbackState = PlaybackOverrun;
                }
            }
        }
        
        if (self.playbackState == PlaybackStepping && self.previousKeyStrokes!=nil)
        {
            if (self.playbackPosition < self.previousKeyStrokes.length && key!=kMoveQuit)
            {
                key = (char)[self.previousKeyStrokes characterAtIndex:self.playbackPosition];
                self.playbackMoves.text = [NSString stringWithFormat:@"Playback moves: %d",(int)(self.previousKeyStrokes.length - self.playbackPosition)];
                self.playbackPosition++;
            }
            else
            {
                checkpointDone = YES;
            }
        }
        
        if (self.playbackState != PlaybackDone && !checkpointDone)
        {
            char *howDead = onemove(&_num, &_screen_score, &_bell, (char*)"kjhl", (game*)&_game, key);
            
            __weak typeof(self) weakSelf = self;
            
            [self.display runSequenceWithCompletion:^{
                NSString *dead = nil;
                
                if (howDead)
                {
                    dead = [NSString stringWithUTF8String:howDead];
                }
                
                if (dead !=nil && self.playbackState!=PlaybackStepping)
                {
                    if (_game.quit)
                    {
                        [weakSelf playbackRecording];
                        [weakSelf initScreen];
                    }
                    else
                    {
                        [self.display deadPlayer];
                        [self.display ad_sound:'!'];
                        
                        
                        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"You are dead."
                                                                                       message:[NSString stringWithFormat:@"You were killed by %@", dead]
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        
                        UIAlertAction* defaultAction = [self actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  buttonName:kButtonA
                                                                     handler:^(UIAlertAction * action) {
                                                                         [weakSelf playbackRecording];
                                                                         [weakSelf initScreen];
                                                                     }
                                                        ];
                        
                        [alert addAction:defaultAction];
                        [self presentViewController:alert animated:YES completion:nil];
                    }
                }
                else if (_game.finished)
                {
                    NSString *key = [NSString stringWithFormat:@"%d", _num];
                    bool better = NO;
                    bool increased = NO;
                    checkpointDone = NO;
                    [self.display happyPlayer];
                    
                    if (self.achievements[key]==nil)
                    {
                        self.achievements[key] = @{
                                                   kAchievementDate : [NSDate date],
                                                   kAchievementScore : @(_screen_score) };
                        
                        [weakSelf saveAchievements];
                        [weakSelf writeSavedMoves];
                        increased = YES;
                    }
                    else if (self.keyStrokes.length > 0)
                    {
                        NSNumber *previousScore = weakSelf.achievements[key][kAchievementScore];
                        
                        if (_screen_score > previousScore.longValue
                            || (_screen_score == previousScore.longLongValue && self.keyStrokes.length < self.previousKeyStrokes.length ))
                        {
                            weakSelf.achievements[key] = @{
                                                           kAchievementDate : [NSDate date],
                                                           kAchievementScore : @(_screen_score) };
                            
                            [weakSelf saveAchievements];
                            [weakSelf writeSavedMoves];
                            better = YES;
                        }
                    }
                    
                    DEBUG_LOGO(self.achievements);
                    
                    _total_score = [self calculateTotalScore];
                    
                    if (_gameCenter && _total_score > 0)
                    {
                        [[GameCenterMgr sharedManager] reportScore:_total_score];
                        [[GameCenterMgr sharedManager] reportAchievements:self.achievements];
                    }
                    
                    if (self.playbackState != PlaybackStepping)
                    {
                        NSString *message = nil;
                        
                        if (better)
                        {
                            message = [NSString stringWithFormat:@"Screen %d completed, better than last time. The total score is now %ld!", _num, _total_score];
                        }
                        else if (increased)
                        {
                            message = [NSString stringWithFormat:@"Screen %d completed. The total score is now %ld!", _num, _total_score];
                        }
                        else
                        {
                            message = [NSString stringWithFormat:@"Screen %d completed, but the total score is unchanged.", _num];
                        }
                        
                        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"You did it!"
                                                                                       message:message
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        
                        UIAlertAction* action = nil;
                        
                        action = [weakSelf actionWithTitle:@"Playback moves" style:UIAlertActionStyleDefault
                                                buttonName:kButtonY
                                                   handler:^(UIAlertAction * action) {
                                                       [self startPlayback];
                                                   }
                                  ];
                                  
                                  
                        [alert addAction:action];
                        
                        int next = [self nextUndoneScreen];

                        
                        if (next > 0)
                        {
                            action = [weakSelf actionWithTitle:@"Next Uncompleted Screen" style:UIAlertActionStyleDestructive
                                                    buttonName:kButtonA
                                                       handler:^(UIAlertAction * action) {
                                                           _unsavedMoves = NO;
                                                           [self changeToScreen:next review:YES];
                                                       }
                                      ];
                        } else {
                            action = [weakSelf actionWithTitle:@"OK" style:UIAlertActionStyleDestructive
                                                    buttonName:kButtonA
                                                       handler:^(UIAlertAction * action) {
                                                           [self requestReview];
                                                       }
                                      
                                      ];
                        }
                        
                        
                        [alert addAction:action];
                        
                        [self presentViewController:alert animated:YES completion:nil];
                    }
                    else
                    {
                        _unsavedMoves = NO;
                        weakSelf.playbackState = PlaybackDone;
                        [weakSelf controlButtonUp:nil];
                        [self getSettings];
                        [weakSelf updateLevelButtons];
                    }
                }
                else
                {
                    if (!_unsavedMoves)
                    {
                        _unsavedMoves = YES;
                        [weakSelf updateLevelButtons];
                    }
                }
                
                if (checkpointDone)
                {
                    _unsavedMoves = NO;
                    weakSelf.keyStrokes = [self.previousKeyStrokes mutableCopy];
                    [weakSelf controlButtonUp:nil];
                    [weakSelf playbackRecording];
                    [weakSelf updateLevelButtons];
                }
            }];
            
            
#ifdef DEBUGLOGGING
            self.busyLabel.text = [NSString stringWithFormat:@"%d %lu %lu", self.display.animationCount, (unsigned long)self.display.fastMoveCache.count, (unsigned long)self.display.cacheHits];
#endif
        }
        
        if (checkpointDone)
        {
            _unsavedMoves = NO;
            self.keyStrokes = [self.previousKeyStrokes mutableCopy];
            [self controlButtonUp:nil];
            [self playbackRecording];
            [self updateLevelButtons];
        }
    }
}



-(NSString*)getSavedMoves
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths.firstObject;
    NSString *fullPathName = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:kSavedMoves, _num]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPathName])
    {
        NSDictionary *savedMoves = [NSDictionary dictionaryWithContentsOfFile:fullPathName];
        
        NSString *raw = savedMoves[kSavedMovesKeys];
        
        NSMutableString *expanded = [NSMutableString string];
        
        int repeat = 0;
        unichar ch  = 0;
        
        for (int i=0; i<raw.length; i++)
        {
            ch = [raw characterAtIndex:i];
            
            if (ch>='0' && ch <='9')
            {
                repeat = repeat * 10 + (ch-'0');
            }
            else
            {
                if (repeat == 0)
                {
                    [expanded appendString:[NSString stringWithCharacters:&ch length:1]];
                }
                else
                {
                    for (int j=0; j<repeat; j++)
                    {
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

+ (void)write:(NSMutableString *)compressed ch:(unichar)ch repeat:(int)repeat
{
    if (repeat == 1)
    {
        [compressed appendString:[NSString stringWithCharacters:&ch length:1]];
    }
    else if (repeat == 2)
    {
        [compressed appendFormat:@"%c%c", ch, ch];
    }
    else
    {
        [compressed appendFormat:@"%d%c", repeat, ch];
    }
}

-(void)writeSavedMoves
{
    if (self.keyStrokes && self.keyStrokes.length > 0)
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = paths.firstObject;
        NSString *fullPathName = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:kSavedMoves, _num]];
    
        NSMutableString *compressed = [NSMutableString string];
        
        int repeat = 0;
        unichar ch  = 0;
        unichar lastch = [self.keyStrokes characterAtIndex:0];
        
        for (int i=0; i<self.keyStrokes.length; i++)
        {
            ch = [self.keyStrokes characterAtIndex:i];
            
            if (ch==lastch)
            {
                repeat++;
            }
            else
            {
                [GameViewController write:compressed ch:lastch repeat:repeat];
                repeat=1;
            }
            lastch = ch;
        }
        
        [GameViewController write:compressed ch:ch repeat:repeat];
        
        //NSLog(@"original   %@", self.keyStrokes);
        // NSLog(@"compressed %@", compressed);
        
        NSDictionary *savedMoves = @{kSavedMovesKeys:compressed};
        
        
        [savedMoves writeToFile:fullPathName atomically:YES];
        
        self.previousKeyStrokes = [self.keyStrokes copy];
    }
}

- (void)getAchievements
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths.firstObject;
    NSString *fullPathName = [documentsDirectory stringByAppendingPathComponent:kAchievements];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:fullPathName])
    {
        self.achievements = [NSMutableDictionary dictionary];
        
        [self.achievements writeToFile:fullPathName atomically:YES];
    }
    else
    {
        self.achievements = [NSMutableDictionary dictionaryWithContentsOfFile:fullPathName];
    }
}

- (void)saveAchievements
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths.firstObject;
    NSString *fullPathName = [documentsDirectory stringByAppendingPathComponent:kAchievements];
    if (![self.achievements writeToFile:fullPathName atomically:YES])
    {
        ERROR_LOG(@"not saved\n");
    }
}

-(void)handleChangeInUserSettings:(id)obj
{
    [self getSettings];
}

- (bool)showHelpOnce
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    bool showHelp = NO;
    
    if ([defaults boolForKey:kShowHelp])
    {
        showHelp = YES;
        [defaults setBool:NO forKey:kShowHelp];
    }
    
    return showHelp;
}

- (void)getSettings
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults synchronize];
    
    _donated = [defaults boolForKey:kDonated];
    
    if (self.playbackState != PlaybackStepping)
    {
        self.display.animationDuration = kAnimationDurationV;
        self.rapidFireDuration = kRapidFireDurationV;
        self.display.playerDuration = self.rapidFireDuration;
    }
    
    _startPlaybackSpeed = (int)[defaults integerForKey:kStartPlaybackSpeed];
    self.display.sounds = [defaults boolForKey:kSounds];
    
    DEBUG_LOGF(self.display.animationDuration);
    DEBUG_LOGF(self.rapidFireDuration);

    // NSLog(@"duration %f\n", self.display.animationDuration);
    
    _num = (int)[defaults integerForKey:kCurrentLevel];
    
    bool oldGameCenter = _gameCenter;
    _gameCenter = [defaults boolForKey:kGameCenter];
    
    if (!_gameCenter)
    {
        [GameCenterMgr noGameCenter];
    }
    else if (!oldGameCenter)
    {
        [[GameCenterMgr sharedManager] authenticatePlayer:^{
                [[GameCenterMgr sharedManager] reportScore:_total_score];
                [[GameCenterMgr sharedManager] reportAchievements:self.achievements];
        }];
    }
    
    bool oldRetro = [WandererTile retro];

    [WandererTile setRetro: [defaults  boolForKey:kRetro]];
    
    if (oldRetro != [WandererTile retro])
    {
        [self.display ad_init_completed];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleChangeInUserSettings:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kLeftHanded] && self.view)
    {
        CGRect frame = self.controlClusterView.frame;
        
        self.controlClusterView.frame = CGRectMake(0,
                                                   frame.origin.y, frame.size.width, frame.size.height);
        
        frame = self.screenClusterView.frame;
        
        self.screenClusterView.frame = CGRectMake(self.view.frame.size.width-frame.size.width,
                                                  frame.origin.y, frame.size.width, frame.size.height);
    }
    else
    {
        CGRect frame = self.controlClusterView.frame;
        
        self.controlClusterView.frame = CGRectMake(self.view.frame.size.width-frame.size.width,
                                                   frame.origin.y, frame.size.width, frame.size.height);
        
        frame = self.screenClusterView.frame;
        
        self.screenClusterView.frame = CGRectMake(0,
                                                  frame.origin.y, frame.size.width, frame.size.height);

    }
    
    self.highScoresButton.hidden = !_gameCenter;
    self.achievementsButton.hidden = !_gameCenter;
    self.donateButton.hidden = _donated || ![SKPaymentQueue canMakePayments];
    
    if (_donated)
    {
        self.thanksLabel.text = @"❤️😀";
    }
    self.thanksLabel.hidden  = !_donated;

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self toggleHardwareController:YES];
    
    
    // For testing donations
#ifdef DEBUGLOGGING
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDonated];
    DEBUG_LOG(@"Remvoed donation!");
#endif
    
    [self getAchievements];
    
    self.alertActionMap = [NSMutableDictionary dictionary];
    
    // Load the SKScene from 'GameScene.sks'
    GameScene *scene = (GameScene *)[SKScene nodeWithFileNamed:@"GameScene"];
    
    
    
    // Set the scale mode to scale to fit the window
    scene.scaleMode = SKSceneScaleModeAspectFit;
    scene.controller = self;
    
    SKView *skView = (SKView *)self.view;
    skView.allowsTransparency = YES;
    scene.backgroundColor = [UIColor clearColor];
    
    // Present the scene
    [skView presentScene:scene];
    
    DEBUG_ONLY(
               skView.showsFPS = YES;
               skView.showsNodeCount = YES;
               skView.showsDrawCount = YES;
               skView.showsQuadCount = YES;
    )
    
    NSURL *defaultPrefsFile = [[NSBundle mainBundle]
                               URLForResource:@"DefaultPreferences" withExtension:@"plist"];
    NSDictionary *defaultPrefs = [NSDictionary dictionaryWithContentsOfURL:defaultPrefsFile];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultPrefs];

    
    
    [self updateLevelButtons];
    
    self.display = [[SpriteDisplay alloc] init];
    
    [self getSettings];
 
    self.display.boardLayer  = scene.boardLayer;
    
    self.display.scoreLabel = self.scoreLabel;
    self.display.diamondsLabel = self.diamondsLabel;
    self.display.maxMovesLabel = self.maxMovesLabel;
    self.display.monsterLabel = self.monsterLabel;
    self.display.nameLabel = self.nameLabel;
    self.display.view = self.view;
    self.display.delegate = self;
    
    
    memset(&_game, sizeof(_game), 0);
    
    
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [[self view] addGestureRecognizer:recognizer];
    
    [self scheduleNextAction:NextActionInitScreen move:0];
    
    _total_score = [self calculateTotalScore];
    
   
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([self showHelpOnce])
    {
        [self showHelp:nil];
    }
}

- (void)scheduleNextAction:(NextAction)action move:(char)move
{
    @synchronized(self) {
        self.nextMove   = move;
        self.nextAction = action;
    }
}

- (void)processNextAction
{
    if (!_busy)
    {
        @synchronized(self) {
            switch (self.nextAction)
            {
                case NextActionInitScreen:
                    [self playbackRecording];
                    [self initScreen];
                    [self saveLevel];
                    self.nextAction = NextActionDoNothing;
                    break;
                case NextActionMove:
                    // DEBUG_LOG(@"NextActionMove");
                    [self makeMove:self.nextMove];
                    self.nextAction = NextActionDoNothing;
                    self.nextMove = 0;
                    break;
                case NextActionDoNothing:
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

- (void)scheduleMove:(char)move
{
    if (self.nextAction == NextActionDoNothing)
    {
        [self scheduleNextAction:NextActionMove move:move];
    }
}



- (IBAction)saveCheckpoint:(id)sender {
    if (self.previousKeyStrokes)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Checkpoint"
                                                                       message:@"Replace the checkpoint for this screen?"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[self actionWithTitle:@"OK" style:UIAlertActionStyleDestructive
                                    buttonName:kButtonA
                                       handler:^(UIAlertAction * action) {
                                           [self writeSavedMoves];
                                           _unsavedMoves = NO;
                                           [self updateLevelButtons];
                                       }]];
        
        [alert addAction:[self actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                    buttonName:kButtonX
                                       handler:^(UIAlertAction * action) {
                                           [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
                                           [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
                                       }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        [self writeSavedMoves];
        [self updateLevelButtons];

    }
}

- (void)startPlayback
{
    self.playbackState = PlaybackStepping;
    self.playbackSpeedSeg.selectedSegmentIndex = _startPlaybackSpeed;
    [self initScreen];
    [self playbackSpeedChanged:nil];
    self.playbackMoves.text = [NSString stringWithFormat:@"Playback moves: %d",(int)(self.previousKeyStrokes.length - self.playbackPosition)];
    [self.display sunglassesPlayer];
}

- (void)stopPlayback:(dispatch_block_t)block
{
    if (self.playbackState != PlaybackRecording)
    {
        [self controlButtonUp:nil];
        self.playbackState = PlaybackRecording;
        __weak typeof(self) weakSelf = self;
        [self.display cancelSequenceWithCompletion:^{
            weakSelf.keyStrokes = [[weakSelf.previousKeyStrokes substringToIndex:weakSelf.playbackPosition] mutableCopy];
            [weakSelf playbackRecording];
            [weakSelf updateLevelButtons];
        
            if (block)
            {
                block();
            }
        }];
    } else if (block)
    {
        block();
    }

}

- (IBAction)playbackPressed:(id)sender {
    switch (self.playbackState)
    {
        case PlaybackStepping:
            // Copy where we are now into the recording buffer
            [self stopPlayback:nil];
            break;
        case PlaybackOverrun:
        case PlaybackRecording:
            if (self.previousKeyStrokes!=nil)
            {
                if (!_unsavedMoves && self.playbackState!=PlaybackDone)
                {
                    
                    [self startPlayback];
                    
                }
                else
                {
                    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Playback to last checkpoint"
                                                                                   message:@"You will lose any unsaved progress on this screen."
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    
                    [alert addAction:[self actionWithTitle:@"OK" style:UIAlertActionStyleDestructive
                                                buttonName:kButtonA
                                                   handler:^(UIAlertAction * action) {
                                                       [self.display cancelSequenceWithCompletion:^{
                                                           [self startPlayback];
                                                       }];
                                                   }]];
                    
                    [alert addAction:[self actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                buttonName:kButtonX
                                                   handler:nil]];
                    
                    [self presentViewController:alert animated:YES completion:nil];
                    
                }
            }
            break;
        case PlaybackDone:
            break;
    }

}

- (void)fire
{
    [self scheduleMove:self.rapidFireDirection];
    
    if (_initialRapidFire)
    {
        [self.rapidFireTimer invalidate];
        self.rapidFireTimer = [NSTimer scheduledTimerWithTimeInterval:self.rapidFireDuration  target:self selector:@selector(rapidFire:) userInfo:nil repeats:YES];
        _initialRapidFire = NO;
    }
}

- (void)rapidFire:(id)arg
{
    if (self.rapidFireControllerButton)
    {
        if (self.controllerConnected && self.rapidFireControllerButton.pressed && self.rapidFireDirection)
        {
            [self fire];
        }
        else
        {
            [self controlButtonUp:nil];
        }
    }
    else
    {
        [self fire];
    }
}

- (void)scheduleRapidFire:(GCControllerButtonInput *)controllerButton direction:(char)rapidFireDirection
{
    self.rapidFireDirection = rapidFireDirection;
    self.rapidFireControllerButton = controllerButton;
    
    if (self.rapidFireTimer!=nil)
    {
        [self.rapidFireTimer invalidate];
    }
    _initialRapidFire = YES;
    
    // initial timer is for a little longer
    self.rapidFireTimer = [NSTimer scheduledTimerWithTimeInterval:self.rapidFireDuration * 1.5 target:self selector:@selector(rapidFire:) userInfo:nil repeats:NO];
}

- (IBAction)controlButtonUp:(id)sender {
    
    self.rapidFireControllerButton = nil;
    [self.rapidFireTimer invalidate];
    self.rapidFireTimer = nil;
    self.rapidFireDirection = 0;
}

- (IBAction)up:(id)sender {
    [self scheduleMove:kMoveKeyUp];
    [self scheduleRapidFire:nil direction:kMoveKeyUp];
}

- (IBAction)left:(id)sender {
    [self scheduleMove:kMoveKeyLeft];
    [self scheduleRapidFire:nil direction:kMoveKeyLeft];
}

- (IBAction)right:(id)sender {
    [self scheduleMove:kMoveKeyRight];
    [self scheduleRapidFire:nil direction:kMoveKeyRight];
}

- (IBAction)down:(id)sender {
    [self scheduleMove:kMoveKeyDown];
    [self scheduleRapidFire:nil direction:kMoveKeyDown];
}

- (IBAction)stay:(id)sender {
    [self scheduleMove:kMoveKeySkip];
    [self scheduleRapidFire:nil direction:kMoveKeySkip];
}

- (IBAction)startOver:(id)sender {
    
    
    
    if (_unsavedMoves && self.playbackState!=PlaybackDone)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Start this screen over"
                                                                       message:@"You will lose any unsaved progress for this screen."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[self actionWithTitle:@"OK" style:UIAlertActionStyleDestructive
                                    buttonName:kButtonA
                                       handler:^(UIAlertAction * action) {
                                           [self stopPlayback:^{
                                               [self makeMove:kMoveQuit];
                                           }];
                                       }]];
        
        [alert addAction:[self actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                    buttonName:kButtonX
                                       handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
        
    }
    else if (self.playbackState==PlaybackDone)
    {
        if (self.previousKeyStrokes!=nil)
        {
            [self playbackRecording];
            [self initScreen];
        }
    }
    else
    {
         [self scheduleMove:kMoveQuit];
    }
}

- (IBAction)next:(id)sender {
    if (_num < self.highest)
    {
        [self changeToScreen:_num+1 review:NO];
    }
}

- (void)playbackRecording
{
    self.playbackState = PlaybackRecording;
    [self.display normalPlayer];
}

- (IBAction)previous:(id)sender {
    
    if (_num >0)
    {
        [self changeToScreen:_num-1 review:NO];
    }
}

#define BUTTON_BOUNCE -0.3

-(NSDate *)keyStroke:(char)ch last:(NSDate *)date value:(float)value pressed:(bool)pressed button:(GCControllerButtonInput*)button
{
    //    NSLog(@"%c %f %f %d\n",ch, [date timeIntervalSinceNow], value, pressed);
    
    if ((pressed && (date==nil || [date timeIntervalSinceNow] < BUTTON_BOUNCE)) && self.view.userInteractionEnabled && self.presentedViewController==nil)
    {
        [self scheduleMove:ch];
        
        if (button)
        {
            [self scheduleRapidFire:button direction:ch];
        }
        
        return [NSDate date];
    }
    
    return date;
    
}


- (void)clearController
{
    if (self.controller)
    {
        [self.controller.extendedGamepad.dpad.up  setValueChangedHandler:nil];
        [self.controller.extendedGamepad.dpad.down setValueChangedHandler:nil];
        [self.controller.extendedGamepad.dpad.left setValueChangedHandler:nil];
        [self.controller.extendedGamepad.dpad.right setValueChangedHandler:nil];
        [self.controller setControllerPausedHandler:nil];
        [self.controller.extendedGamepad.rightShoulder setValueChangedHandler:nil];
        [self.controller.extendedGamepad.leftShoulder setValueChangedHandler:nil];
        [self.controller.extendedGamepad.buttonA setValueChangedHandler:nil];
        [self.controller.extendedGamepad.buttonB setValueChangedHandler:nil];
        [self.controller.extendedGamepad.buttonX setValueChangedHandler:nil];
        [self.controller.extendedGamepad.buttonY setValueChangedHandler:nil];

        self.controller = nil;
    }
}


#define BUTTON_LOG(X) DEBUG_LOG(@"Button: %@ pressed %d value %f delta %f blocked %d\n", X, pressed, value, [depressedDate timeIntervalSinceNow], [depressedDate timeIntervalSinceNow] >= BUTTON_BOUNCE )
-(bool)setupControler
{
    NSArray *controllers = [GCController controllers];
    
    if (controllers != nil && controllers.count > 0)
    {
        
        self.controller = controllers[0];

        if (self.controller.extendedGamepad) {
            
            self.controllerConnected = YES;
            
            __weak typeof(self) weakSelf = self;
            __block NSDate *depressedDate = [NSDate date];
            
            [self.controller.extendedGamepad.dpad.up  setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                BUTTON_LOG(kButtonU);
                if (weakSelf.buttonActionMap[kButtonU])
                {
                    if (pressed &&  [depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE)
                    {
                        (weakSelf.buttonActionMap[kButtonU])();
                        depressedDate = [NSDate date];
                    }
                    
                }
                else if (self.playbackState==PlaybackRecording)
                {
                    depressedDate = [weakSelf keyStroke:kMoveKeyUp last:depressedDate value:value pressed:pressed button:button];
                }
            }];
            
            [self.controller.extendedGamepad.dpad.down setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                BUTTON_LOG(kButtonD);
                if (self.playbackState==PlaybackRecording)
                {
                    depressedDate = [weakSelf keyStroke:kMoveKeyDown last:depressedDate value:value pressed:pressed button:button];
                }
            }];
            
            
            [self.controller.extendedGamepad.dpad.left setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                BUTTON_LOG(kButtonL);
                if (weakSelf.buttonActionMap[kButtonL])
                {
                    if (pressed &&  [depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE)
                    {
                        (weakSelf.buttonActionMap[kButtonL])();
                        depressedDate = [NSDate date];
                    }
                }
                else if (self.playbackState==PlaybackRecording)
                {
                    depressedDate = [weakSelf keyStroke:kMoveKeyLeft last:depressedDate value:value pressed:pressed button:button];
                }
            }];
            
            [self.controller.extendedGamepad.dpad.right setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                BUTTON_LOG(kButtonR);
                if (weakSelf.buttonActionMap[kButtonR])
                {
                    if (pressed &&  [depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE)
                    {
                        (weakSelf.buttonActionMap[kButtonR])();
                        depressedDate = [NSDate date];
                    }
                }
                else if (self.playbackState==PlaybackRecording)
                {
                    depressedDate = [weakSelf keyStroke:kMoveKeyRight last:depressedDate value:value pressed:pressed button:button];
                }
            }];
            
            
            [self.controller setControllerPausedHandler: ^(GCController *controller)
             {
#ifdef DEBUGLOGGING
                 bool pressed = YES;
                 float value = 0.0;
#endif
                 BUTTON_LOG(kButtonPause);
                 if ([depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE)
                 {
                     depressedDate = [NSDate date];
                     if (weakSelf.presentedViewController==nil)
                     {
                         if (weakSelf.buttonActionMap[kButtonPause])
                         {
                             (weakSelf.buttonActionMap[kButtonPause])();
                         }
                     }
                 }
             }];
            
            [self.controller.extendedGamepad.rightShoulder setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                BUTTON_LOG(kButtonR1);
                if (pressed &&  [depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE)
                {
                    if (weakSelf.presentedViewController==nil)
                    {
                        if (weakSelf.buttonActionMap[kButtonR1])
                        {
                            (weakSelf.buttonActionMap[kButtonR1])();
                        }
                    }
                    depressedDate = [NSDate date];
                }
            }];
            
            [self.controller.extendedGamepad.leftShoulder setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                BUTTON_LOG(kButtonL1);
                if (pressed && [depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE)
                {
                    if (weakSelf.presentedViewController==nil)
                    {
                        if (weakSelf.buttonActionMap[kButtonL1])
                        {
                            (weakSelf.buttonActionMap[kButtonL1])();
                        }
                    }
                    depressedDate = [NSDate date];
                }
            }];
            
            [self.controller.extendedGamepad.buttonA setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                BUTTON_LOG(kButtonA);
                if (weakSelf.presentedViewController)
                {
                    if (pressed && [depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE)
                    {
                        if (weakSelf.alertActionMap[kButtonA])
                        {
                            (weakSelf.alertActionMap[kButtonA])(nil);
                        }
                        depressedDate = [NSDate date];
                    }
                }
                else if (self.playbackState != PlaybackStepping || self.playbackSpeedSeg.selectedSegmentIndex == kSegStep)
                {
                    depressedDate = [weakSelf keyStroke:kMoveKeySkip last:depressedDate value:value pressed:pressed button:button];
                }
                else if (self.playbackState == PlaybackStepping && self.playbackSpeedSeg.selectedSegmentIndex != kSegStep)
                {
                    self.playbackSpeedSeg.selectedSegmentIndex = kSegStep;
                    [self playbackSpeedChanged:nil];
                }
            }];
            
            [self.controller.extendedGamepad.buttonB setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                BUTTON_LOG(kButtonB);
                if (pressed && [depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE)
                {
                    if (weakSelf.presentedViewController)
                    {
                        if (weakSelf.alertActionMap[kButtonB])
                        {
                            (weakSelf.alertActionMap[kButtonB])(nil);
                        }
                    }
                    else
                    {
                        if (weakSelf.buttonActionMap[kButtonB])
                        {
                            (weakSelf.buttonActionMap[kButtonB])();
                        }
                    }
                    depressedDate = [NSDate date];
                }
                
            }];
            
            [self.controller.extendedGamepad.buttonX setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                BUTTON_LOG(kButtonX);
                if (pressed && [depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE)
                {
                    if (weakSelf.presentedViewController)
                    {
                        
                        if (weakSelf.alertActionMap[kButtonX])
                        {
                            (weakSelf.alertActionMap[kButtonX])(nil);
                        }
                        
                        
                    }
                    else
                    {
                        if (weakSelf.buttonActionMap[kButtonX])
                        {
                            (weakSelf.buttonActionMap[kButtonX])();
                        }
                    }
                    depressedDate = [NSDate date];
                }
                
            }];
            
            [self.controller.extendedGamepad.buttonY setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                BUTTON_LOG(kButtonY);
                if (pressed && [depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE)
                {
                    if (weakSelf.presentedViewController)
                    {
                        
                        if (weakSelf.alertActionMap[kButtonY])
                        {
                            (weakSelf.alertActionMap[kButtonY])(nil);
                        }
                    }
                    else
                    {
                        if (weakSelf.buttonActionMap[kButtonY])
                        {
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
    [self updateLevelButtons];
}


- (void)controllerGone:(NSNotification *)connectedNotification {
    [self clearController];
    self.controllerLabel.text = @"";
    self.controllerLabel.hidden = YES;
    self.controllerConnected = NO;
    [self.buttonActionMap removeAllObjects];
    [self updateLevelButtons];
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

- (IBAction)swipeRight:(id)sender {
    [self scheduleMove:kMoveKeyRight];
}

- (IBAction)swipeLeft:(id)sender {
    [self scheduleMove:kMoveKeyLeft];
}

- (IBAction)swipeUp:(id)sender {
     [self scheduleMove:kMoveKeyUp];
}

- (IBAction)swipeDown:(id)sender {
    [self scheduleMove:kMoveKeyDown];
}

- (IBAction)tapped:(UITapGestureRecognizer *)sender

{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        SKView *view = (SKView*)self.view;
        CGPoint scenePoint = [view convertPoint:[sender locationInView:self.view] toScene:view.scene];
        CGRect  gameRect = CGRectMake(self.display.boardLayer.position.x, self.display.boardLayer.position.y, kTileWidth*kBoardWidth, kTileHeight*kBoardHeight);
        
        if (CGRectContainsPoint(gameRect, scenePoint))
        {
            [self scheduleMove:kMoveKeySkip];
        }
        
        DEBUG_LOG(@"%f %f", scenePoint.x, scenePoint.y);
    }
}

- (IBAction)settingsTouched:(id)sender {
    
    /*
     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
     options:[NSDictionary dictionary]
     completionHandler:nil];
     
     */
    
    
    // grab the view controller we want to show
    
    UINavigationController *controller = [[UINavigationController alloc] init];
    
    UIViewController *settings = [[SettingsTableViewController alloc] init];
    
    [controller pushViewController:settings animated:NO];
    controller.title = @"Settings";

    
    // present the controller
    // on iPad, this will be a Popover
    // on iPhone, this will be an action sheet
    controller.modalPresentationStyle = UIModalPresentationPopover;
    [self presentViewController:controller animated:YES completion:nil];
    
    // configure the Popover presentation controller
    UIPopoverPresentationController *popController = [controller popoverPresentationController];
    popController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popController.sourceView = self.settingsButton;
    
    
}

- (void)animationsStarted
{
    _busy = YES;
    self.animatingLabel.text = @"🤔";
}

- (void)animationsDone
{
    _busy = NO;
    self.animatingLabel.text = @"";
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"showScreenSelector"]){
        ScreenSelector *controller = (ScreenSelector *)segue.destinationViewController;
        controller.gameView = self;
    }
}

- (int)currentScreen
{
    return _num;
}

- (int)highest
{
    if (self.achievements.count >= kMaxScreen)
    {
        return kFinalScreen;
    }
    return kMaxScreen;
}

- (IBAction)showHighScores:(id)sender
{
    if (_gameCenter)
    {
        [[GameCenterMgr sharedManager] showLeaderboard];
    }
}

- (IBAction)showAchievements:(id)sender
{
    if (_gameCenter)
    {
        [[GameCenterMgr sharedManager] showAchievements];
    }
}

- (IBAction)showHelp:(id)sender
{
    // grab the view controller we want to show
    UIViewController *controller = [[HelpScreen alloc] init];
    
    // present the controller
    // on iPad, this will be a Popover
    // on iPhone, this will be an action sheet
    controller.modalPresentationStyle = UIModalPresentationPopover;
    [self presentViewController:controller animated:YES completion:nil];
    
    // configure the Popover presentation controller
    UIPopoverPresentationController *popController = [controller popoverPresentationController];
    popController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popController.sourceView = self.helpButton;
}
- (IBAction)playbackSpeedChanged:(id)sender
{
    if (self.playbackState == PlaybackStepping)
    {
        // NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        switch (self.playbackSpeedSeg.selectedSegmentIndex)
        {
            case kSegStep:
                [self controlButtonUp:nil];
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
        [self updateLevelButtons];
    }
}

#pragma mark In app purchases

- (void)donated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:kDonated];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)donate:(id)sender
{
    if([SKPaymentQueue canMakePayments]){
        SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:kDonateProductIdentifier]];
        productsRequest.delegate = self;
        [productsRequest start];
        // self.donateButton.titleLabel.text=@"Working...";
        self.donateButton.enabled = NO;
    }
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    SKProduct *validProduct = nil;
    NSInteger count = [response.products count];
    if(count > 0){
        validProduct = [response.products objectAtIndex:0];
        
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:validProduct.priceLocale];
        
//      NSLocale* storeLocale = validProduct.priceLocale;
//      NSString *storeCountry = (NSString*)CFLocaleGetValue((CFLocaleRef)storeLocale, kCFLocaleCountryCode);
        NSString *price = [numberFormatter stringFromNumber:validProduct.price];
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Donate"
                                                                       message:[NSString stringWithFormat:@"If you like this app, would you donate %@ to the developer? The features of the app will rename the same, but the 'Donate!' button will disappear.",
                                                                                                            price]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[self actionWithTitle:@"OK" style:UIAlertActionStyleDestructive
                                    buttonName:kButtonA
                                       handler:^(UIAlertAction * action) {
                                           
                                           [self purchase:validProduct];
                                           
                                       }]];
        
        [alert addAction:[self actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                    buttonName:kButtonX
                                       handler:nil]];
        
        
        [alert addAction:[self actionWithTitle:@"Restore Purchases" style:UIAlertActionStyleDefault
                                    buttonName:kButtonY
                                       handler:^(UIAlertAction * action) {
                                           [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
                                           [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
                                       }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    else if(!validProduct){
        // NSLog(@"No products available");
        //this is called if your product id is not valid, this shouldn't be called unless that happens.
        
        DEBUG_LOG(@"Bad ids %@", response.invalidProductIdentifiers.debugDescription);
    }
    
    
    // self.donateButton.titleLabel.text=@"Donate!";
    self.donateButton.enabled = YES;
}

- (void)purchase:(SKProduct *)product{
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}


- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    DEBUG_LOG(@"received restored transactions: %lu", (unsigned long)queue.transactions.count);
    for(SKPaymentTransaction *transaction in queue.transactions){
        if(transaction.transactionState == SKPaymentTransactionStateRestored){
            //called when the user successfully restores a purchase
            DEBUG_LOG(@"Transaction state -> Restored");

            [self donated];
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            break;
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{
    for(SKPaymentTransaction *transaction in transactions){
        //if you have multiple in app purchases in your app,
        //you can get the product identifier of this transaction
        //by using transaction.payment.productIdentifier
        //
        //then, check the identifier against the product IDs
        //that you have defined to check which product the user
        //just purchased
        
        switch(transaction.transactionState){
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
                break;
            case SKPaymentTransactionStateRestored:
                DEBUG_LOG(@"Transaction state -> Restored");
                //add the same code as you did from SKPaymentTransactionStatePurchased here
                [self donated];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                //called when the transaction does not finish
                if(transaction.error.code == SKErrorPaymentCancelled){
                    DEBUG_LOG(@"Transaction state -> Cancelled");
                    //the user cancelled the payment ;(
                }
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
        }
    }
}

@end
