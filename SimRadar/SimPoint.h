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
}

@property (nonatomic, readonly) BOOL busy;
@property (nonatomic, assign) id<SimPointDelegate> delegate;
@property (nonatomic, readonly) NSInteger numberOfPoints;
@property (nonatomic, readonly, getter=azimuthInDegrees) float az_deg;
@property (nonatomic, readonly, getter=elevationInDegrees) float el_deg;

- (void)shareVBOsWithGL:(GLuint [][8])vbos;
- (void)upload;
- (void)populate;
- (void)explode;
- (void)advanceTime;
- (void)advanceBeamPosition;
- (void)advanceTimeAndBeamPosition;
- (void)randomBeamPosition;
- (void)homeBeamPosition;
- (void)run;

- (cl_float4 *)points;
- (NSInteger)pointCount;
- (NSInteger)pointCountForDevice:(cl_uint)deviceId;

- (cl_float4 *)anchors;
- (NSInteger)anchorCount;

- (cl_float4 *)anchorLines;
- (NSInteger)anchorLineCount;

- (RSVolume)simulationDomain;

- (GLint)decreasePopulationForSpecies:(const int)speciesId;
- (GLint)increasePopulationForSpecies:(const int)speciesId;
- (GLint)populationForSpecies:(const int)speciesId;
- (GLint)populationForSpecies:(const int)speciesId forDevice:(const int)deviceId;

@end
