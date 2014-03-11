//
//  FDPickScene.m
//  FireflyGame
//
//  Created by Denis Bohm on 10/21/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDPickLayout.h"
#import "FDPickScene.h"

#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDFireflyIceChannelBLE.h>
#import <FireflyDevice/FDHardwareId.h>

#import <CoreBluetooth/CoreBluetooth.h>

@interface FDDeviceNode : SKNode

@property SKEmitterNode *selected;
@property SKEmitterNode *closest;
@property CGRect calculatedFrame;
@property SKSpriteNode *sprite;
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

@property NSSet *imageNames;

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
        _imageNames = [NSSet setWithArray:@[@"firefly-black", @"firefly-blue", @"firefly-green", @"firefly-pink", @"firefly-yellow"]];
        
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

- (double)blendFactorForSignalStrength:(double)strength
{
    return 0.0;
}

- (void)updateDevices:(NSArray *)fireflyIces
{
    FDPickLayout *layout = [[FDPickLayout alloc] init:self.frame.size cellSize:CGSizeMake(50.0f, 72.0f) cellSpace:CGSizeMake(8.0f, 8.0f)];
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
            
            NSString *imageName = [NSString stringWithFormat:@"firefly-%@", [name lowercaseString]];
            if (![_imageNames containsObject:imageName]) {
                imageName = @"firefly-orange";
            }
            SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:imageName];
            sprite.color = [SKColor blackColor];
            sprite.xScale = 1.0;
            sprite.yScale = 1.0;
            [node addChild:sprite];
            node.sprite = sprite;
            
            SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
            label.text = name;
            label.fontSize = 12;
            label.color = [UIColor redColor];
            label.position = CGPointMake(0, -(12 + sprite.frame.size.height / 2.0f));
            label.color = [SKColor blackColor];
            [node addChild:label];
            node.label = label;
            
            [self addChild:node];
            node.calculatedFrame = [node calculateAccumulatedFrame];
            _spriteByIdentifier[identifier] = node;
        }
        node.position = [layout nextPoint];
        node.label.text = name;
        
        double strength = [channel.peripheral.RSSI doubleValue];
        if (strength > closestStrength) {
            closestStrength = strength;
            closestNode = node;
        }
        double blendFactor = [self blendFactorForSignalStrength:strength];
        node.sprite.colorBlendFactor = blendFactor;
        node.label.colorBlendFactor = blendFactor;
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

- (FDDeviceNode *)nodeTouched:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    for (SKNode *node in self.children) {
        CGPoint location = [touch locationInNode:node];
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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self changeTouchedNode:[self nodeTouched:touches withEvent:event]];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    FDDeviceNode *node = [self nodeTouched:touches withEvent:event];
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

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    FDDeviceNode *node = _touchedNode;
    [self touchesCancelled:touches withEvent:event];
    
    if (node != nil) {
        [_delegate pickSceneChoose:self fireflyIce:node.fireflyIce];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self changeTouchedNode:nil];
}

- (void)update:(CFTimeInterval)currentTime
{
    /* Called before each frame is rendered */
}

@end
