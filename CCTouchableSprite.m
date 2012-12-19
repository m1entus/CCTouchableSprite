//
//  TouchableSprite.m
//
//  Created by Michał Zaborowski on 05.11.2012.
//  Copyright 2012 whitecode Michał Zaborowski. All rights reserved.
//

#import "CCTouchableSprite.h"

#define COCOS2D_V2 (COCOS2D_VERSION >= 0x00020000)

typedef BOOL(^CCSpriteTouchBegan)(UITouch *touch, UIEvent *event);
typedef void(^CCSpriteTouchEnded)(UITouch *touch, UIEvent *event);
typedef void(^CCSpriteTouchMoved)(UITouch *touch, UIEvent *event);
typedef void(^CCSpriteTouchCancelled)(UITouch *touch, UIEvent *event);
typedef void(^CCSpriteTouchBlock)(CCTouchableSprite *sprite);


@interface CCTouchableSprite()  <CCTargetedTouchDelegate>

@property (nonatomic,retain) NSInvocation *invocation;

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
@synthesize isTouched = _isTouched;
@synthesize debugDraw = _debugDraw;
@synthesize invocation = _invocation;
@synthesize isTouchEnabled = _isTouchEnabled;

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

- (void)setTouchBlock:(void(^)(CCTouchableSprite *sprite))block
{
    self.touchableBlock = block;
}
#endif

- (void)setTouchTarget:(id)target action:(SEL)action
{
    NSMethodSignature * sig = nil;
    
    if( target && action ) {
        sig = [target methodSignatureForSelector:action];
        
        if (self.invocation) {
            [_invocation release];
        }
        
        self.invocation = nil;
        self.invocation = [NSInvocation invocationWithMethodSignature:sig];
        [self.invocation setTarget:target];
        [self.invocation setSelector:action];
#if NS_BLOCKS_AVAILABLE
        if ([sig numberOfArguments] == 3)
#endif
			[self.invocation setArgument:&self atIndex:2];
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
    self.isTouchEnabled = NO;
    
    [_touchPriority release];
    _touchPriority = [touchPriority retain];
    
    self.isTouchEnabled = YES;
}

- (BOOL)isTouchEnabled
{
	return _isTouchEnabled;
}

- (void)setIsTouchEnabled:(BOOL)enabled
{
	if( _isTouchEnabled != enabled ) {
		_isTouchEnabled = enabled;
        if( enabled )
            [self registerWithTouchDispatcher];
        else 
#if COCOS2D_V2
            [[CCDirector sharedDirector] touchDispatcher];
#else
            [[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
#endif
            
	}
}

-(void) registerWithTouchDispatcher
{
#if COCOS2D_V2
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:[self.touchPriority integerValue] swallowsTouches:YES];
#else
    [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:[self.touchPriority integerValue] swallowsTouches:YES];
#endif
	
}

- (void)onEnter
{
    [super onEnter];
    
    self.isTouchEnabled = YES;
    
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    self.isTouched = YES;
    
#if NS_BLOCKS_AVAILABLE
    if (self.touchBegan) {
        return self.touchBegan(touch,event);
    }
#endif
    CGPoint location = [touch locationInView: [touch view]];
    CGPoint touchLocation = [[CCDirector sharedDirector]convertToGL:location];

    if (CGRectContainsPoint([self boundingBox], touchLocation)) {
        
#if NS_BLOCKS_AVAILABLE
        //changed behavior in iOS6, sender of block is nil, so invocation fails, executing block does work
        if(self.touchableBlock)
        {
            self.touchableBlock(self);
        }
        else if(self.invocation)
        {
            [self.invocation invoke];
        }
#else
        if(self.invocation)
        {
            [self.invocation invoke];
        }
#endif
        if (self.touchableBlock || self.invocation) {
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

- (void) draw {

    [super draw];
    
	if (self.debugDraw) {
#if COCOS2D_V2
        ccGLEnableVertexAttribs(kCCVertexAttribFlag_Color );
#else
        glDisable(GL_TEXTURE_2D);
        glDisableClientState(GL_COLOR_ARRAY);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
#endif
        
        if (self.isTouched) {
#if COCOS2D_V2
            ccColor4F color [4] = {255,255,0,50};
            glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_FLOAT, GL_FALSE, 0, color);
            ccDrawColor4B(255,255,0,50);
#else
            glColor4ub(255, 255, 0, 50);
#endif
        } else {
#if COCOS2D_V2
            ccColor4F color [4] = {0,255,0,50};
            glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_FLOAT, GL_FALSE, 0, color);
            ccDrawColor4B(0,255,0,50);
#else
            glColor4ub(0, 255, 0, 50);
#endif
        }
        glLineWidth(1);
        
        CGSize s = self.textureRect.size;
        CGPoint offsetPix = self.offsetPosition;
        CGPoint vertices[4] = {
            ccp(offsetPix.x,offsetPix.y), ccp(offsetPix.x+s.width,offsetPix.y),
            ccp(offsetPix.x+s.width,offsetPix.y+s.height), ccp(offsetPix.x,offsetPix.y+s.height)
        };
        ccDrawPoly(vertices, 4, YES);
#if !COCOS2D_V2
        glColor4ub(255,255,255,255);
        
        glEnable(GL_TEXTURE_2D);
        glEnableClientState(GL_COLOR_ARRAY);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
#endif
    }
    
}

- (void)onExit
{
    self.isTouchEnabled = NO;
    
    [super onExit];
    
}

- (void)dealloc
{

    [_invocation release];

#if NS_BLOCKS_AVAILABLE

    [_touchEnded release];
     _touchEnded = nil;

    [_touchBegan release];
    _touchBegan = nil;

    [_touchableBlock release];
     _touchableBlock = nil;

    [_touchCancelled release];
    _touchCancelled = nil;

    [_touchMoved release];
    _touchMoved = nil;
    
#endif
    
    [_touchPriority release];
    _touchPriority = nil;
	
    [super dealloc];
}


@end
