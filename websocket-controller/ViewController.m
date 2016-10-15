//
//  ViewController.m
//  websocket-controller
//
//  Created by Emmanuel Boidot on 10/15/16.
//  Copyright © 2016 Emmanuel Boidot. All rights reserved.
//

#import "ViewController.h"

#import "websocket_controller-Swift.h"

@interface ViewController () <MFLSwiftJoystickDelegate>

@property dispatch_source_t     _timer;

@property (weak) IBOutlet UITextField *serverIPTextField;
@property (weak) IBOutlet MFLSwiftJoystickImplementation *swiftJoystick;
@property (weak, nonatomic) IBOutlet UIButton *accelerateButton;
@property (weak, nonatomic) IBOutlet UIButton *decelerateButton;
@property (weak, nonatomic) IBOutlet UIButton *accelerationLabel;
@property (weak, nonatomic) IBOutlet UIButton *angleLabel;
@property (weak, nonatomic) IBOutlet UIButton *radiusLabel;
@property CGPoint playerSwiftOrigin;

// control tuning parameters
@property float timeoutInSeconds;
@property float accelerationIncrementPerTimeout;

// control inputs
@property float acceleration;
@property float angle;
@property float radius;

// communication
@property NSString *serverIPString;
@property WebSocket* _webSocket;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.swiftJoystick setupWithThumbAndBackgroundImages:[UIImage imageNamed:@"joy_thumb.png"]
                                                  bgImage:[UIImage imageNamed:@"stick_base.png"]];
    [self.swiftJoystick setDelegate:self];
    
    [self.serverIPTextField setDelegate:self];
    self.serverIPTextField.text = @"192.168.10.1:9002";
    
    self.acceleration = 0.0;
    self.timeoutInSeconds = 0.10;
    self.accelerationIncrementPerTimeout = 0.1;

    [self updateServerIP];
}
- (IBAction)serverIPTextFieldEntered:(id)sender {
    [self.serverIPTextField becomeFirstResponder];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.serverIPTextField resignFirstResponder];
    [self updateServerIP];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.serverIPTextField resignFirstResponder];
    [self updateServerIP];
    return NO;
}

- (IBAction)updateWebSocket:(id)sender {
    [self updateServerIP];
}

- (void) updateServerIP {
    self.serverIPString = [NSString stringWithFormat:@"ws://%@", self.serverIPTextField.text];
    [self openWebSocketConnection];
}

- (void) openWebSocketConnection {
    self._webSocket = [[WebSocket alloc] init:self.serverIPString];
    //self._webSocket.delegate = self;
    [self._webSocket open];
    NSAssert(self._webSocket.readyState == WebSocketReadyStateConnecting, @"WebSocket is not connecting");
}

- (void) updateLabels {
    NSString *s = [NSString stringWithFormat:@"Acceleration: %.2f",self.acceleration];
    [self.accelerationLabel setTitle:s forState:UIControlStateNormal];
    
    NSString *s2 = [NSString stringWithFormat:@"Angle: %.2f",self.angle];
    [self.angleLabel setTitle:s2 forState:UIControlStateNormal];
    
    NSString *s3 = [NSString stringWithFormat:@"Radius: %.2f",self.radius];
    [self.radiusLabel setTitle:s3 forState:UIControlStateNormal];
    
    NSString *msg = [NSString stringWithFormat:@"%.2f %.2f",self.acceleration,self.angle];
    NSLog(self.serverIPString);
    NSLog(@"acceleration, steering");
    [self._webSocket sendWithText:msg];
}

- (void)incrementAcceleration:(float)inc{
    self.acceleration += inc;
    if (self.acceleration > 1.0) {
        self.acceleration = 1.0;
    } else if (self.acceleration < -1.0) {
        self.acceleration = -1.0;
    }
    [self updateLabels];
}

- (void)loopIncrementAcceleration:(float)inc{
    if (!self._timer) {
        dispatch_queue_t queue = dispatch_get_main_queue();
        self._timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        // This is the number of seconds between each firing of the timer
        dispatch_source_set_timer(
                                  self._timer,
                                  dispatch_time(DISPATCH_TIME_NOW, self.timeoutInSeconds * NSEC_PER_SEC),
                                  self.timeoutInSeconds * NSEC_PER_SEC,
                                  0.10 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(self._timer, ^{
            // ***** LOOK HERE *****
            // This block will execute every time the timer fires.
            // Do any non-UI related work here so as not to block the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                // Do UI work on main thread
                if (inc>0){
                    NSLog(@"Look, Mom, I'm accelerating");
                } else {
                    NSLog(@"Look, Mom, I'm decelerating");
                }
                [self incrementAcceleration:inc];
            });
        });
    }
    
    dispatch_resume(self._timer);
}

- (IBAction)stopAccChange:(id)sender {
    NSLog(@"Look, Mom, I'm stopping");
    if (self._timer) {
        dispatch_source_cancel(self._timer);
        self._timer = nil;
        self.acceleration = 0.0;
    }
    [self updateLabels];
}

- (IBAction)accDown:(id)sender {
    [self loopIncrementAcceleration:self.accelerationIncrementPerTimeout];
}

- (IBAction)decDown:(id)sender {
    [self loopIncrementAcceleration:(-1.0*self.accelerationIncrementPerTimeout)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// update when Swift joystick has moved
- (void)joyStickDidUpdate:(CGPoint)movement
{
    [self setRadiusFromMovement:movement];
    [self setAngleFromMovement:movement];
    
    [self updateLabels];
}

- (void)setRadiusFromMovement:(CGPoint)movement
{
    self.radius = sqrt(movement.x*movement.x+movement.y*movement.y);
}

- (void)setAngleFromMovement:(CGPoint)movement
{
    if (movement.x < 0.000001 && movement.x > -0.000001){
        self.angle =  0.0;
    } else {
        self.angle = atan2(movement.x,fabs(movement.y));
    }
}


@end
