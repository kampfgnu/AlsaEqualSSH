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

#import <SWRevealViewController.h>

@interface AEMenuViewController ()
@property (nonatomic, strong) NSMutableArray *hosts;
@end


@implementation AEMenuViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.hosts = [NSMutableArray array];
        NSData *hostData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"hosts" ofType:@"json"]];

        NSError *error;
        NSMutableArray *allHosts = [NSJSONSerialization
                                           JSONObjectWithData:hostData
                                           options:NSJSONReadingMutableContainers
                                           error:&error];
        
        for (NSDictionary *h in allHosts) {
            AEHost *newHost = [[AEHost alloc] init];
            newHost.hostname = h[@"hostname"];
            newHost.port = [h[@"port"] intValue];
            newHost.username = h[@"username"];
            newHost.password = h[@"password"];
            
            [_hosts addObject:newHost];
        }
        
    }
    return self;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 24.f;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"hosts" : @"other stuff to do";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return _hosts.count;
    else return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.section == 0) {
        AEHost *host = _hosts[indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"connect to %@", host.hostname];
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"show equalizer";
        }
        else if (indexPath.row == 1) {
            cell.textLabel.text = @"disconnect";
        }
        else if (indexPath.row == 2) {
            cell.textLabel.text = @"send preset 1";
        }
        else if (indexPath.row == 3) {
            cell.textLabel.text = @"send preset 2";
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        AEHost *host = _hosts[indexPath.row];
        
        [[self mainViewController] connectTo:host];
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            [self.revealViewController revealToggleAnimated:YES];
        }
        else if (indexPath.row == 1) {
            [[self mainViewController] disconnect];
        }
        else if (indexPath.row == 2) {
            [[self mainViewController] setPreset:0];
        }
        else if (indexPath.row == 3) {
            [[self mainViewController] setPreset:1];
        }
    }
    
    if (indexPath.section == 0) {
        [self.revealViewController revealToggleAnimated:YES];
    }
    else if (indexPath.section == 1) {
        if (indexPath.row != 0) {
            [self.revealViewController revealToggleAnimated:YES];
        }
    }
}

- (AEEqualizerViewController *)mainViewController {
    UINavigationController *nc = (UINavigationController *)self.revealViewController.frontViewController;
    return (AEEqualizerViewController *)nc.viewControllers[0];
}

@end
