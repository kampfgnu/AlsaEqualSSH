//
//  AEPresetView.m
//  AlsaEqualSSH
//
//  Created by kampfgnu on 21/07/14.
//  Copyright (c) 2014 mongofamily. All rights reserved.
//

#import "AEPresetView.h"

#import "AEPreset.h"

@implementation AEPresetView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGFloat x = 0.f;
    CGFloat lineWidth = self.frameWidth/_preset.values.count;
    
    UIColor *oddColor = [UIColor darkGrayColor];
    UIColor *evenColor = [UIColor grayColor];
    for (int i = 0; i < _preset.values.count; i++) {
        NSNumber *value = _preset.values[i];
        
        for (int w = 0; w < lineWidth; w++) {
            [KGQuartzDrawing drawVerticalLineAtPosition:CGPointMake(x + w, self.frameHeight) height:-([value floatValue]/100.f)*self.frameHeight color:(i % 2 == 0 ? oddColor : evenColor)];
        }
        
        x += lineWidth;
    }
}

- (void)setPreset:(AEPreset *)preset {
    _preset = preset;
    
    [self setNeedsDisplay];
}

@end
