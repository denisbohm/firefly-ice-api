//
//  FDPickScene.m
//  FireflyGame
//
//  Created by Denis Bohm on 10/21/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDPickScene.h"

#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDFireflyIceChannelBLE.h>
#import <FireflyDevice/FDHardwareId.h>

#import <IOBluetooth/IOBluetooth.h>

@interface FDDeviceNode : SKNode

@property SKEmitterNode *selected;
@property SKEmitterNode *closest;
@property CGRect calculatedFrame;
@property SKLabelNode *label;

@property FDFireflyIce *fireflyIce;

@end

@implementation FDDeviceNode

- (CGRect)frame
{
    return _calculatedFrame;
}

@end

@interface FDPickScene ()

@property SKLabelNode *searchingLabel;

@property NSMutableDictionary *spriteByIdentifier;

@property CGFloat x;
@property CGFloat y;
@property CGFloat scale;

@property FDDeviceNode *closestNode;
@property FDDeviceNode *touchedNode;

@end

@implementation FDPickScene

- (id)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size]) {
        _spriteByIdentifier = [NSMutableDictionary dictionary];
        
        _x = CGRectGetMidX(self.frame);
        _y = CGRectGetHeight(self.frame) - 75;
        _scale = 0.20;

        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        
        _searchingLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        _searchingLabel.text = @"Searching...";
        _searchingLabel.fontSize = 30;
        _searchingLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        [_searchingLabel runAction:[SKAction repeatActionForever:[SKAction sequence:@[
                                                        [SKAction scaleTo:1.2 duration:0.5],
                                                        [SKAction scaleTo:1.0 duration:0.5],
         ]]]];
        [self addChild:_searchingLabel];
    }
    return self;
}

- (NSString *)shortName:(NSString *)name
{
    NSRange range = [name rangeOfString:@" " options: NSBackwardsSearch];
    return [name substringToIndex:range.location];
}

- (void)updateDevices:(NSArray *)fireflyIces
{
    double closestStrength = -1000;
    FDDeviceNode *closestNode = nil;
    for (FDFireflyIce *fireflyIce in fireflyIces) {
        _searchingLabel.hidden = YES;
        FDFireflyIceChannelBLE *channel = fireflyIce.channels[@"BLE"];
        NSString *identifier = [channel.peripheral.identifier UUIDString];

        NSString *name = [self shortName:fireflyIce.name];
        FDDeviceNode *node = _spriteByIdentifier[identifier];
        if (node == nil) {
            node = [[FDDeviceNode alloc] init];
            node.fireflyIce = fireflyIce;
            node.position = CGPointMake(_x, _y);
            
            NSString *selectedPath = [[NSBundle mainBundle] pathForResource:@"FDSelectedEmitter" ofType:@"sks"];
            SKEmitterNode *selected = [NSKeyedUnarchiver unarchiveObjectWithFile:selectedPath];
            selected.xScale = _scale;
            selected.yScale = _scale;
            selected.hidden = YES;
            node.selected = selected;
            [node addChild:selected];
            
            NSString *closestPath = [[NSBundle mainBundle] pathForResource:@"FDClosestEmitter" ofType:@"sks"];
            SKEmitterNode *closest = [NSKeyedUnarchiver unarchiveObjectWithFile:closestPath];
            closest.xScale = _scale;
            closest.yScale = _scale;
            closest.hidden = YES;
            node.closest = closest;
            [node addChild:closest];
            
            SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"firefly-green"];
            sprite.xScale = _scale / 3.0;
            sprite.yScale = _scale / 3.0;
            [node addChild:sprite];
            
            SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
            label.text = name;
            label.fontSize = 12;
            label.color = [NSColor redColor];
            label.position = CGPointMake(0, -(12 + sprite.frame.size.height / 2.0f));
            [node addChild:label];
            node.label = label;
            
            [self addChild:node];
            node.calculatedFrame = [node calculateAccumulatedFrame];
            _spriteByIdentifier[identifier] = node;
            
            _y -= 24 + sprite.frame.size.height;
            _scale -= 0.04;
        }
        node.label.text = name;
        
        double strength = [channel.peripheral.RSSI doubleValue];
        if (strength > closestStrength) {
            closestStrength = strength;
            closestNode = node;
        }
    }
    
    if (_closestNode != closestNode) {
        if (_closestNode != nil) {
            _closestNode.closest.hidden = YES;
        }
        _closestNode = closestNode;
        if (_closestNode != nil) {
            _closestNode.closest.hidden = NO;
        }
    }
}

- (FDDeviceNode *)nodeTouched:(NSEvent *)event
{
    NSPoint location = [event locationInNode:self];
    for (SKNode *node in self.children) {
        if (![node isKindOfClass:[FDDeviceNode class]]) {
            continue;
        }
        CGRect frame = node.frame;
        if (CGRectContainsPoint(frame, location)) {
            FDDeviceNode *deviceNode = (FDDeviceNode *)node;
            return deviceNode;
        }
    }
    return nil;
}

- (void)changeTouchedNode:(FDDeviceNode *)touchedNode
{
    if (_touchedNode != nil) {
        _touchedNode.selected.hidden = YES;
    }
    _touchedNode = touchedNode;
    if (_touchedNode != nil) {
        _touchedNode.selected.hidden = NO;
    }
    [_delegate pickSceneIndicate:self fireflyIce:_touchedNode.fireflyIce];
}

- (void)mouseDown:(NSEvent *)event
{
    [self changeTouchedNode:[self nodeTouched:event]];
}

- (void)mouseDragged:(NSEvent *)event
{
    FDDeviceNode *node = [self nodeTouched:event];
    if (_touchedNode == nil) {
        if (node != nil) {
            [self changeTouchedNode:node];
        }
    } else {
        if (node == nil) {
            [self changeTouchedNode:node];
        } else {
            if (node != _touchedNode) {
                [self changeTouchedNode:node];
            }
        }
    }
}

- (void)mouseUp:(NSEvent *)event
{
    FDDeviceNode *node = _touchedNode;
    [self touchesCancelled:event];
    
    if (node != nil) {
        [_delegate pickSceneChoose:self fireflyIce:node.fireflyIce];
    }
}

- (void)touchesCancelled:(NSEvent *)event
{
    [self changeTouchedNode:nil];
}

- (void)update:(CFTimeInterval)currentTime
{
    /* Called before each frame is rendered */
}

@end
