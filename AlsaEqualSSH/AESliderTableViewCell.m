//
//  AESliderTableViewCell.m
//  AlsaEqualSSH
//
//  Created by kampfgnu on 21/07/14.
//  Copyright (c) 2014 mongofamily. All rights reserved.
//

#import "AESliderTableViewCell.h"

#import "AEFrequency.h"

@interface AESliderTableViewCell ()
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UILabel *label;
@end


@implementation AESliderTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.label = [UILabel new];
        _label.font = [UIFont systemFontOfSize:11.f];
        _label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_label];

        self.slider = [UISlider new];
        _slider.minimumValue = 0.f;
        _slider.maximumValue = 100.f;
        [self addSubview:_slider];
        __weak typeof(self) weakSelf = self;
        [_slider bk_addEventHandler:^(UISlider *sender) {
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(sliderTableViewCellSliderTouchedUp:)]) {
                [weakSelf.delegate sliderTableViewCellSliderTouchedUp:weakSelf];
            }
        } forControlEvents:UIControlEventTouchUpInside];
        [_slider bk_addEventHandler:^(UISlider *sender) {
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(sliderTableViewCellSliderChanged:)]) {
                [weakSelf.delegate sliderTableViewCellSliderChanged:weakSelf];
            }
        } forControlEvents:UIControlEventValueChanged];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _label.frame = CGRectMake(0.f, 0.f, 30.f, self.frameHeight);
    _slider.frame = CGRectMake(_label.frameRight, 0.f, self.frameWidth - _label.frameWidth - 10.f, self.frameHeight);
}

- (void)setFrequency:(AEFrequency *)frequency {
    _frequency = frequency;
    
    _label.text = [NSString stringWithFormat:@"%i", _frequency.value];
    _slider.value = _frequency.value;
}


@end
