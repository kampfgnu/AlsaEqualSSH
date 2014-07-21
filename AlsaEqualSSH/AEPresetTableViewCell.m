//
//  AEPresetTableViewCell.m
//  AlsaEqualSSH
//
//  Created by kampfgnu on 21/07/14.
//  Copyright (c) 2014 mongofamily. All rights reserved.
//

#import "AEPresetTableViewCell.h"

#import "AEPreset.h"
#import "AEPresetView.h"

@interface AEPresetTableViewCell ()
@property (nonatomic, strong) AEPresetView *presetView;
@end


@implementation AEPresetTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.presetView = [[AEPresetView alloc] initWithFrame:CGRectMake(0.f, 0.f, 50.f, 44.f)];
        _presetView.backgroundColor = [UIColor clearColor];
        [self addSubview:_presetView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _presetView.frameRight = self.frameRight - 10.f;
    _presetView.frameHeight = self.frameHeight - 10.f;
    [_presetView moveToCenterOfSuperviewVertically];
}

- (void)setPreset:(AEPreset *)preset {
    _preset = preset;
    
    self.textLabel.text = preset.name;
    _presetView.preset = preset;
}

@end
