//
//  AEEqualizerViewController.m
//  AlsaEqualSSH
//
//  Created by kampfgnu on 16/07/14.
//  Copyright (c) 2014 mongofamily. All rights reserved.
//

#import "AEEqualizerViewController.h"

#import "AEMenuViewController.h"
#import "AEFrequency.h"
#import "AEHost.h"

#import <SWRevealViewController.h>
#import <NMSSH.h>
#import <BlocksKit+UIKit.h>
#import <iOSHelper.h>

typedef enum {
    CommandStateConnecting,
    CommandStateConnected,
    CommandStateGetSets,
    CommandStateSetsReceived
} CommandState;

@interface AEEqualizerViewController () <NMSSHSessionDelegate, NMSSHChannelDelegate, UITextViewDelegate>
@property (nonatomic, strong) dispatch_queue_t sshQueue;
@property (nonatomic, strong) NMSSHSession *session;
@property (nonatomic, assign) dispatch_once_t onceToken;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, assign) CommandState commandState;
@property (nonatomic, strong) NSMutableArray *hertzControls;
@property (nonatomic, strong) NSMutableArray *hertzLabels;
@property (nonatomic, strong) NSMutableArray *hertzSliders;
@property (nonatomic, strong) NSMutableArray *hertzValues;
@property (nonatomic, assign) dispatch_once_t buildSliderOnceToken;
@property (nonatomic, strong) NSMutableArray *presets;
@property (nonatomic, strong) AEHost *host;
@end


@implementation AEEqualizerViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.hertzControls = [NSMutableArray array];
        self.hertzLabels = [NSMutableArray array];
        self.hertzSliders = [NSMutableArray array];
        self.hertzValues = [NSMutableArray array];
        self.presets = [NSMutableArray array];
        
        [_presets addObject:[NSArray arrayWithObjects:@(77), @(74), @(70), @(70), @(70), @(70), @(65), @(68), @(66), @(70), nil]];
        [_presets addObject:[NSArray arrayWithObjects:@(87), @(78), @(74), @(70), @(70), @(70), @(65), @(68), @(66), @(70), nil]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Menu" style:UIBarButtonItemStylePlain target:self.revealViewController action:@selector(revealToggle:)];
    
    [self buildSliders];
    
    self.title = @"disconnected";
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    for (int i = 0; i < 10; i++) {
        UILabel *hl = _hertzLabels[i];
        UISlider *s = _hertzSliders[i];
        UILabel *vl = _hertzValues[i];
        
        hl.frame = CGRectMake(10.f, (i+1)*50.f + 30.f, 80.f, 34.f);
        s.frameLeft = 80.f;
        s.frameWidth = self.view.frameWidth - 120.f;
        s.frameTop = (i+1)*50.f + 30.f;
        vl.frame = CGRectMake(s.frameRight, (i+1)*50.f + 30.f, 30.f, 34.f);
    }
}

- (AEMenuViewController *)menuViewController {
    return (AEMenuViewController *)self.revealViewController.rearViewController;
}

- (void)connectTo:(AEHost *)host {
    _host = host;
    
    [self disconnect];
    
    self.title = @"connecting";
    
//    [NMSSHLogger logger].logLevel = NMSSHLogLevelVerbose;
    _commandState = CommandStateConnecting;
    
    self.sshQueue = dispatch_queue_create("NMSSH.queue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(self.sshQueue, ^{
        self.session = [NMSSHSession connectToHost:_host.hostname port:_host.port withUsername:_host.username];
        //        self.session = [NMSSHSession connectToHost:@"192.168.0.14" port:2222 withUsername:@"kampfgnu"];
        self.session.delegate = self;
        
        if (!self.session.connected) {
            NSLog(@"connection error");
        }
        
        [self.session authenticateByPassword:_host.password];
        
        if (!self.session.authorized) {
            NSLog(@"Authentication error\n");
            
            self.title = @"Authentication error";
        }
        else {
            self.session.channel.delegate = self;
            self.session.channel.requestPty = YES;
            
            NSError *error;
            [self.session.channel startShell:&error];
            
            if (error) {
                NSLog(@"%@", error.localizedDescription);
                
                self.title = error.localizedDescription;
            }
        }
    });
}

- (void)disconnect {
    if (self.session != nil && [self.session isConnected]) {
        [self.session disconnect];
    }
    self.commandState = CommandStateConnecting;
}

- (void)setPreset:(int)index {
    NSArray *preset = _presets[index];
    
    int counter = 0;
    for (NSNumber *n in preset) {
        AEFrequency *f = _hertzControls[counter];
        f.value = [n intValue];
        
        [self updateUIAtIndex:counter sendValue:YES updateSlider:YES];
        counter++;
    }
}

- (void)channel:(NMSSHChannel *)channel didReadData:(NSString *)message {
    NSLog(@"%@", message);
    
    if ([message hasPrefix:[NSString stringWithFormat:@"%@@", _host.username]] && _commandState < CommandStateGetSets) {
        self.commandState = CommandStateGetSets;
        
        [self performCommand:@"amixer -D equal scontents"];
    }
    else if ([message containsString:@"Simple mixer control"] && _commandState == CommandStateGetSets) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [weakSelf parseSets:message];
        });
    }
}

- (void)channel:(NMSSHChannel *)channel didReadError:(NSString *)error {
    NSLog(@"%@", [NSString stringWithFormat:@"[ERROR] %@", error]);
}

- (void)channel:(NMSSHChannel *)channel didReadRawData:(NSData *)data {
    NSLog(@"did read raw data");
}

- (void)channelShellDidClose:(NMSSHChannel *)channel {
    NSLog(@"%@", @"\nShell closed\n");
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        weakSelf.title = @"disconnected";
    });
    
}

- (void)session:(NMSSHSession *)session didDisconnectWithError:(NSError *)error {
    NSLog(@"%@", [NSString stringWithFormat:@"\nDisconnected with error: %@", error.localizedDescription]);
}

- (void)parseSets:(NSString *)message {
    NSArray *comps = [message componentsSeparatedByString:@"Simple mixer control "];
    
    for (NSString *control in comps) {
        if ([control hasPrefix:@"'"]) {
            NSString *hertz = [control stringBetweenString:@"'" andString:@"'"];
            NSString *percentage = [control stringBetweenString:@"[" andString:@"%]"];
            
            AEFrequency *f = [[AEFrequency alloc] init];
            f.hertz = hertz;
            f.value = [percentage intValue];
            [_hertzControls addObject:f];
        }
    }
    
    self.view.backgroundColor = [UIColor grayColor];
    if (_hertzControls.count == 10) {
        self.commandState = CommandStateSetsReceived;

        for (int i = 0; i < _hertzControls.count; i++) {
            [self updateUIAtIndex:i sendValue:NO updateSlider:YES];
        }
        
        self.title = @"connected";
    }
}

- (void)updateUIAtIndex:(int)index sendValue:(BOOL)send updateSlider:(BOOL)updateSlider {
    AEFrequency *f = _hertzControls[index];
    UILabel *hl = _hertzLabels[index];
    UISlider *s = _hertzSliders[index];
    UILabel *vl = _hertzValues[index];
    
    hl.text = f.hertz;
    if (updateSlider) s.value = f.value;
    vl.text = [NSString stringWithFormat:@"%i", f.value];
    
    if (send) {
        [self performCommand:[NSString stringWithFormat:@"amixer -D equal -q set '%@' %i", f.hertz, f.value]];
    }
}

- (void)buildSliders {
    __weak typeof(self) weakSelf = self;
    for (int i = 0; i < 10; i++) {
        UILabel *hl = [UILabel new];
        hl.font = [UIFont systemFontOfSize:11.f];
        hl.frame = CGRectMake(10.f, i*50.f + 30.f, 80.f, 34.f);
        [self.view addSubview:hl];
        [_hertzLabels addObject:hl];
        
        UISlider *s = [UISlider new];
        s.minimumValue = 0.f;
        s.maximumValue = 100.f;
        s.frameLeft = 80.f;
        s.frameWidth = self.view.frameWidth - 120.f;
        s.frameTop = i*50.f + 30.f;
        s.tag = i;
        [s bk_addEventHandler:^(UISlider *sender) {
            int index = (int)sender.tag;
            AEFrequency *f = _hertzControls[index];
            f.value = (int)sender.value;
            
            [weakSelf updateUIAtIndex:index sendValue:YES updateSlider:NO];
        } forControlEvents:UIControlEventTouchUpInside];
        [s bk_addEventHandler:^(UISlider *sender) {
            NSUInteger index = sender.tag;
            UILabel *label = [weakSelf.hertzValues objectAtIndex:index];
            label.text = [NSString stringWithFormat:@"%i", (int)sender.value];
        } forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:s];
        [_hertzSliders addObject:s];
        
        UILabel *vl = [UILabel new];
        vl.font = [UIFont systemFontOfSize:11.f];
        vl.textAlignment = NSTextAlignmentCenter;
        vl.frame = CGRectMake(s.frameRight, i*50.f + 30.f, 30.f, 34.f);
        [self.view addSubview:vl];
        [_hertzValues addObject:vl];
    }
}

- (void)performCommand:(NSString *)command {
    dispatch_async(self.sshQueue, ^{
        NSError *error;
        [[self.session channel] write:[command stringByAppendingString:@"\n"] error:&error timeout:@10];
        if (error) {
            NSLog(@"error performing command: %@", error);
        }
    });
}

@end
