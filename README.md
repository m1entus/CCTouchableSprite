CCTouchableSprite
=================

Touchable CCSprite for cocos2d framework with Objective-C Blocks

## How to use:

``` objective-c
[xButton setTouchBlock:^(CCSprite *sprite) {
            CCAction *actionDown =
            [CCSequence actions:
             [CCEaseIn actionWithAction:[CCMoveTo actionWithDuration:1 position:ccp(0, 0)] rate:3],
             nil];
            
            [credits runAction:actionDown];
        }];
```

or

``` objective-c
[xButton setTouchTarget:self action:@selector(callbackMethod)];
```