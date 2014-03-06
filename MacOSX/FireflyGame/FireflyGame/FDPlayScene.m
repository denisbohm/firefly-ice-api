//
//  FDPlayScene.m
//  FireflyGame
//
//  Created by Denis Bohm on 10/21/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDPlayScene.h"

@interface FDPlayScene ()

@property NSUInteger playTime;
@property CFTimeInterval startTime;
@property NSUInteger remainingTime;
@property SKLabelNode *timerLabel;
@property CGRect syncProgressFrame;
@property SKShapeNode *syncProgress;
@property SKLabelNode *pointsLabel;
@property SKLabelNode *playLabel;
@property SKLabelNode *backLabel;

@end

@implementation FDPlayScene

- (id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        _playTime = 30;
        
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        
        _timerLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        [self updateTimerLabel:_playTime];
        _timerLabel.fontSize = 30;
        _timerLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        [self addChild:_timerLabel];
        
        _syncProgress = [SKShapeNode node];
        _syncProgressFrame = CGRectMake(10, CGRectGetMidY(self.frame) - 40, self.frame.size.width - 20, 20);
        CGPathRef path = CGPathCreateWithRoundedRect(_syncProgressFrame, 4, 4, nil);
        _syncProgress.path = path;
        CGPathRelease(path);
        _syncProgress.hidden = YES;
        [self addChild:_syncProgress];
        
        _pointsLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        _pointsLabel.text = @"You got points!";
        _pointsLabel.fontSize = 30;
        _pointsLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) - 40);
        _pointsLabel.hidden = YES;
        [self addChild:_pointsLabel];
        
        _playLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        _playLabel.text = @"Play!";
        _playLabel.fontSize = 30;
        _playLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMinY(self.frame) + 20);
        [self addChild:_playLabel];
        
        _backLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        _backLabel.text = @"<Back";
        _backLabel.fontSize = 30;
        _backLabel.position = CGPointMake(CGRectGetMinX(self.frame) + 50, CGRectGetMaxY(self.frame) - 40);
        [self addChild:_backLabel];
    }
    return self;
}

- (void)syncProgress:(double)progress
{
    _syncProgress.hidden = NO;
    CGRect frame = _syncProgressFrame;
    frame.size.width = (_syncProgressFrame.size.width - 10) * progress;
    frame.size.width += 10;
    CGPathRef path = CGPathCreateWithRoundedRect(frame, 4, 4, nil);
    _syncProgress.path = path;
    CGPathRelease(path);
}

- (void)syncComplete:(NSUInteger)points
{
    _syncProgress.hidden = YES;
    _pointsLabel.text = [NSString stringWithFormat:@"%lu points!", (unsigned long)points];
    _pointsLabel.hidden = NO;
    [self updateTimerLabel:_playTime];
}

- (void)syncError:(NSError *)error
{
}

- (void)syncAbort:(NSError *)error
{
    _syncProgress.hidden = YES;
    _pointsLabel.hidden = YES;
    [self updateTimerLabel:_playTime];
}

- (void)done
{
    _startTime = 0;
    _remainingTime = 0;
    [self updateTimerLabel:_remainingTime];
    
    [self syncProgress:0];
    [_delegate playSceneSync:self];
}

- (void)updateTimerLabel:(NSUInteger)timeInterval
{
    NSUInteger seconds = timeInterval % 60;
    NSUInteger minutes = timeInterval / 60;
    _timerLabel.text = [NSString stringWithFormat:@"%02lu:%02lu", (unsigned long)minutes, (unsigned long)seconds];
}

- (void)updateTimer:(CFTimeInterval)currentTime
{
    NSUInteger remaining = _playTime - (NSUInteger)(currentTime - _startTime);
    if (remaining == _remainingTime) {
        return;
    }
    _remainingTime = remaining;
    [self updateTimerLabel:_remainingTime];
    if (_remainingTime == 0) {
        [self done];
    }
}

- (void)play
{
    _pointsLabel.hidden = YES;
    _syncProgress.hidden = YES;
    _remainingTime = _playTime;
    _startTime = CFAbsoluteTimeGetCurrent();
    [self updateTimer:_startTime];
}

- (void)back
{
    _syncProgress.hidden = YES;
    _remainingTime = 0;
    _startTime = 0;
    [self updateTimerLabel:_playTime];

    [_delegate playSceneDone:self];
}

- (void)mouseDown:(NSEvent *)event
{
    NSPoint location = [event locationInNode:self];
    if (CGRectContainsPoint(_backLabel.frame, location)) {
        [self back];
        return;
    }
    if (CGRectContainsPoint(_playLabel.frame, location)) {
        if (_remainingTime == 0) {
            [self play];
        } else {
            [self done];
        }
        return;
    }
}

- (void)update:(CFTimeInterval)currentTime
{
    if (_startTime != 0) {
        [self updateTimer:CFAbsoluteTimeGetCurrent()];
    }
}

@end
