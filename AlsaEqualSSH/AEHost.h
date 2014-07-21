//
//  AEHost.h
//  AlsaEqualSSH
//
//  Created by kampfgnu on 21/07/14.
//  Copyright (c) 2014 mongofamily. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AEHost : NSObject

@property (nonatomic, strong) NSString *hostname;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, assign) int port;

@end
