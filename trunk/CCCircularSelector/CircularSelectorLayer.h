//
//  CircularSelectorLayer.h
//  PuzzlePack
//
//  Created by Tang Eric on 05/03/2011.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
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

-(void)rotationBegan:(CircularSelectorLayer*)circularSelector;
-(void)rotationEnded:(CircularSelectorLayer*)circularSelector;
-(void)selectionDidChange:(int)index circularSelector:(CircularSelectorLayer*)circularSelector;
-(void)selectionDidDecide:(int)index circularSelector:(CircularSelectorLayer*)circularSelector;

@end


@interface CircularSelectorLayer : CCLayer {
    NSObject<CircularSelectorDelagateProtocol> *delegate_;
    CGPoint center_;
    BOOL isDragging_;
    int selectionIndex_;
    NSArray *choices_;
    float angle_;
    float frontScale_, backScale_;
    float radiusX_, radiusY_;
    float rotationSpeedFactor_; // this factor affect the rate between drag distance and rotation angle
    
    // inertia related
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
-(CGPoint)getNormalizedXZCoordinatesWithAngle:(float)theta;
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

@property (readwrite) CGPoint center;

@property (readwrite) float frontScale, backScale;

@property (assign) BOOL allowConfirmSelectByTap, allowRotateByTappingChoice, allowRotateByTappingSpace;

@property (assign) float deceleration;
@property (assign) CCCircularSelectionDecelerationMode decelerationMode;

@end
