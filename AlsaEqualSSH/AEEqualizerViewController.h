//
//  AEEqualizerViewController.h
//  AlsaEqualSSH
//
//  Created by kampfgnu on 16/07/14.
//  Copyright (c) 2014 mongofamily. All rights reserved.
//

@class AEHost;
@class AEPreset;

@interface AEEqualizerViewController : UITableViewController

- (void)connectTo:(AEHost *)host;
- (void)disconnect;
- (void)setPreset:(AEPreset *)preset;

@end
