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
#import <GameController/GameController.h>
#import <StoreKit/StoreKit.h>
#import "DirectionClusterControl.h"

#define kMaxScreen 60
#define kFinalScreen 61

extern "C"
{
#include "wand_head.h"
}


#define kButtonA            @"(A)"
#define kButtonB            @"(B)"
#define kButtonX            @"(X)"
#define kButtonY            @"(Y)"
#define kButtonL1           @"(L1)"
#define kButtonR1           @"(R1)"
#define kButtonL2           @"(L2)"
#define kButtonR2           @"(R2)"
#define kButtonL            @"(←)"
#define kButtonR            @"(→)"
#define kButtonU            @"(↑)"
#define kButtonD            @"(↓)"
#define kButtonPause        @"(||)"

#define kKeyReturn          @"\n"
#define kKeyR               @"r"
#define kKeyN               @"n"
#define kKeyP               @"p"
#define kKeyQ               @"q"
#define kKeyD               @"d"
#define kKeyW               @"w"
#define kKeyS               @"s"
#define kKeyX               @"x"
#define kKeyM               @"m"
#define kKeyN               @"n"




#define CGPointOffsetted(A, B) CGPointMake((A).x + (B).x, (A).y + (B).y)



#define kSegStep            0
#define kSegSlowMo          1
#define kSegSlow            2
#define kSegFast            3

@class AugmentedSegmentControl;


typedef void (^AlertBlock)(UIAlertAction *action);
typedef void (^ButtonAction)();

enum NextAction
{
    NextActionDoNothing,
    NextActionInitScreen,
    NextActionMove,
    NextActionPlayback
};

enum PlaybackState
{
    PlaybackRecording,
    PlaybackStepping,
    PlaybackOverrun,
    PlaybackDone,
    PlaybackDead
};

@interface GameViewController : UIViewController <SpriteDisplayDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
    long _screen_score;
    long _total_score;
    int  _num;
    game _game;
    int _bell;
    bool _busy;
    bool _unsavedMoves;
    int _playbackPosition;
    int _startPlaybackSpeed;
    bool _gameCenter;
    bool _donated;
    bool _initialRapidFire;
    CGRect _gameRect;
    bool _reinitForRetro;
    bool _busyTouched;
    bool _normalFlashing;
}

@property (nonatomic) bool gameCenter;
@property (nonatomic, strong) GCController *controller;
@property (atomic)  NextAction nextAction;
@property (atomic)  PlaybackState playbackState;
@property (atomic) int playbackPosition;
@property (nonatomic, retain) SpriteDisplay *display;
@property (atomic) char nextMove;
@property (nonatomic, retain) NSMutableString *keyStrokes;
@property (nonatomic, retain) NSString *savedKeyStrokes;
@property (nonatomic, retain) NSString *playbackKeyStrokes;

@property (atomic) bool controllerConnected;
@property (nonatomic, retain) NSTimer *rapidFireTimer;
@property (nonatomic, retain) GCControllerButtonInput *rapidFireControllerButton;
@property (nonatomic) char rapidFireDirection;
@property (nonatomic, retain) NSMutableDictionary<NSString *, NSDictionary *> *achievements;
@property (nonatomic) double rapidFireDuration;
@property (nonatomic, retain) NSMutableDictionary<NSString *, AlertBlock>* alertActionMap;
@property (nonatomic, retain) NSMutableDictionary<NSString *, ButtonAction>* buttonActionMap;
@property (nonatomic, retain) NSMutableDictionary<NSString *, NSString *> *cellTextButton;
@property (nonatomic, retain) id<NSObject> observerObj;
@property (nonatomic, retain) NSArray<UIKeyCommand *>* keyCommands;

@property (strong, nonatomic) IBOutlet SKView *spriteView;

@property (nonatomic, readonly) int currentScreen;

@property (nonatomic, readonly) bool showNextScreen;
@property (nonatomic, readonly) bool showPrevScreen;

@property (nonatomic, retain) NSTimer *busyTimer;



- (void)setButtonForController:(UIButton *)button title:(NSString *)title buttonName:(NSString *)buttonName keyName:(NSString*)keyName buttonOnRight:(bool)buttonOnRight space:(NSString *)space;
- (void)setButtonForController:(UIButton *)button title:(NSString *)title buttonName:(NSString *)buttonName keyName:(NSString*)keyName buttonOnRight:(bool)buttonOnRight controllerFont:(UIFont *)controllerFont regularFont:(UIFont *)regularFont space:(NSString *)space;
- (void)setButtonsForSeg:(AugmentedSegmentControl*)control titles:(NSArray<NSString*> *)titles firstButton:(NSString*)first restButton:(NSString*)rest restKey:(NSString*)key;
- (void)setButtonForCell:(NSString *)cellText buttonName:(NSString *)buttonName action:(ButtonAction)action;
- (NSString*)cellText:(NSString *)text buttonOnRight:(bool)right;

- (void)actionDonate;
- (void)actionSaveCheckpoint;
- (void)actionPlayback;
- (void)actionButtonUp;
- (void)actionPlaybackSpeedChanged;
- (void)actionDirection:(char)direction;
- (void)actionPrevious;
- (void)actionNext;
- (void)actionStartOver;
- (void)actionSwipeRight;
- (void)actionSwipeLeft;
- (void)actionSwipeUp;
- (void)actionSwipeDown;
- (void)actionTapped:(UITapGestureRecognizer *)sender;
- (void)actionShowHighScores;
- (void)actionShowAchievements;
- (void)hideSegment:(UISegmentedControl *)ctrl;

- (void)saveLevel;
- (void)initScreen;
- (long)totalScore;

- (void)scheduleMove:(char)move;
- (void)schedulePlayback;

- (int)highest;
- (void)processNextAction;
- (void)changeToScreen:(int)screen review:(bool)review;
- (NSDictionary*)achievementForScreen:(int)num;


- (void)displayPlaybackMoves:(int)moves;
- (void)displayBusyText:(NSString *)text;
- (void)displayLeftHanded:(bool)left;
- (void)displayGameCenter:(bool)enabled;
- (void)displayDonated:(bool)donated capable:(bool)capable processing:(bool)processing;
- (AugmentedSegmentControl *)speedSegment;

- (void)displaySetLabels;
- (int)getDisplayPlaybackSpeed;
- (void)updateButtons;

- (bool)showHelpOnce;

- (void)controlClusterTouchedUp:(id)sender event:(UIEvent *)event;
- (void)controlClusterTouched:(DirectionClusterControl *)sender event:(UIEvent *)event;
- (void)showBusy:(bool)busy;


@end
