//
//  ViewController.m
//  Text Wanderer
//
//  Created by Andrew Wallace on 4/29/17.
//  Copyright © 2017 Teleportaloo. All rights reserved.
//

#import "ViewController.h"
extern "C"
{
    #include "wand_head.h"
}

@interface ViewController ()

@end

@implementation ViewController

-(void)initScreen
{
    int maxmoves = 0;
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"screen" ofType:@"1"];
    
    NSString *partialPath = [filePath substringToIndex:filePath.length-1];
    
    _game.finished = 0;
    
    if (rscreen(_num,&maxmoves, [partialPath cStringUsingEncoding:NSUTF8StringEncoding]))
    {
        strcpy(_game.howdead,"a non-existant screen");
    }
    else
    {
        initscreen(&_num, &_score, &_bell, maxmoves, (char*)"kjhl", (game*)&_game);
    }
}



- (void)moved:(NSString *)howDead
{
    if (howDead !=nil)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"You are dead."
                                                                       message:[NSString stringWithFormat:@"You were killed by %@", howDead]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) { [self initScreen];}];
        
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else if (_game.finished)
    {
        _num++;
        [self initScreen];
    }
    
    _busy = NO;
}

-(void)makeMove:(char)key
{
    if (_busy)
    {
        // NSLog(@"busy");
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        self->_busy = TRUE;
        
        char *howDead = onemove(&self->_num, &self->_score, &self->_bell, (char*)"kjhl", (game*)&self->_game, key);
        
        NSString *dead = nil;
        
        if (howDead)
        {
            dead = [NSString stringWithUTF8String:howDead];
        }
        [self performSelectorOnMainThread:@selector(moved:) withObject:dead waitUntilDone:NO];
    });
}

#define BUTTON_BOUNCE -0.2

-(NSDate *)keyStroke:(char)ch last:(NSDate *)date value:(float)value pressed:(bool)pressed
{
//    NSLog(@"%c %f %f %d\n",ch, [date timeIntervalSinceNow], value, pressed);
    
    if (pressed && (date==nil || [date timeIntervalSinceNow] < BUTTON_BOUNCE))
    {
        [self makeMove:ch];
        return [NSDate date];
    }
    
    return date;

}


-(bool)setupControler
{
    NSArray *controllers = [GCController controllers];
    
    if (controllers != nil && controllers.count > 0)
    {
        
        self.controller = controllers[0];
        //4
        if (self.controller.extendedGamepad) {
            
            __weak typeof(self) weakSelf = self;
            __block NSDate *depressedDate = nil;
            

            [self.controller.extendedGamepad.dpad.up  setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                depressedDate = [weakSelf keyStroke:'k' last:depressedDate value:value pressed:pressed];
            }];
            [self.controller.extendedGamepad.dpad.down setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                depressedDate = [weakSelf keyStroke:'j' last:depressedDate value:value pressed:pressed];
            }];
            
            
            [self.controller.extendedGamepad.dpad.left setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                depressedDate = [weakSelf keyStroke:'h' last:depressedDate value:value pressed:pressed];
            }];
            
            [self.controller.extendedGamepad.dpad.right setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                depressedDate = [weakSelf keyStroke:'l' last:depressedDate value:value pressed:pressed];
            }];
            
            
            [self.controller setControllerPausedHandler: ^(GCController *controller)
            {
                depressedDate = [weakSelf keyStroke:' ' last:depressedDate value:0.0 pressed:YES];
            }];
            
            [self.controller.extendedGamepad.buttonB setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                if (pressed && (depressedDate==nil || [depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE))
                {
                    depressedDate = [NSDate date];
                    [self next:nil];
                }
            }];
            
            [self.controller.extendedGamepad.buttonX setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                if (pressed && (depressedDate==nil || [depressedDate timeIntervalSinceNow] < BUTTON_BOUNCE))
                {
                    depressedDate = [NSDate date];
                    [self previous:nil];
                }
            }];
            
            [self.controller.extendedGamepad.buttonA setValueChangedHandler:^(GCControllerButtonInput *button, float value, BOOL pressed) {
                depressedDate = [weakSelf keyStroke:'q' last:depressedDate value:0.0 pressed:YES];
            }];
            
            
        }
        return YES;
    }
    return NO;
}


- (void)controllerDiscovered:(NSNotification *)connectedNotification {
    
    [self setupControler];
}

- (void)toggleHardwareController:(BOOL)useHardware {
    
    if (useHardware) {
        if (![self setupControler])
        {
            //7
            if ([[GCController controllers] count] == 0) {
                [GCController startWirelessControllerDiscoveryWithCompletionHandler:nil];
                
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(controllerDiscovered:)
                                                             name:GCControllerDidConnectNotification
                                                           object:nil];
            }
        }
    } else {
        self.controller = nil;
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    [self toggleHardwareController:YES];
    
    _num = 1;
    
    self.display = [[SimpleTextDisplay alloc] init];
    self.display.mainLabel = self.text;
    self.display.scoreLabel = self.scoreLabel;
    self.display.diamondsLabel = self.diamondsLabel;
    self.display.maxMovesLabel = self.maxMovesLabel;
    self.display.monsterLabel = self.monsterLabel;
    self.display.nameLabel = self.nameLabel;
    self.display.screenNumberLabel = self.screenNumberLabel;
    
    
    
    memset(&_game, sizeof(_game), 0);
    
    [self initScreen];
  
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)startOver:(id)sender {
    [self makeMove:'q'];
}

- (IBAction)next:(id)sender {
    _num++;
    [self initScreen];
}

- (IBAction)previous:(id)sender {
    if (_num >1)
    {
        _num--;
        [self initScreen];
    }
}

- (IBAction)up:(id)sender {
    [self makeMove:'k'];
}

- (IBAction)left:(id)sender {
    [self makeMove:'h'];
}

- (IBAction)right:(id)sender {
    [self makeMove:'l'];
}

- (IBAction)down:(id)sender {
     [self makeMove:'j'];
}

- (IBAction)stay:(id)sender {
    [self makeMove:' '];
}
@end
