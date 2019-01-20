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

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import <GameplayKit/GameplayKit.h>
#import "SpriteDisplay.h"
#import "SpriteDisplay.h"
#import "GameViewController.h"
#import <GameController/GameController.h>
#import <StoreKit/StoreKit.h>
#import "AugmentedSegmentControl.h"



@interface GameViewControlleriPad : GameViewController
{
    int _maxPlaybackMoves;
}

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UILabel *controllerConnectedLabel;
@property (strong, nonatomic) IBOutlet SKView *spriteView;
@property (strong, nonatomic) IBOutlet UIButton *startOverButton;
@property (strong, nonatomic) IBOutlet UIButton *settingsButton;
@property (strong, nonatomic) IBOutlet UILabel *achievementLabel;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *scoreLabel;
@property (strong, nonatomic) IBOutlet UILabel *diamondsLabel;
@property (strong, nonatomic) IBOutlet UILabel *maxMovesLabel;
@property (strong, nonatomic) IBOutlet UILabel *monsterLabel;
@property (strong, nonatomic) IBOutlet UILabel *busyLabel;
@property (strong, nonatomic) IBOutlet UILabel *totalScoreLabel;
@property (strong, nonatomic) IBOutlet UIButton *playbackButton;
@property (strong, nonatomic) IBOutlet AugmentedSegmentControl *playbackSpeedSeg;
@property (strong, nonatomic) IBOutlet UIButton *previousButton;
@property (strong, nonatomic) IBOutlet UIButton *nextButton;
@property (strong, nonatomic) IBOutlet UILabel *controllerLabel;
@property (strong, nonatomic) IBOutletCollection(UISwipeGestureRecognizer) NSArray *gestures;
@property (strong, nonatomic) IBOutlet UIView *screenClusterView;
@property (strong, nonatomic) IBOutlet UIButton *saveCheckpointButton;
@property (strong, nonatomic) IBOutlet UILabel *playbackMoves;
@property (strong, nonatomic) IBOutlet UIButton *helpButton;
@property (strong, nonatomic) IBOutlet UIButton *highScoresButton;
@property (strong, nonatomic) IBOutlet UIButton *achievementsButton;
@property (strong, nonatomic) IBOutlet UILabel *animatingLabel;
@property (strong, nonatomic) IBOutlet UIButton *donateButton;
@property (strong, nonatomic) IBOutlet UILabel *thanksLabel;
@property (strong, nonatomic) IBOutlet DirectionClusterControl *controlClusterView;
@property (strong, nonatomic) IBOutlet UIProgressView *playbackProgress;

- (IBAction)donate:(id)sender;
- (IBAction)saveCheckpoint:(id)sender;
- (IBAction)playbackPressed:(id)sender;
- (IBAction)controlButtonUp:(id)sender;
- (IBAction)playbackSpeedChanged:(id)sender;
- (IBAction)previous:(id)sender;
- (IBAction)next:(id)sender;
- (IBAction)startOver:(id)sender;
- (IBAction)swipeRight:(id)sender;
- (IBAction)swipeLeft:(id)sender;
- (IBAction)swipeUp:(id)sender;
- (IBAction)swipeDown:(id)sender;
- (IBAction)tapped:(UITapGestureRecognizer *)sender;
- (IBAction)settingsTouched:(id)sender;
- (IBAction)showHighScores:(id)sender;
- (IBAction)showAchievements:(id)sender;
- (IBAction)showHelp:(id)sender;


@end
