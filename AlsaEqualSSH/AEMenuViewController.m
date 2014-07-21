//
//  AEMenuViewController.m
//  AlsaEqualSSH
//
//  Created by kampfgnu on 16/07/14.
//  Copyright (c) 2014 mongofamily. All rights reserved.
//

#import "AEMenuViewController.h"

#import "AEEqualizerViewController.h"
#import "AEHost.h"
#import "AEPreset.h"
#import "AEPresetTableViewCell.h"

#import <SWRevealViewController.h>

@interface AEMenuViewController ()
@property (nonatomic, strong) NSMutableArray *hosts;
@property (nonatomic, strong) NSMutableArray *presets;
@end


@implementation AEMenuViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.hosts = [NSMutableArray array];
        self.presets = [NSMutableArray array];
        
        NSData *hostData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"hosts" ofType:@"json"]];
        NSMutableArray *allHosts = [NSJSONSerialization
                                           JSONObjectWithData:hostData
                                           options:NSJSONReadingMutableContainers
                                           error:nil];
        
        for (NSDictionary *h in allHosts) {
            AEHost *newHost = [[AEHost alloc] init];
            newHost.hostname = h[@"hostname"];
            newHost.port = [h[@"port"] intValue];
            newHost.username = h[@"username"];
            newHost.password = h[@"password"];
            
            [_hosts addObject:newHost];
        }
        
        NSData *presetsData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"presets" ofType:@"json"]];
        NSMutableArray *allPresets = [NSJSONSerialization
                                      JSONObjectWithData:presetsData
                                      options:NSJSONReadingMutableContainers
                                      error:nil];
        
        for (NSDictionary *p in allPresets) {
            AEPreset *preset = [[AEPreset alloc] init];
            preset.name = p[@"name"];
            preset.values = p[@"values"];
            
            [_presets addObject:preset];
        }
        
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tableView.frameWidth = self.revealViewController.rearViewRevealWidth;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 24.f;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"hosts";
    }
    else if (section == 1) {
        return @"presets";
    }
    else {
        return @"other stuff to do";
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return _hosts.count;
    else if (section == 1) return _presets.count;
    else return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        static NSString *PresetCellIdentifier = @"PresetCell";
        AEPresetTableViewCell *cell = (AEPresetTableViewCell *)[tableView dequeueReusableCellWithIdentifier:PresetCellIdentifier];
        if (cell == nil) {
            cell = [[AEPresetTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:PresetCellIdentifier];
        }
        
        AEPreset *preset = _presets[indexPath.row];
        cell.preset = preset;
        [cell setNeedsDisplay];
        
        return cell;
    }
    else {
        static NSString *CellIdentifier = @"Cell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        if (indexPath.section == 0) {
            AEHost *host = _hosts[indexPath.row];
            cell.textLabel.text = [NSString stringWithFormat:@"connect to %@", host.hostname];
        }
        else if (indexPath.section == 2) {
            if (indexPath.row == 0) {
                cell.textLabel.text = @"show equalizer";
            }
            else if (indexPath.row == 1) {
                cell.textLabel.text = @"disconnect";
            }
        }
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        AEHost *host = _hosts[indexPath.row];
        
        [[self mainViewController] connectTo:host];
    }
    else if (indexPath.section == 1) {
        [[self mainViewController] setPreset:_presets[indexPath.row]];
    }
    else {
        if (indexPath.row == 1) {
            [[self mainViewController] disconnect];
        }
    }
    
    [self.revealViewController revealToggleAnimated:YES];
}

- (AEEqualizerViewController *)mainViewController {
    UINavigationController *nc = (UINavigationController *)self.revealViewController.frontViewController;
    return (AEEqualizerViewController *)nc.viewControllers[0];
}

@end
