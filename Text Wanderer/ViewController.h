//
//  ViewController.h
//  Text Wanderer
//
//  Created by Andrew Wallace on 4/29/17.
//  Copyright © 2017 Teleportaloo. All rights reserved.
//

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>

#import <GameController/GameController.h>
#import "SimpleTextDisplay.h"

extern "C"
{
#include "wand_head.h"
}

@interface ViewController : UIViewController {
    long _score;
    int _num;
    game _game;
    int _bell;
    bool _busy;
}

@property (strong, nonatomic) IBOutlet UILabel *text;
- (IBAction)next:(id)sender;
- (IBAction)previous:(id)sender;
- (IBAction)up:(id)sender;
- (IBAction)left:(id)sender;
- (IBAction)right:(id)sender;
- (IBAction)down:(id)sender;
@property (nonatomic, strong) GCController *controller;
- (IBAction)stay:(id)sender;
@property (nonatomic, retain) SimpleTextDisplay *display;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *scoreLabel;
@property (strong, nonatomic) IBOutlet UILabel *diamondsLabel;
@property (strong, nonatomic) IBOutlet UILabel *maxMovesLabel;
@property (strong, nonatomic) IBOutlet UILabel *monsterLabel;
@property (strong, nonatomic) IBOutlet UILabel *screenNumberLabel;

@end
