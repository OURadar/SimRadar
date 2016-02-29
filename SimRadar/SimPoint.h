//
//  SimPoint.h
//  SimRadar
//
//  Created by Boon Leng Cheong on 11/11/13.
//  Copyright (c) 2013 Boon Leng Cheong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "rs.h"

@protocol SimPointDelegate <NSObject>

- (void)timeAdvanced:(id)sender;

@optional

- (void)progressUpdated:(double)completionPercentage message:(NSString *)message;

@end


@interface SimPoint : NSObject {
	
	BOOL busy;
	id<SimPointDelegate> delegate;

	float az_deg;
    float el_deg;
	
@private
	
	RSHandle *S;

    ADMHandle *A;
    RCSHandle *R;
	LESHandle *L;
	
	int table_id;

    size_t returnCounts[RS_MAX_GPU_DEVICE];
    
    size_t nearest_thousand;
    size_t nearest_hundred;

    FILE *ori_fid;
}

@property (nonatomic, readonly) BOOL busy;
@property (nonatomic, assign) id<SimPointDelegate> delegate;
@property (nonatomic, readonly) NSInteger numberOfPoints;
@property (nonatomic, readonly, getter=azimuthInDegrees) float az_deg;
@property (nonatomic, readonly, getter=elevationInDegrees) float el_deg;

- (id)initWithDelegate:(id<SimPointDelegate>)newDelegate cglShareGroup:(CGLShareGroupObj)shareGroup;

- (BOOL)isPopulated;

- (void)shareVBOsWithGL:(GLuint [][8])vbos;
- (void)upload;
- (void)populate;
- (void)advanceTime;
- (void)advanceBeamPosition;
- (void)advanceTimeAndBeamPosition;
- (void)randomBeamPosition;
- (void)homeBeamPosition;
- (void)run;
//- (int)cycleScattererColorMode;
//- (int)cycleReverseScattererColorMode;
- (void)setScattererColorMode:(int)mode;

- (NSInteger)deviceCount;

- (cl_float4 *)points;
- (NSInteger)pointCount;
- (NSInteger)pointCountForDevice:(cl_uint)deviceId;

- (cl_float4 *)anchors;
- (NSInteger)anchorCount;

- (cl_float4 *)anchorLines;
- (NSInteger)anchorLineCount;

- (RSVolume)simulationDomain;

- (GLint)decreasePopulationForDebris:(const int)debrisId returnCounts:(GLint *)counts;
- (GLint)increasePopulationForDebris:(const int)debrisId returnCounts:(GLint *)counts;
- (GLint)populationForDebris:(const int)debrisId;
- (GLint)populationForDebris:(const int)debrisId forDevice:(const int)deviceId;

- (GLfloat)recommendedViewRange;

- (void)increaseDemoRange;
- (void)decreaseDemoRange;

@end
