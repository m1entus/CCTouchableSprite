//
//  TouchableSprite.m
//
//  Created by Michał Zaborowski on 05.11.2012.
//  Copyright 2012 whitecode Michał Zaborowski. All rights reserved.
//

#import "CCTouchableSprite.h"


typedef BOOL(^CCSpriteTouchBegan)(UITouch *touch, UIEvent *event);
typedef void(^CCSpriteTouchEnded)(UITouch *touch, UIEvent *event);
typedef void(^CCSpriteTouchMoved)(UITouch *touch, UIEvent *event);
typedef void(^CCSpriteTouchCancelled)(UITouch *touch, UIEvent *event);
typedef void(^CCSpriteTouchBlock)(CCSprite *sprite);


@interface CCTouchableSprite()  <CCTargetedTouchDelegate>
{
    NSInvocation *invocation_;
}
@property (nonatomic,assign) BOOL isTouchDelegateEnabled;
@property (nonatomic,assign) BOOL isTouched;

@property (nonatomic,copy) CCSpriteTouchBegan touchBegan;
@property (nonatomic,copy) CCSpriteTouchEnded touchEnded;
@property (nonatomic,copy) CCSpriteTouchMoved touchMoved;
@property (nonatomic,copy) CCSpriteTouchCancelled touchCancelled;
@property (nonatomic,copy) CCSpriteTouchBlock touchableBlock;
@end

@implementation CCTouchableSprite
@synthesize touchPriority = _touchPriority;
@synthesize touchBegan = _touchBegan;
@synthesize touchableBlock = _touchableBlock;
@synthesize touchEnded = _touchEnded;
@synthesize touchCancelled = _touchCancelled;
@synthesize touchMoved = _touchMoved;
@synthesize isTouchDelegateEnabled = _isTouchDelegateEnabled;
@synthesize isTouched = _isTouched;
@synthesize debugDraw = _debugDraw;

#if NS_BLOCKS_AVAILABLE

- (void)setTouchBeganBlock:(BOOL(^)(UITouch *touch, UIEvent *event))beganBlock
{
    self.touchBegan = beganBlock;
}

- (void)setTouchEndedBlock:(void(^)(UITouch *touch, UIEvent *event))endBlock
{
    self.touchEnded = endBlock;
}

- (void)setTouchCencelledBlock:(void(^)(UITouch *touch, UIEvent *event))cancelledBlock
{
    self.touchCancelled = cancelledBlock;
}

- (void)setTouchMovedBlock:(void(^)(UITouch *touch, UIEvent *event))movedBlock
{
    self.touchMoved = movedBlock;
}

- (void)setTouchBlock:(void(^)(CCSprite *sprite))block
{
    self.touchableBlock = block;
}
#endif

- (void)setTouchTarget:(id)target action:(SEL)action
{
    NSMethodSignature * sig = nil;
    
    if( target && action ) {
        sig = [target methodSignatureForSelector:action];
        
        invocation_ = nil;
        invocation_ = [NSInvocation invocationWithMethodSignature:sig];
        [invocation_ setTarget:target];
        [invocation_ setSelector:action];
#if NS_BLOCKS_AVAILABLE
        if ([sig numberOfArguments] == 3)
#endif
			[invocation_ setArgument:&self atIndex:2];
        
        [invocation_ retain];
    }
}

- (NSNumber *)priority
{
    if (_touchPriority == nil) {
        _touchPriority = [[NSNumber alloc] initWithInteger:0];
    }
    
    return _touchPriority;
}

- (void)setTouchPriority:(NSNumber *)touchPriority
{
    [_touchPriority release];
    _touchPriority = [touchPriority retain];
    
    if (self.isTouchDelegateEnabled) {
        [[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
        self.isTouchDelegateEnabled = NO;
    }
    
    [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:[self.touchPriority integerValue] swallowsTouches:YES];
    self.isTouchDelegateEnabled = YES;
}

- (CGRect)spriteRect
{
    return CGRectMake((self.offsetPositionInPixels.x +self.positionInPixels.x) / CC_CONTENT_SCALE_FACTOR(), (self.offsetPositionInPixels.y +self.positionInPixels.y) / CC_CONTENT_SCALE_FACTOR(), self.textureRect.size.width, self.textureRect.size.height);
}

- (void)onEnter
{
    [super onEnter];
    
    if (self.isTouchDelegateEnabled == NO) {
        [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:[self.priority integerValue] swallowsTouches:YES];
    }
    
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    self.isTouched = YES;
    
#if NS_BLOCKS_AVAILABLE
    if (self.touchBegan) {
        return self.touchBegan(touch,event);
    }
#endif

    CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    
    if (CGRectContainsPoint([self spriteRect], touchLocation)) {
        
#if NS_BLOCKS_AVAILABLE
        //changed behavior in iOS6, sender of block is nil, so invocation fails, executing block does work
        if(self.touchableBlock)
        {
            self.touchableBlock(self);
        }
        else if(invocation_)
        {
            [invocation_ invoke];
        }
#else
        if(invocation_)
        {
            [invocation_ invoke];
        }
#endif
        if (self.touchableBlock || invocation_) {
            return YES;
        }
    }


    return NO;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
#if NS_BLOCKS_AVAILABLE
    if (self.touchMoved) {
        self.touchMoved(touch,event);
    }
#endif
}

- (void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
#if NS_BLOCKS_AVAILABLE
    if (self.touchCancelled) {
        self.touchCancelled(touch,event);
    }
#endif
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    self.isTouched = NO;
    
#if NS_BLOCKS_AVAILABLE
    if (self.touchEnded) {
        self.touchEnded(touch,event);
    }
#endif
}

void ccFillPoly( CGPoint *poli, int points, BOOL closePolygon )
{
    // Default GL states: GL_TEXTURE_2D, GL_VERTEX_ARRAY, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
    // Needed states: GL_VERTEX_ARRAY,
    // Unneeded states: GL_TEXTURE_2D, GL_TEXTURE_COORD_ARRAY, GL_COLOR_ARRAY
    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);
    
    glVertexPointer(2, GL_FLOAT, 0, poli);
    if( closePolygon )
        glDrawArrays(GL_TRIANGLE_FAN, 0, points);
    else
        glDrawArrays(GL_LINE_STRIP, 0, points);
    
    // restore default state
    glEnableClientState(GL_COLOR_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnable(GL_TEXTURE_2D);
}

- (void) draw {

    [super draw];
    
	if (self.debugDraw) {
        glDisable(GL_TEXTURE_2D);
        glDisableClientState(GL_COLOR_ARRAY);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        
        if (self.isTouched) {
            glColor4ub(255, 255, 0, 50);
        } else {
            glColor4ub(0, 255, 0, 50);
        }
        glLineWidth(1);
        
        CGRect spriteRect = [self spriteRect];
        
        CGPoint vertices2[] = { ccp(spriteRect.origin.x, spriteRect.origin.y),
            ccp(spriteRect.origin.x, spriteRect.origin.y + spriteRect.size.height),
            ccp(spriteRect.origin.x + spriteRect.size.width, spriteRect.origin.y + spriteRect.size.height),
            ccp(spriteRect.origin.x + spriteRect.size.width, spriteRect.origin.y)
        };
        
        ccFillPoly( vertices2, 4, YES);
        
        glColor4ub(255,255,255,255);
        
        glEnable(GL_TEXTURE_2D);
        glEnableClientState(GL_COLOR_ARRAY);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    }
    
}

- (void)dealloc
{

    if (invocation_) {
        [invocation_ release];
    }

#if NS_BLOCKS_AVAILABLE
    if (_touchEnded) {
        [_touchEnded release];
        _touchEnded = nil;
    }
    if (_touchBegan) {
        [_touchBegan release];
        _touchBegan = nil;
    }
    if (_touchableBlock) {
        [_touchableBlock release];
        _touchableBlock = nil;
    }
    if (_touchCancelled) {
        [_touchCancelled release];
        _touchCancelled = nil;
    }
    if (_touchMoved) {
        [_touchMoved release];
        _touchMoved = nil;
    }
    
#endif
    
    [_touchPriority release];
    _touchPriority = nil;

    [[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
    [super dealloc];
}


@end
