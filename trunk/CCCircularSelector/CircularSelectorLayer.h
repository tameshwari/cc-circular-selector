//
//  CircularSelectorLayer.h
//  PuzzlePack
//
//  Created by Manna01 on 10年9月10日.
//  Copyright 2010 Manna Soft. All rights reserved.
//

#define MAX_ANGULAR_VELOCITY    360.0f*2.5f

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import <math.h>

typedef enum{
    kCCCircularSelectorDecelerationModeLinear,
    kCCCircularSelectorDecelerationModeExponential
} CCCircularSelectionDecelerationMode;

@class CircularSelectorLayer;

@protocol CircularSelectorDelagateProtocol

-(void)dragBegan:(CircularSelectorLayer*)circularSelector;
-(void)dragEnded:(CircularSelectorLayer*)circularSelector;
-(void)rotationBegan:(CircularSelectorLayer*)circularSelector;
-(void)rotationEnded:(CircularSelectorLayer*)circularSelector;
-(void)selectionDidChange:(int)index circularSelector:(CircularSelectorLayer*)circularSelector;
-(void)selectionDidDecide:(int)index circularSelector:(CircularSelectorLayer*)circularSelector;

@end


@interface CircularSelectorLayer : CCLayer {
    NSObject<CircularSelectorDelagateProtocol> *delegate_;
    CGSize size_;
    BOOL isDragging_;
    int selectionIndex_;
    NSArray *choices_;
    float angle_;
    float frontScale_, backScale_;
    float frontY_, backY_;
    float maxX_;
    float rotationSpeedFactor_; // this factor affect the rate between drag distance and rotation angle
    
    float dTheta_;
    float dThetaThreshold_;
    float deceleration_;
    CCCircularSelectionDecelerationMode decelerationMode_;
    // for linear deceleration, deceleration unit is angle per squared second (several hundred)
    // for exponential deceleration, deceleration unit is fraction of angular velocity to be decelerated per second (0 < deceleration <= 1)
    
    float targetAngle_;
    
    NSTimeInterval lastAngleTime_;
    float lastAngle_;
    
    BOOL allowConfirmSelectByTap, allowRotateByTappingChoice, allowRotateByTappingSpace;
}


-(CircularSelectorLayer*)initWithChoices:(NSArray*)someChoices;
-(void)positionChoices;
-(float)getAngleForChoice:(int)index;
-(CGPoint)getXZCoordinatesWithAngle:(float)theta;
-(float)getTFromZ:(float)z;
-(float)getScaleFromT:(float)t;
-(float)getYFromT:(float)t;
-(float)correctAngle:(float)angle;
-(CCNode*)getSelectedNode;
-(void)rotateToIndex:(int)index;

-(void)decelerate:(ccTime)dt;
-(void)rotateToTargetAngle:(ccTime)dt;
-(void)stopInertia;

@property (retain) NSObject<CircularSelectorDelagateProtocol> *delegate;
@property (readonly) int selectionIndex;
@property (readonly) NSArray *choices;

@property (readwrite) float frontScale, backScale;
@property (readwrite) float frontY, backY;
@property (readwrite) float maxX;

@property (assign) BOOL allowConfirmSelectByTap, allowRotateByTappingChoice, allowRotateByTappingSpace;

@property (assign) float deceleration;
@property (assign) CCCircularSelectionDecelerationMode decelerationMode;

@end
