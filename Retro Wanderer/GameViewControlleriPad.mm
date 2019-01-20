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

#import "GameViewControlleriPad.h"
#import "GameScene.h"
#import <AudioToolbox/AudioToolbox.h>
#import "ScreenSelector.h"
#import "GameCenterMgr.h"
#import "HelpScreen.h"
#import "DebugLogging.h"
#import "SettingsTableViewController.h"




#define kControllerText     @"Controller Connected. Use:\n● D-pad to move,\n● button 'A' to skip.\n"

@implementation GameViewControlleriPad

@dynamic spriteView;

- (void)updateButtons
{
    self.previousButton.hidden = !(_num > 0);
    self.nextButton.hidden = !(_num < self.highest);
    
    [self setButtonForController:self.previousButton title:@"⇤" buttonName:kButtonL1 keyName:kKeyQ buttonOnRight:YES controllerFont:[UIFont systemFontOfSize:15] regularFont:[UIFont systemFontOfSize:26] space:nil];
    [self setButtonForController:self.nextButton     title:@"⇥" buttonName:kButtonR1 keyName:kKeyW buttonOnRight:NO  controllerFont:[UIFont systemFontOfSize:15] regularFont:[UIFont systemFontOfSize:26] space:nil];
    
    NSDictionary *achievement = [self achievementForScreen:_num];
    
    if (self.controllerConnected)
    {
        self.controllerConnectedLabel.text = @"🎮";
    }
    else
    {
        self.controllerConnectedLabel.text = @"";
    }
    
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
            if (self.nextAction != NextActionPlayback)
            {
                [self setButtonForController:self.playbackButton title:@"Stop playback" buttonName:kButtonPause keyName:kKeyD buttonOnRight:YES space:nil];
                self.playbackButton.hidden = NO;
            }
            else
            {
                self.playbackButton.hidden = YES;
            }
            self.buttonActionMap[kButtonY] = nil;
            
            self.display.screenPrefix = @"Playing back screen ";
            
            [self setButtonsForSeg:self.playbackSpeedSeg titles:@[@"Step", @"Slow Mo", @"Normal", @"Fast"] firstButton:kButtonA restButton:kButtonX restKey:kKeyX];
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
            
            self.playbackProgress.hidden = NO;
            if (_maxPlaybackMoves == 0)
            {
                self.playbackProgress.progress = 0;
            }
            
            break;
        case PlaybackOverrun:
        case PlaybackRecording:
            self.display.screenPrefix = @"Screen ";
            
            if (self.savedKeyStrokes)
            {
                [self setButtonForController:self.playbackButton title:@"Start playback" buttonName:kButtonY keyName:kKeyP buttonOnRight:YES space:nil];
                self.playbackButton.hidden = NO;
                self.buttonActionMap[kButtonPause] = nil;
            }
            else
            {
                self.playbackButton.hidden = YES;
            }
            [self hideSegment:self.playbackSpeedSeg];
            self.saveCheckpointButton.hidden = !_unsavedMoves;
            [self setButtonForController:self.saveCheckpointButton title:@"Save checkpoint" buttonName:kButtonX keyName:kKeyS buttonOnRight:YES space:nil];
            self.playbackMoves.hidden = YES;
            self.playbackProgress.hidden = YES;
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
            self.display.screenPrefix = @"Played back screen ";
            self.playbackButton.hidden = YES;
            [self hideSegment:self.playbackSpeedSeg];
            self.saveCheckpointButton.hidden = !_unsavedMoves;
            [self setButtonForController:self.saveCheckpointButton title:@"Save checkpoint" buttonName:kButtonX keyName:kKeyS buttonOnRight:YES space:nil];
            self.playbackMoves.hidden = YES;
            self.playbackProgress.hidden = YES;
            break;
        case PlaybackDead:
            self.display.screenPrefix = @"Died on screen  ";
            self.playbackButton.hidden = YES;
            [self hideSegment:self.playbackSpeedSeg];
            self.saveCheckpointButton.hidden = YES;
            [self setButtonForController:self.saveCheckpointButton title:@"Save checkpoint" buttonName:kButtonX keyName:kKeyS buttonOnRight:YES space:nil];
            self.playbackMoves.hidden = NO;
            self.playbackProgress.hidden = YES;
            break;
    }
    
    [self setButtonForController:self.startOverButton title:@"Start over" buttonName:kButtonB keyName:UIKeyInputEscape buttonOnRight:YES space:nil];
    
    self.startOverButton.hidden = !((self.keyStrokes.length!=0) || self.playbackState==PlaybackDone);
    
    self.controllerLabel.hidden = YES;
    
    if (self.playbackState!=PlaybackStepping && self.playbackState!=PlaybackDone)
    {
        self.controlClusterView.hidden = NO;
        self.controlClusterView.upperView.stepMode = NO;
        self.controlClusterView.lowerView.stepMode = NO;
        [self.controlClusterView.lowerView showControls];
        [self.controlClusterView setNeedsDisplay];
    }
    else if (self.playbackSpeedSeg.selectedSegmentIndex != kSegStep)
    {
        self.controlClusterView.hidden = YES;
        self.controlClusterView.upperView.stepMode = NO;
        self.controlClusterView.lowerView.stepMode = NO;
        [self.controlClusterView.lowerView showControls];
        [self.controlClusterView setNeedsDisplay];
    }
    else
    {
        self.controlClusterView.hidden = NO;
        self.controlClusterView.upperView.stepMode = YES;
        self.controlClusterView.lowerView.stepMode = YES;
        [self.controlClusterView.lowerView showControls];
        [self.controlClusterView setNeedsDisplay];
    }
    
   [self.display updateName];
}

- (void)displaySetLabels
{
    self.display.scoreLabel = self.scoreLabel;
    self.display.diamondsLabel = self.diamondsLabel;
    self.display.maxMovesLabel = self.maxMovesLabel;
    self.display.monsterLabel = self.monsterLabel;
    self.display.nameLabel = self.nameLabel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
 
    [self.controlClusterView showLowerView];
    self.controlClusterView.lowerView.NoLines = YES;
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([self showHelpOnce])
    {
        [self showHelp:nil];
    }
}


- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)displayBusyText:(NSString *)text
{
    self.busyLabel.text = [NSString stringWithFormat:@"%d %lu %lu", self.display.animationCount, (unsigned long)self.display.fastMoveCache.count, (unsigned long)self.display.cacheHits];
    
}

- (void)displayPlaybackMoves:(int)moves
{
    self.playbackMoves.text = [NSString stringWithFormat:@"Playback moves: %d",moves];
    
    DEBUG_LOGL(moves);
    DEBUG_LOGL(_maxPlaybackMoves);
    
    if (_maxPlaybackMoves < moves)
    {
        _maxPlaybackMoves = moves;
    }
    
    if (_maxPlaybackMoves > 0)
    {
        [self.playbackProgress setProgress:1.0-((float)moves/(float)_maxPlaybackMoves) animated:YES];
    }
    
    
}

- (void)displayLeftHanded:(bool)left
{
    if (left)
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
}

- (void)displayGameCenter:(bool)enabled
{
    self.highScoresButton.hidden = !_gameCenter;
    self.achievementsButton.hidden = !_gameCenter;
}

- (void)displayDonated:(bool)donated capable:(bool)capable processing:(bool)processing
{
    self.donateButton.hidden = _donated || !capable || processing;
    
    if (_donated)
    {
        self.thanksLabel.text = @"❤️😀";
    }
    self.thanksLabel.hidden  = !_donated;
}

- (void)displayPlaybackSpeed:(int)playbackSpeed
{
    self.playbackSpeedSeg.selectedSegmentIndex = playbackSpeed;
}

- (int)getDisplayPlaybackSpeed
{
    return (int)self.playbackSpeedSeg.selectedSegmentIndex;
}

- (IBAction)saveCheckpoint:(id)sender {
    if (!_busy)
    {
        [self actionSaveCheckpoint];
    }
    else
    {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    }
}

- (IBAction)playbackPressed:(id)sender
{
    _maxPlaybackMoves = 0;
    [self schedulePlayback];
    [self updateButtons];
}

- (IBAction)controlButtonUp:(id)sender {
    
    if ([sender isKindOfClass:[DirectionClusterControl class]])
    {
        [((DirectionClusterControl*)sender).upperView fadeOut];
    }
    
    [self actionButtonUp];
}

- (IBAction)controlButtonTouched:(id)sender forEvent:(UIEvent *)event {
    [self controlClusterTouched:sender event:event];
}


- (IBAction)startOver:(id)sender {
    if (!_busy)
    {
        [self actionStartOver];
    }
    else
    {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    }
}

- (IBAction)next:(id)sender {
    if (!_busy)
    {
        [self actionNext];
    }
    else
    {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    }
}


- (IBAction)previous:(id)sender {
    if (!_busy)
    {
        [self actionPrevious];
    }
    else
    {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    }
}

- (IBAction)swipeRight:(id)sender {
    [self actionSwipeRight];
}

- (IBAction)swipeLeft:(id)sender {
    [self actionSwipeLeft];
}

- (IBAction)swipeUp:(id)sender {
    [self actionSwipeUp];
}

- (IBAction)swipeDown:(id)sender {
     [self actionSwipeDown];
}

- (IBAction)tapped:(UITapGestureRecognizer *)sender

{
    [self actionTapped:sender];
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
    popController.permittedArrowDirections = UIPopoverArrowDirectionLeft;
    popController.sourceView = self.settingsButton;
    
    const CGFloat side = 3;
    CGRect frame = self.settingsButton.frame;
    CGRect sourceRect = CGRectMake(frame.size.width - side, (frame.size.height-side)/2.0, side, side);
    
    popController.sourceRect = sourceRect;
    
}

- (void)showBusy:(bool)busy
{
    if (busy)
    {
        [self.activityIndicator startAnimating];
    }
    else
    {
         [self.activityIndicator stopAnimating];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"showScreenSelector"]){
        ScreenSelector *controller = (ScreenSelector *)segue.destinationViewController;
        controller.gameView = self;
    }
}

- (IBAction)showHighScores:(id)sender
{
    [self actionShowHighScores];
}

- (IBAction)showAchievements:(id)sender
{
    [self actionShowAchievements];
}

- (IBAction)showHelp:(id)sender
{
    // grab the view controller we want to show
    HelpScreen *controller = [[HelpScreen alloc] init];
    
    controller.iPad = YES;
    
    // present the controller
    // on iPad, this will be a Popover
    // on iPhone, this will be an action sheet
    controller.modalPresentationStyle = UIModalPresentationPopover;
    [self presentViewController:controller animated:YES completion:nil];
    
    // configure the Popover presentation controller
    UIPopoverPresentationController *popController = [controller popoverPresentationController];
    popController.permittedArrowDirections = UIPopoverArrowDirectionRight;
    popController.sourceView = self.helpButton;
    
    const CGFloat side = 3;
    CGRect frame = self.helpButton.frame;
    CGRect sourceRect = CGRectMake(0, (frame.size.height-side)/2.0, side, side);
    
    popController.sourceRect = sourceRect;
}

- (IBAction)playbackSpeedChanged:(id)sender
{
    [self actionPlaybackSpeedChanged];
}

- (IBAction)donate:(id)sender
{
    [self actionDonate];
}


@end
