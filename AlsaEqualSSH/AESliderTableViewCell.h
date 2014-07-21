//
//  AESliderTableViewCell.h
//  AlsaEqualSSH
//
//  Created by kampfgnu on 21/07/14.
//  Copyright (c) 2014 mongofamily. All rights reserved.
//

@protocol AESliderTableViewCellDelegate;

@class AEFrequency;

@interface AESliderTableViewCell : UITableViewCell

@property (nonatomic, readonly) UISlider *slider;
@property (nonatomic, readonly) UILabel *label;
@property (nonatomic, strong) AEFrequency *frequency;
@property (nonatomic, unsafe_unretained) id<AESliderTableViewCellDelegate> delegate;

@end


@protocol AESliderTableViewCellDelegate <NSObject>
- (void)sliderTableViewCellSliderChanged:(AESliderTableViewCell *)sliderTableViewCell;
- (void)sliderTableViewCellSliderTouchedUp:(AESliderTableViewCell *)sliderTableViewCell;
@end