//
//  TouchableSprite.h
//
//  Created by Michał Zaborowski on 05.11.2012.
//  Copyright 2012 whitecode Michał Zaborowski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"


@interface CCTouchableSprite : CCSprite
@property (nonatomic, retain) NSNumber *touchPriority;
@property (nonatomic, assign) BOOL debugDraw;
@property (nonatomic, assign) BOOL isTouchEnabled;

#if NS_BLOCKS_AVAILABLE
- (void)setTouchBeganBlock:(BOOL(^)(UITouch *touch, UIEvent *event))beganBlock;
- (void)setTouchEndedBlock:(void(^)(UITouch *touch, UIEvent *event))endBlock;
- (void)setTouchCencelledBlock:(void(^)(UITouch *touch, UIEvent *event))cancelledBlock;
- (void)setTouchMovedBlock:(void(^)(UITouch *touch, UIEvent *event))movedBlock;

- (void)setTouchBlock:(void(^)(CCTouchableSprite *sprite))block;
#endif

- (void)setTouchTarget:(id)target action:(SEL)action;


@end
