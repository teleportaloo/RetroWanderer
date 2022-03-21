/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import <GameplayKit/GameplayKit.h>
#import "SpriteDisplay.h"
#import "SpriteDisplay.h"
#import <GameController/GameController.h>
#import <StoreKit/StoreKit.h>
#import "DirectionClusterControl.h"

extern "C"
{
#include "wand_head.h"
}


#define kButtonA     @"(A)"
#define kButtonB     @"(B)"
#define kButtonX     @"(X)"
#define kButtonY     @"(Y)"
#define kButtonL1    @"(L1)"
#define kButtonR1    @"(R1)"
#define kButtonL2    @"(L2)"
#define kButtonR2    @"(R2)"
#define kButtonL     @"(←)"
#define kButtonR     @"(→)"
#define kButtonU     @"(↑)"
#define kButtonD     @"(↓)"
#define kButtonPause @"(||)"

#define kKeyReturn   @"\n"
#define kKeyR        @"r"
#define kKeyN        @"n"
#define kKeyP        @"p"
#define kKeyQ        @"q"
#define kKeyD        @"d"
#define kKeyW        @"w"
#define kKeyS        @"s"
#define kKeyX        @"x"
#define kKeyM        @"m"
#define kKeyN        @"n"




#define CGPointOffsetted(A, B) CGPointMake((A).x + (B).x, (A).y + (B).y)



#define kSegStep   0
#define kSegSlowMo 1
#define kSegSlow   2
#define kSegFast   3

@class AugmentedSegmentControl;


typedef void (^AlertBlock)(UIAlertAction *action);
typedef void (^ButtonAction)();

enum NextAction {
    NextActionDoNothing = 0,
    NextActionInitScreen,
    NextActionInitScreenAndPlayback,
    NextActionMove,
    NextActionPlayback
};

enum PlaybackState {
    PlaybackRecording,
    PlaybackStepping,
    PlaybackOverrun,
    PlaybackDone,
    PlaybackDead
};

@interface GameViewController : UIViewController <SpriteDisplayDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver> {
    long _screen_score;
    long _total_score;
    NSInteger _ordinal;
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
@property (nonatomic, retain) NSMutableDictionary<NSString *, AlertBlock> *alertActionMap;
@property (nonatomic, retain) NSMutableDictionary<NSString *, ButtonAction> *buttonActionMap;
@property (nonatomic, retain) NSMutableDictionary<NSString *, NSString *> *cellTextButton;
@property (nonatomic, retain) id<NSObject> observerObj;
@property (nonatomic, retain) NSArray<UIKeyCommand *> *keyCommands;

@property (strong, nonatomic) IBOutlet SKView *spriteView;

@property (nonatomic, readonly) NSInteger currentScreenOrdinal;

@property (nonatomic, readonly) bool showNextScreen;
@property (nonatomic, readonly) bool showPrevScreen;

@property (nonatomic, retain) NSTimer *busyTimer;

@property (nonatomic, readonly) UIRectEdge preferredScreenEdgesDeferringSystemGestures;


- (void)setButtonForController:(UIButton *)button title:(NSString *)title buttonName:(NSString *)buttonName keyName:(NSString *)keyName buttonOnRight:(bool)buttonOnRight space:(NSString *)space;
- (void)setButtonForController:(UIButton *)button title:(NSString *)title buttonName:(NSString *)buttonName keyName:(NSString *)keyName buttonOnRight:(bool)buttonOnRight controllerFont:(UIFont *)controllerFont regularFont:(UIFont *)regularFont space:(NSString *)space;
- (void)setButtonsForSeg:(AugmentedSegmentControl *)control titles:(NSArray<NSString *> *)titles firstButton:(NSString *)first restButton:(NSString *)rest restKey:(NSString *)key;
- (void)setButtonForCell:(NSString *)cellText buttonName:(NSString *)buttonName action:(ButtonAction)action;
- (NSString *)cellText:(NSString *)text buttonOnRight:(bool)right;

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

- (NSInteger)highestOrdinal;
- (void)processNextAction;
- (void)changeToScreenOrdinal:(NSInteger)ordinal review:(bool)review;
- (NSDictionary *)achievementForScreenNum:(int)num;


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

- (int)screenNum;

@end
