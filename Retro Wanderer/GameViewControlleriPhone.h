//
//  GameViewControlleriPhone.h
//  Text Wanderer
//
//  Created by Andrew Wallace on 8/13/17.
//  Copyright © 2017 Teleportaloo. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GameViewController.h"
#import "SWRevealViewController/SWRevealViewController.h"
#import "AugmentedSegmentControl.h"

@interface GameViewControlleriPhone : GameViewController
{
    int _maxPlaybackMoves;
}

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UILabel *controllerConnectedLabel;
@property (strong, nonatomic) IBOutlet UILabel *sideDiamondLabel;
@property (strong, nonatomic) IBOutlet SKView *spriteView;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *gestureLeft;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *gestureRight;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *gestureUp;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *gestureDown;
@property (strong, nonatomic) IBOutlet UIButton *leftMenuButton;
@property (strong, nonatomic) IBOutlet UIButton *rightMenuButton;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *scoreLabel;
@property (strong, nonatomic) IBOutlet UILabel *diamondsLabel;
@property (strong, nonatomic) IBOutlet UILabel *maxMovesLabel;
@property (strong, nonatomic) IBOutlet UILabel *monsterLabel;
- (IBAction)saveCheckpoint:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *saveCheckpointButton;
@property (strong, nonatomic) IBOutlet AugmentedSegmentControl *playbackSpeedSeg;
- (IBAction)playbackSpeedChanged:(id)sender;
@property (strong, nonatomic) IBOutlet UILabel *achievementLabel;
@property (strong, nonatomic) IBOutlet UILabel *mainTitle;
- (IBAction)helpTouched:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *donateButton;
- (IBAction)donate:(id)sender;
@property (strong, nonatomic) IBOutlet UILabel *thanksLabel;
- (IBAction)startPlayback:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *startPlaybackButton;
@property (strong, nonatomic) IBOutlet UIButton *startOverButton;
- (IBAction)startOver:(id)sender;
- (IBAction)stopPlaybackTouched:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *stopPlaybackButton;

@property (nonatomic, retain) NSMutableDictionary<NSString *, ButtonAction>* cellActions;
@property (nonatomic, retain) DirectionClusterControl *directionControlLeft;
@property (nonatomic, retain) DirectionClusterControl *directionControlRight;
@property (strong, nonatomic) IBOutlet UIProgressView *playbackMoves;

@end
