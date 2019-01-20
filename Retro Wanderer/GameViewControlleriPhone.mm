//
//  GameViewControlleriPhone.m
//  Text Wanderer
//
//  Created by Andrew Wallace on 8/13/17.
//  Copyright © 2017 Teleportaloo. All rights reserved.
//

#import "GameViewControlleriPhone.h"
#import "GameCenterMgr.h"
#import "ScreenSelectorTable.h"
#import "HelpScreen.h"
#import "iPhoneControlsTableViewController.h"
#import "ScreenSelectorTable.h"
#import "DebugLogging.h"

@interface GameViewControlleriPhone ()

@end

@implementation GameViewControlleriPhone

@dynamic spriteView;

- (DirectionClusterControl *)clusterWithRect:(CGRect)rect
{
    DirectionClusterControl * cluster = [[DirectionClusterControl alloc] initWithFrame:rect];
    [cluster addTarget:self
                action:@selector(controlClusterTouchedUp:event:)
      forControlEvents: UIControlEventTouchUpInside
     | UIControlEventTouchCancel
     | UIControlEventTouchUpOutside
     //  | UIControlEventTouchDragExit
     //  | UIControlEventTouchDragInside
     //  | UIControlEventTouchDragOutside
     ] ;
    
    
    [cluster addTarget:self action:@selector(controlClusterTouched:event:)
      forControlEvents:UIControlEventTouchDown];
    
    [self.view addSubview:cluster];
    
    return cluster;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.revealViewController.rearViewRevealOverdraw = 0.0f;
    [self.leftMenuButton addTarget:self action:@selector(left:) forControlEvents:UIControlEventTouchUpInside];
    // [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
    self.revealViewController.rightViewRevealOverdraw = 0.0f;
    [self.rightMenuButton addTarget:self action:@selector(right:) forControlEvents:UIControlEventTouchUpInside];
    
    
    self.cellActions = [NSMutableDictionary dictionary];
    
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionTapped:)];
    [[self view] addGestureRecognizer:recognizer];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (self.directionControlLeft == nil)
    {
        CGPoint screenOpposite = CGPointMake(self.display.boardLayer.position.x + kTileWidth*kBoardWidth, self.display.boardLayer.position.y + kTileHeight*kBoardHeight);
        
        CGPoint origin    = [self.spriteView convertPoint:self.display.boardLayer.position fromScene:self.spriteView.scene];
        CGPoint opposite  = [self.spriteView convertPoint:screenOpposite fromScene:self.spriteView.scene];
        
        origin =   CGPointOffsetted(origin, self.spriteView.frame.origin);
        opposite = CGPointOffsetted(opposite, self.spriteView.frame.origin);
        
        self.directionControlLeft = [self clusterWithRect:CGRectMake(
                                                                     origin.x,
                                                                     origin.y+(opposite.y-origin.y),
                                                                     (opposite.x-origin.x)/2,
                                                                     -(opposite.y-origin.y))];
        
        self.directionControlRight = [self clusterWithRect:CGRectMake(
                                                                      origin.x + (opposite.x-origin.x)/2,
                                                                      origin.y+(opposite.y-origin.y),
                                                                      (opposite.x-origin.x)/2,
                                                                      -(opposite.y-origin.y))];
        
        self.directionControlLeft.left  = YES;
        self.directionControlLeft.topGuides = YES;
        self.directionControlLeft.bottomGuides = YES;
        self.directionControlLeft.leftGuides = YES;
        
        self.directionControlRight.right = YES;
        
        self.directionControlRight.topGuides = YES;
        self.directionControlRight.bottomGuides = YES;
        self.directionControlRight.rightGuides = YES;
        
        if (@available(iOS 11, *))
        {
            UIEdgeInsets safeArea = self.view.safeAreaInsets;
            self.revealViewController.rightViewRevealWidth += safeArea.right;
            [self setNeedsUpdateOfHomeIndicatorAutoHidden];
        }
    }
}

- (BOOL)prefersHomeIndicatorAutoHidden
{
    return YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([self showHelpOnce])
    {
        [self helpTouched:nil];
    }
    
    if (@available(iOS 11, *))
    {
        [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    }
}

- (void)left:(id)sender
{
    if (self.revealViewController.rearViewController)
    {
        UINavigationController *left = (UINavigationController *)self.revealViewController.rearViewController;
        
        for (UITableViewController *controller in left.viewControllers)
        {
            [controller.tableView reloadData];
        }
    }
    
    [self.revealViewController revealToggle:sender];
}


- (void)right:(id)sender
{
    if (self.revealViewController.rightViewController)
    {
        UITableViewController *right = (UITableViewController *)self.revealViewController.rightViewController;
        [right.tableView reloadData];
    }
    
    [self.revealViewController rightRevealToggle:sender];
}

- (void)helpDone:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.directionControlLeft.upperView showControls];
        [self.directionControlRight.upperView showControls];
    }];
}

- (void)scheduleMove:(char)move
{
    if (move == kMoveKeyStep && self.playbackState == PlaybackStepping && self.getDisplayPlaybackSpeed != kSegStep)
    {
      
            self.playbackSpeedSeg.selectedSegmentIndex = kSegStep;
            [self actionPlaybackSpeedChanged];
    }
    else
    {
        [super scheduleMove:move];
    }
}

-(void) helpTouched:(id)sender
{
    HelpScreen *help = [[HelpScreen alloc] init];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:help];
    help.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(helpDone:)];
    
    help.action = ^{
        [self helpDone:nil];
    };
    
    help.title = @"Instructions";
    
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    // help.transitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:nav animated:YES completion: nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

- (void)saveButtonHidden:(bool)hidden
{
    __weak typeof(self) weakSelf = self;
    
    
    self.saveCheckpointButton.hidden = hidden;
    
    if (hidden)
    {
        [self setButtonForCell:kSaveCheckpoint buttonName:kButtonX action:nil];
    }
    else
    {
        [self setButtonForCell:kSaveCheckpoint buttonName:kButtonX action:^{
            [weakSelf actionSaveCheckpoint];
        }];
    };
}

-(void)cellButtonState:(UIButton *)button cell:(NSString*)cell controller:(NSString*)controller hidden:(bool)hidden action:(ButtonAction)action
{
    button.hidden = hidden;
    
    if (hidden)
    {
        [self setButtonForCell:cell buttonName:controller action:nil];
        if (self.cellActions[cell])
        {
            self.cellActions[cell] = nil;
        }
    }
    else
    {
        [self setButtonForCell:cell buttonName:controller action:action];
        self.cellActions[cell] = action;
    };
}

- (void)reloadSidebars
{
    if (self.revealViewController.rearViewController!=nil)
    {
        UINavigationController *left = (UINavigationController*)self.revealViewController.rearViewController;
        
        for (UITableViewController *v in left.viewControllers)
        {
             [v.tableView reloadData];
        }
       
    }
    
    if (self.revealViewController.rightViewController!=nil)
    {
        UITableViewController *right = (UITableViewController*)self.revealViewController.rightViewController;
        [right.tableView reloadData];
    }
}

- (void)updateButtons
{
    
    [self setButtonForController:self.leftMenuButton  title:@"Menu"    buttonName:kButtonL2 keyName:kKeyM buttonOnRight:YES space:@"  "];
    [self setButtonForController:self.rightMenuButton title:@"Screens" buttonName:kButtonR2 keyName:kKeyN buttonOnRight:YES space:@"  "];
    
    __weak typeof(self) weakSelf = self;
    
    if (self.controllerConnected)
    {
        self.controllerConnectedLabel.text = @"🎮";
    }
    else
    {
        self.controllerConnectedLabel.text = @"";
    }
    
    if (self.showPrevScreen)
    {
        [self setButtonForCell:kPrevText buttonName:kButtonL1 action:^{
            [weakSelf changeToScreen:self.currentScreen-1 review:NO];
        }];
    }
    else
    {
        [self setButtonForCell:kPrevText buttonName:kButtonL1 action:nil];
        
    }
    if (self.showNextScreen)
    {
        [self setButtonForCell:kNextText buttonName:kButtonR1 action:^{
            [weakSelf changeToScreen:self.currentScreen+1 review:NO];
        }];
    }
    else
    {
        [self setButtonForCell:kNextText buttonName:kButtonR1 action:nil];
    }
    
    switch (self.playbackState)
    {
        case PlaybackStepping:
        {
            [self cellButtonState:self.startPlaybackButton cell:kStart controller:kButtonY     hidden:YES action:nil];
            [self cellButtonState:self.stopPlaybackButton  cell:kStop  controller:kButtonPause hidden:self.nextAction==NextActionPlayback  action:^{
                [self resetViews];
                [weakSelf actionPlayback];
            }];
            
            self.display.screenPrefix = @"Playing back screen ";
            
            self.directionControlLeft.upperView.stepMode  = YES;
            self.directionControlRight.upperView.stepMode = YES;
            
            [self setButtonsForSeg:self.playbackSpeedSeg titles:@[@"Step", @"Slow Mo", @"Normal", @"Fast"] firstButton:kButtonA restButton:kButtonX restKey:kKeyX];
            self.playbackSpeedSeg.hidden = NO;
            
            self.playbackMoves.hidden = NO;
            if (_maxPlaybackMoves == 0)
            {
                self.playbackMoves.progress = 0.0;
            }
            break;
        }
        case PlaybackOverrun:
        case PlaybackRecording:
        {
            self.display.screenPrefix = @"Screen ";
            
            if (self.savedKeyStrokes)
            {
                [self cellButtonState:self.startPlaybackButton  cell:kStart controller:kButtonY hidden:NO action:^{
                    [self resetViews];
                    [weakSelf actionPlayback];
                }];
            }
            else
            {
                [self cellButtonState:self.startPlaybackButton  cell:kStart controller:kButtonY hidden:YES action:nil];
            }
            
            
            [self cellButtonState:self.stopPlaybackButton  cell:kStop controller:kButtonPause hidden:YES action:nil];
            
            
            [self hideSegment:self.playbackSpeedSeg];
            
            [self cellButtonState:self.saveCheckpointButton  cell:kSaveCheckpoint controller:kButtonX hidden:!_unsavedMoves action:^{
                [self resetViews];
                [weakSelf actionSaveCheckpoint];
            }];
            
            self.directionControlLeft.upperView.stepMode  = NO;
            self.directionControlRight.upperView.stepMode = NO;
            

            self.playbackMoves.hidden = YES;
            
            break;
        }
        case PlaybackDead:
            [self cellButtonState:self.startPlaybackButton   cell:kStart           controller:kButtonY     hidden:YES action:nil];
            [self cellButtonState:self.stopPlaybackButton    cell:kStop            controller:kButtonPause hidden:YES action:nil];
            [self cellButtonState:self.saveCheckpointButton  cell:kSaveCheckpoint  controller:kButtonX     hidden:YES action:nil];
            
            [self hideSegment:self.playbackSpeedSeg];
            
            self.directionControlLeft.upperView.stepMode  = NO;
            self.directionControlRight.upperView.stepMode = NO;
            
            self.playbackMoves.hidden = YES;
            
            self.display.screenPrefix = @"Died on screen ";
            
            break;
        case PlaybackDone:
            [self cellButtonState:self.startPlaybackButton   cell:kStart           controller:kButtonY     hidden:YES action:nil];
            [self cellButtonState:self.stopPlaybackButton    cell:kStop            controller:kButtonPause hidden:YES action:nil];
            [self cellButtonState:self.saveCheckpointButton  cell:kSaveCheckpoint  controller:kButtonX     hidden:!_unsavedMoves
                           action:^{
                               [self resetViews];
                               [weakSelf actionSaveCheckpoint];
                           }];
            
            [self hideSegment:self.playbackSpeedSeg];
            
            self.directionControlLeft.upperView.stepMode  = NO;
            self.directionControlRight.upperView.stepMode = NO;
            
            self.playbackMoves.hidden = YES;
            
            self.display.screenPrefix = @"Played back screen ";
            
            break;
    }
    
    //[self setButtonForController:self.startOverButton title:@"Start over" buttonName:kButtonB buttonOnRight:YES];
    
    self.startOverButton.hidden = !((self.keyStrokes.length!=0) || self.playbackState==PlaybackDone || self.playbackState==PlaybackDead);
    
    
    
    [self cellButtonState:self.startOverButton
                     cell:kStartOver
               controller:kButtonB
                   hidden:!((self.keyStrokes.length!=0) || self.playbackState==PlaybackDone || self.playbackState==PlaybackDead)
                   action:^{
                       [self resetViews];
                       [weakSelf actionStartOver];
                   }];
    
    
    if (!self.controllerConnected)
    {
        if (self.playbackState!=PlaybackStepping && self.playbackState!=PlaybackDone && self.playbackState!=PlaybackDead)
        {
            self.directionControlLeft.hidden = NO;
            self.directionControlRight.hidden = NO;
        }
        else
        {
            self.directionControlLeft.upperView.stepMode  = YES;
            self.directionControlRight.upperView.stepMode = YES;
            self.directionControlLeft.hidden = NO;
            self.directionControlRight.hidden = NO;
        }
    }
    else
    {
        self.directionControlLeft.hidden = NO;
        self.directionControlRight.hidden = NO;
    }

    
    NSDictionary *achievement = [self achievementForScreen:_num];
    
    if (achievement && self.playbackSpeedSeg.hidden && self.saveCheckpointButton.hidden)
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
            self.achievementLabel.hidden = NO;
        }
        
    }
    else
    {
        self.achievementLabel.text = @"";
        self.achievementLabel.hidden = YES;
    }
    
    if (self.achievementLabel.hidden && self.playbackSpeedSeg.hidden)
    {
        self.mainTitle.hidden = NO;
    }
    else
    {
        self.mainTitle.hidden = YES;
    }
    
    [self reloadSidebars];
    [self.display updateName];
}

- (void)resetViews
{
    if (self.revealViewController.frontViewPosition != FrontViewPositionLeft)
    {
        [self.revealViewController setFrontViewPosition:FrontViewPositionLeft animated:YES];
    }
}

- (void)displaySetLabels
{
    self.display.scoreLabel    = self.scoreLabel;
    
    if (@available(iOS 11, *))
    {
        UIEdgeInsets safeArea = self.view.safeAreaInsets;
        
        if (safeArea.bottom > 0)
        {
            self.display.diamondsLabel = self.sideDiamondLabel;
            self.diamondsLabel.hidden = YES;
        }
    }
    
    if (self.display.diamondsLabel == nil)
    {
        self.display.diamondsLabel = self.diamondsLabel;
        self.sideDiamondLabel.hidden = YES;
    }
    
    self.display.maxMovesLabel = self.maxMovesLabel;
    self.display.monsterLabel  = self.monsterLabel;
    self.display.nameLabel     = self.nameLabel;
}

- (void)actionTapped:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        if (self.revealViewController.frontViewPosition != FrontViewPositionLeft)
        {
            [self.revealViewController setFrontViewPosition:FrontViewPositionLeft animated:YES];
        }
        else
        {
            CGPoint scenePoint = [self.spriteView convertPoint:[sender locationInView:self.spriteView] toScene:self.spriteView.scene];
            CGRect  gameRect = CGRectMake(self.display.boardLayer.position.x, self.display.boardLayer.position.y, kTileWidth*kBoardWidth, kTileHeight*kBoardHeight);
            
            // Origin is bottom left
            
            
            if (!CGRectContainsPoint(gameRect, scenePoint))
            {
                [self.directionControlLeft.upperView showControls];
                [self.directionControlRight.upperView showControls];
            }

        }
    }
}


- (IBAction)saveCheckpoint:(id)sender {
    if (!_busy)
    {
        [self actionSaveCheckpoint];
    }
}
- (IBAction)playbackSpeedChanged:(id)sender {
    
    [self actionPlaybackSpeedChanged];
}

- (int)getDisplayPlaybackSpeed
{
    return (int)self.playbackSpeedSeg.selectedSegmentIndex;
}

- (void)displayPlaybackSpeed:(int)playbackSpeed
{
    self.playbackSpeedSeg.selectedSegmentIndex = playbackSpeed;
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
    self.rightMenuButton.enabled = !_busy;
}

- (void)displayDonated:(bool)donated capable:(bool)capable processing:(bool)processing
{
    self.donateButton.hidden = _donated || !capable || processing;
    
    if (_donated)
    {
        self.thanksLabel.text = @"❤️";
    }
    self.thanksLabel.hidden  = !_donated;
}

- (void)displayPlaybackMoves:(int)moves
{
    DEBUG_LOGL(moves);
    DEBUG_LOGL(_maxPlaybackMoves);
    
    if (_maxPlaybackMoves < moves)
    {
        _maxPlaybackMoves = moves;
    }
    
    if (_maxPlaybackMoves > 0)
    {
        [self.playbackMoves setProgress:1.0-((float)moves/(float)_maxPlaybackMoves) animated:YES];
    }
}


- (IBAction)donate:(id)sender {
    [self actionDonate];
}
- (IBAction)startPlayback:(id)sender {
    if (!_busy)
    {
        _maxPlaybackMoves = 0;
        [self actionPlayback];
    }
    else
    {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    }
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

- (IBAction)stopPlaybackTouched:(id)sender {
    [self schedulePlayback];
    [self updateButtons];
}
@end
