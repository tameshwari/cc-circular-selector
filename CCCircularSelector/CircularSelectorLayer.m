//
//  CircularSelectorLayer.m
//  PuzzlePack
//
//  Created by Manna01 on 10年9月10日.
//  Copyright 2010 Manna Soft. All rights reserved.
//

#import "CircularSelectorLayer.h"

float degreeToRadian(float degree){
    return degree/180.0f*M_PI;
}

float radianToDegree(float radian){
    return radian/M_PI*180.0f;
}

@implementation CircularSelectorLayer

@synthesize delegate=delegate_;
@synthesize selectionIndex=selectionIndex_;
@synthesize choices=choices_;

// property with explicit setters
@synthesize frontScale=frontScale_, backScale=backScale_;
@synthesize frontY=frontY_, backY=backY_;
@synthesize maxX=maxX_;

@synthesize allowConfirmSelectByTap, allowRotateByTappingChoice, allowRotateByTappingSpace;

@synthesize deceleration=deceleration_;
@synthesize decelerationMode=decelerationMode_;

+(CircularSelectorLayer*)layerWithChoices:(NSArray*)someChoices{
    return [[[CircularSelectorLayer alloc] initWithChoices:someChoices] autorelease];
}

-(CircularSelectorLayer*)initWithChoices:(NSArray*)someChoices{
    CCNode *tempNode;
    NSMutableArray *tempChoices = [NSMutableArray arrayWithCapacity:0];
    if (self = [super init]) {
        for (id choice in someChoices) {
            if ([choice isKindOfClass:[CCNode class]]) {
                [tempChoices addObject:choice]; 
                [self addChild:choice];
            }else {
                tempNode = [CCNode node];
                [tempChoices addObject:tempNode];
                [self addChild:tempNode];
            }
        }
        if (tempChoices.count < 1) {
            NSLog(@"[CircularSelectorLayer initWithChoices] at least one choice should be provided");
            return nil;
        }
        choices_ = [[NSArray alloc] initWithArray:tempChoices];
        
        
        allowConfirmSelectByTap = YES;
        allowRotateByTappingChoice = YES;
        allowRotateByTappingSpace = YES;
        
        size_ = self.contentSize;
        isDragging_ = NO;
        selectionIndex_ = 0;
        
        angle_ = 0.0f;
        
        frontScale_ = 1.0f;
        backScale_ = 0.6f;
        
        frontY_ = 0.4f;
        backY_ = 0.7f;
        
        maxX_ = 0.7f;
        
        rotationSpeedFactor_ = 0.3f;
        
        // inertia
        dTheta_ = 0.0f;
        deceleration_ = 800.0f;
        dThetaThreshold_ = 50.0f;
        decelerationMode_ = kCCCircularSelectorDecelerationModeLinear;
        
        self.isTouchEnabled = YES; 
        
        [self positionChoices];
    }
    return self;
}

-(void)dealloc{
    [choices_ release];
    [super dealloc];
}

-(CCNode*)getSelectedNode{
    return [choices_ objectAtIndex:selectionIndex_];
}

-(void)rotateToIndex:(int)newIndex{
    dTheta_ = 360.0f*0.75f;
    targetAngle_ = [self correctAngle:-((float)newIndex/(float)choices_.count)*360.0f];
    if (delegate_ && [delegate_ respondsToSelector:@selector(rotationBegan:)]) {
        [delegate_ rotationBegan:self];
    }
    [self schedule:@selector(rotateToTargetAngle:)];
}

#pragma mark -

-(NSArray*)getSortedChoices{
    // sort choices by their z
    NSMutableArray *sortedChoices = [NSMutableArray arrayWithCapacity:choices_.count];
    int i, j;
    float z1, z2;
    BOOL inserted;
    for (i = 0; i < choices_.count; i++) {
        inserted = NO;
        for (j = 0; j < sortedChoices.count; j++) {
            z1 = [self getXZCoordinatesWithAngle:[self getAngleForChoice:i]].y;
            z2 = [self getXZCoordinatesWithAngle:[self getAngleForChoice:[[sortedChoices objectAtIndex:j] intValue]]].y;
            if (z1 < z2) {
                [sortedChoices insertObject:[NSNumber numberWithInt:i] atIndex:j];
                inserted = YES;
                break;
            }
        }
        if (!inserted) {
            [sortedChoices addObject:[NSNumber numberWithInt:i]];
        }
    }
    return [NSArray arrayWithArray:sortedChoices];
}

-(void)positionChoices{
    CCNode *choice;
    CGPoint xzPoint;
    NSArray *sortedChoices;
    float t;
    int i, j;
    for (i = 0; i < choices_.count; i++) {
        xzPoint = [self getXZCoordinatesWithAngle:[self getAngleForChoice:i]];
        t = [self getTFromZ:xzPoint.y];
        choice = [choices_ objectAtIndex:i];
        choice.anchorPoint = ccp(0.5f, 0.5f);
        choice.position = ccp(xzPoint.x * maxX_ * size_.width/2.0f + size_.width/2.0f, [self getYFromT:t]*size_.height);
        choice.scale = [self getScaleFromT:t];
    }
    
    
    sortedChoices = [self getSortedChoices];
    j = 0;
    for (i = 0; i < sortedChoices.count; i++) { // count the nodes with negative Z
        if ([self getXZCoordinatesWithAngle:[self getAngleForChoice:i]].y > 0) {
            j++;
        }
    }
    j = -1*j;
    for (i = 0; i < sortedChoices.count; i++) { // nodes with negative z in modeling space get negative z in node space
        [self reorderChild:[choices_ objectAtIndex:[[sortedChoices objectAtIndex:i] intValue]] z:j++];
    }
    if (selectionIndex_ != [[sortedChoices lastObject] intValue]) {
        selectionIndex_ = [[sortedChoices lastObject] intValue];
        if (delegate_ && [delegate_ respondsToSelector:@selector(selectionDidChange:circularSelector:)]) {
            [delegate_ selectionDidChange:selectionIndex_ circularSelector:self];
        }
    }
}

-(float)getAngleForChoice:(int)index{
    return angle_+(360.0f*index/choices_.count);
}

-(CGPoint)getXZCoordinatesWithAngle:(float)theta{
    // this method return x and z coordinates of the node
    return CGPointMake(sin((double)degreeToRadian(theta)), cos((double)degreeToRadian(theta)));
}

-(float)getTFromZ:(float)z{
    // t: 0.0 - 1.0 inclusive
    // 1.0 = front
    // 0.0 = back
    return (z - -1.0f)/(1.0f - -1.0f);
}

-(float)getScaleFromT:(float)t{
    return t*frontScale_ + (1.0f-t)*backScale_;
}

-(float)getYFromT:(float)t{
    return t*frontY_ + (1.0f-t)*backY_;
}

-(float)correctAngle:(float)angle{
    while (angle >= 360.0f) {
        angle -= 360.0f;
    }
    while (angle < 0) {
        angle += 360.0f;
    }
    return angle;
}

-(void)decelerate:(ccTime)dt{
    //NSLog(@"[CircularSelectorLayer decelerate:] dt: %f", dt);
    //NSLog(@"[CircularSelectorLayer decelerate:] deceleration: %f, dt: %f, dTheta: %f, ", deceleration_, dt, dTheta_);
    if (dt > 0.0f) {
        if (decelerationMode_ == kCCCircularSelectorDecelerationModeLinear) {
            if (deceleration_ > 0.0f) {
                if (dTheta_ > 0) {
                    if (dTheta_ > (deceleration_*dt)) {
                        dTheta_ -= (deceleration_*dt);
                    } else {
                        dTheta_ = 0.0f;
                    }
                } else {
                    if (dTheta_ < (deceleration_*dt)) {
                        dTheta_ += (deceleration_*dt);
                    } else {
                        dTheta_ = 0.0f;
                    }
                }
            } else {
                dTheta_ = 0.0f;
            }
        } else {
            if (deceleration_ > 0.0f && deceleration_ <= 1.0f) {
                dTheta_ *= pow((double)(1.0f-deceleration_), (double)dt);
            } else {
                dTheta_ = 0.0f;
            }
        }
        
        if (fabsf(dTheta_) < dThetaThreshold_) {
            dTheta_ = dThetaThreshold_;
            targetAngle_ = roundf(angle_/(360.0f/(float)choices_.count))*(360.0f/(float)choices_.count);
            [self unschedule:@selector(decelerate:)];
            [self schedule:@selector(rotateToTargetAngle:)];
        } else {
            angle_ = [self correctAngle:angle_+(dTheta_*dt)];
            [self positionChoices];
        }
    }
}

-(void)rotateToTargetAngle:(ccTime)dt{
    //NSLog(@"[CircularSelectorLayer rotateToTargetAngle:] dt: %f, targetAngle: %f, angle: %f, threshold*dt: %f", dt, targetAngle_, angle_, dThetaThreshold_*dt);
    targetAngle_ = [self correctAngle:targetAngle_];
    if (targetAngle_>angle_) {
        if (targetAngle_<angle_+180.0f) {
            // right
            dTheta_ = fabsf(dTheta_);
        } else {
            dTheta_ = -fabsf(dTheta_);
        }
    } else {
        if (targetAngle_>angle_-180.0f) {
            // right
            dTheta_ = -fabsf(dTheta_);
        } else {
            dTheta_ = fabsf(dTheta_);
        }
    }
    if (fabsf(targetAngle_-angle_) <= fabsf(dTheta_*dt)) {
        angle_ = targetAngle_;
        dTheta_ = 0.0f;
        [self unschedule:@selector(rotateToTargetAngle:)];
        if (delegate_ && [delegate_ respondsToSelector:@selector(rotationEnded:)]) {
            [delegate_ rotationEnded:self];
        }
    } else {
        angle_ += dTheta_*dt;
    }
    angle_ = [self correctAngle:angle_];
    [self positionChoices];
}

-(void)stopInertia{
    [self unschedule:@selector(decelerate:)];
    [self unschedule:@selector(rotateToTargetAngle:)];
    dTheta_ = 0.0f;
}

#pragma mark -
#pragma mark stage event


- (void)onEnter
{
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
	[super onEnter];
}

-(void)onEnterTransitionDidFinish{
    [super onEnterTransitionDidFinish];
}

- (void)onExit
{
	[[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
	[super onExit];
}

#pragma mark -
#pragma mark touch event


- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (CGRectContainsPoint(CGRectMake(0.0f, 0.0f, size_.width, size_.height), [self convertTouchToNodeSpace:touch])) {
        // this touch is on this layer
        [self stopInertia];
        lastAngle_ = angle_;
        lastAngleTime_ = [[NSDate date] timeIntervalSince1970];
        return YES;
    }else {
        return NO;
    }
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    isDragging_ = YES;
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    
    if (delegate_ && [delegate_ respondsToSelector:@selector(dragBegan:)]) {
        [delegate_ dragBegan:self];
    }
    if (delegate_ && [delegate_ respondsToSelector:@selector(rotationBegan:)]) {
        [delegate_ rotationBegan:self];
    }
    
    CGPoint touchPoint = [self convertTouchToNodeSpace:touch];
    CGPoint prevTouchPoint = [self convertToNodeSpace:[[CCDirector sharedDirector] convertToGL: [touch previousLocationInView:[CCDirector sharedDirector].openGLView]]];
    
    angle_ = angle_+(touchPoint.x - prevTouchPoint.x)*rotationSpeedFactor_;
    dTheta_ = (angle_ - lastAngle_)/(currentTime - lastAngleTime_);
    if (MAX_ANGULAR_VELOCITY > 0.0f && fabsf(dTheta_) > MAX_ANGULAR_VELOCITY) {
        if (dTheta_ > 0) {
            dTheta_ = MAX_ANGULAR_VELOCITY;
        } else {
            dTheta_ = -MAX_ANGULAR_VELOCITY;
        }

    }
    
    angle_ = [self correctAngle:angle_];
    [self positionChoices];
    lastAngle_ = angle_;
    lastAngleTime_ = currentTime;
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (isDragging_) {
        if (delegate_ && [delegate_ respondsToSelector:@selector(dragEnded:)]) {
            [delegate_ dragEnded:self];
        }
        [self schedule:@selector(decelerate:)];
        isDragging_ = NO;
        //[self schedule:@selector(snap:)];
    }else {
        [self tapped:touch];
    }
}

-(void)tapped:(UITouch*)touch{
    CCNode *currentChoice = [choices_ objectAtIndex:selectionIndex_];
    CCNode *tempChoice, *tempTopChoice;
    if (allowConfirmSelectByTap &&
        CGRectContainsPoint(CGRectMake(currentChoice.position.x-currentChoice.contentSize.width*currentChoice.scaleX/2.0f, 
                                       currentChoice.position.y-currentChoice.contentSize.height*currentChoice.scaleY/2.0f, 
                                       currentChoice.contentSize.width*currentChoice.scaleX,
                                       currentChoice.contentSize.height*currentChoice.scaleY)
                            , [self convertTouchToNodeSpace:touch])) {
        // the selected choice is tapped
        if (delegate_ && [delegate_ respondsToSelector:@selector(selectionDidDecide:circularSelector:)]) {
            [delegate_ selectionDidDecide:selectionIndex_ circularSelector:self];
        }
    } else {
        // other place is tapped
        tempTopChoice = nil;
        for (tempChoice in choices_) {
            if (tempChoice == currentChoice) {
                continue;
            }
            if (tempTopChoice && tempChoice.zOrder < tempTopChoice.zOrder) {
                continue;
            }
            if (CGRectContainsPoint(CGRectMake(tempChoice.position.x-tempChoice.contentSize.width*tempChoice.scaleX/2.0f, 
                                               tempChoice.position.y-tempChoice.contentSize.height*tempChoice.scaleY/2.0f, 
                                               tempChoice.contentSize.width*tempChoice.scaleX,
                                               tempChoice.contentSize.height*tempChoice.scaleY)
                                    , [self convertTouchToNodeSpace:touch])) {
                tempTopChoice = tempChoice;
            }
        }
        if (allowRotateByTappingChoice && tempTopChoice) { // a specific choice is tapped
            [self rotateToIndex:[choices_ indexOfObject:tempTopChoice]];
        } else if (allowRotateByTappingSpace) { // empty space tapped, rotate left / right
            if ([currentChoice convertTouchToNodeSpace:touch].x > currentChoice.contentSize.width*currentChoice.scaleX/2.0f) {
                [self rotateToIndex:(selectionIndex_+1)%choices_.count];
            } else if ([currentChoice convertTouchToNodeSpace:touch].x < -currentChoice.contentSize.width*currentChoice.scaleX/2.0f) {
                [self rotateToIndex:(selectionIndex_+choices_.count-1)%choices_.count];
            }
        }
    }
}

#pragma mark -
#pragma mark explicit setters

-(void)setFrontScale:(float)newFrontScale{
    frontScale_ = newFrontScale;
    [self positionChoices];
}

-(void)setBackScale:(float)newBackScale{
    backScale_ = newBackScale;
    [self positionChoices];
}

-(void)setFrontY:(float)newFrontY{
    frontY_ = newFrontY;
    [self positionChoices];
}

-(void)setBackY:(float)newBackY{
    backY_ = newBackY;
    [self positionChoices];
}

-(void)setMaxX:(float)newMaxX{
    maxX_ = newMaxX;
    [self positionChoices];
}

@end
