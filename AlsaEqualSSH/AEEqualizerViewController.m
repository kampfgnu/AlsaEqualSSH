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
#import "AEPreset.h"
#import "AESliderTableViewCell.h"

#import <SWRevealViewController.h>
#import <NMSSH.h>

typedef enum {
    CommandStateConnecting,
    CommandStateConnected,
    CommandStateGetSets,
    CommandStateSetsReceived
} CommandState;

@interface AEEqualizerViewController () <NMSSHSessionDelegate, NMSSHChannelDelegate, UITextViewDelegate, AESliderTableViewCellDelegate>
@property (nonatomic, strong) dispatch_queue_t sshQueue;
@property (nonatomic, strong) NMSSHSession *session;
@property (nonatomic, assign) CommandState commandState;
@property (nonatomic, strong) NSMutableArray *hertzControls;
@property (nonatomic, strong) AEHost *host;
@end


@implementation AEEqualizerViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.hertzControls = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Menu" style:UIBarButtonItemStylePlain target:self.revealViewController action:@selector(revealToggle:)];
    
    self.title = @"disconnected";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _hertzControls.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 24.f;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    AEFrequency *f = _hertzControls[section];
    
    return [f.hertz substringFromIndex:4];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    AESliderTableViewCell *cell = (AESliderTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[AESliderTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.delegate = self;
    }
    
    AEFrequency *f = _hertzControls[indexPath.section];
    cell.frequency = f;
    
    return cell;
}

- (AEMenuViewController *)menuViewController {
    return (AEMenuViewController *)self.revealViewController.rearViewController;
}

- (void)setPreset:(AEPreset *)preset {
    
    int counter = 0;
    for (NSNumber *n in preset.values) {
        AEFrequency *f = _hertzControls[counter];
        f.value = [n intValue];
        
        [self performCommand:[NSString stringWithFormat:@"amixer -D equal -q set '%@' %i", f.hertz, f.value]];
        
        counter++;
    }
    [self.tableView reloadData];
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark - ssh
////////////////////////////////////////////////////////////////////////

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

- (void)performCommand:(NSString *)command {
    dispatch_async(self.sshQueue, ^{
        NSError *error;
        [[self.session channel] write:[command stringByAppendingString:@"\n"] error:&error timeout:@10];
        if (error) {
            NSLog(@"error performing command: %@", error);
        }
    });
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

- (void)disconnect {
    if (self.session != nil && [self.session isConnected]) {
        [self.session disconnect];
    }
    self.commandState = CommandStateConnecting;
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark - parsing
////////////////////////////////////////////////////////////////////////

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
    
//    self.view.backgroundColor = [UIColor grayColor];
    if (_hertzControls.count == 10) {
        self.commandState = CommandStateSetsReceived;
        
        [self.tableView reloadData];
        
        self.title = @"connected";
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark - AESliderTableViewCellDelegate
////////////////////////////////////////////////////////////////////////

- (void)sliderTableViewCellSliderChanged:(AESliderTableViewCell *)sliderTableViewCell {
    sliderTableViewCell.label.text = [NSString stringWithFormat:@"%i", (int)sliderTableViewCell.slider.value];
}

- (void)sliderTableViewCellSliderTouchedUp:(AESliderTableViewCell *)sliderTableViewCell {
    AEFrequency *f = sliderTableViewCell.frequency;
    f.value = (int)sliderTableViewCell.slider.value;
    sliderTableViewCell.label.text = [NSString stringWithFormat:@"%i", f.value];
    
    [self performCommand:[NSString stringWithFormat:@"amixer -D equal -q set '%@' %i", f.hertz, f.value]];
}

@end
