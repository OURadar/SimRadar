//
//  SimPoint.m
//  _radarsim
//
//  Created by Boon Leng Cheong on 11/11/13.
//  Copyright (c) 2013 Boon Leng Cheong. All rights reserved.
//

#import "SimPoint.h"

@interface SimPoint()
- (void)runInBackground;
@end

@implementation SimPoint

@synthesize busy;
@synthesize delegate;

#pragma mark -
#pragma Properties

@synthesize az_deg, el_deg;

- (NSInteger)numberOfPoints {
	return (NSInteger)S->num_scats;
}

#pragma mark -
#pragma mark Alloc / Memory

- (id)init
{
	self = [super init];
	if (self) {
        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];

        S = RS_init_with_path([resourcePath UTF8String], RS_METHOD_GPU, 2);
        
        if (S->num_cus[0] < 32) {
            RS_set_density(S, 3.0f);
        }

		//L = LES_init();
        
		L = LES_init_with_config_path(LESConfigSuctionVortices, [resourcePath UTF8String]);
        //L = LES_init_with_config_path(LESConfigTwoCell, [resourcePath UTF8String]);
        
        A = ADM_init_with_config_path(ADMConfigSquarePlate, [resourcePath UTF8String]);

        R = RCS_init_with_config_path(RCSConfigLeaf, [resourcePath UTF8String]);
        
        NSLog(@"LES @ %s", LES_data_path(L));
        NSLog(@"ADM @ %s", ADM_data_path(A));
        NSLog(@"RCS @ %s", RCS_data_path(R));
        
        if (A == NULL || L == NULL || S == NULL || S == NULL) {
            NSLog(@"Some error(s) in RS_init(), LES_init(), ADM_init() or RCS_init() occurred.");
            return nil;
        }
		
        
		#ifdef DEBUG
		RS_set_verbosity(S, 2);
		#endif

		RS_set_antenna_params(S, 1.0f, 44.5f);                // 1.0-deg, 44.5 dBi gain
		
        RS_set_tx_params(S, 30.0f * 2.0f / 3.0e8f, 10.0e3);   // Resolution in m, power in W
        
		RS_set_scan_box(S,
                        2.3e3, 2.8e3, 30.0f,                  // Range
                        -7.0f, 7.0f, 1.0f,                    // Azimuth
                        0.0f, 12.0f, 1.0f);                   // Elevation
	
//        RS_set_debris_count(S, 1, 4000);
//        RS_set_debris_count(S, 2, 2000);
//        RS_set_debris_count(S, 3, 500);

//        RS_set_debris_count(S, 1, (size_t)roundf(30000 / 64) * 64);
        
		//RS_set_physics_data_to_cube125(S);
		//RS_set_physics_data_to_cube27(S);
		
        RS_clear_wind_data(S);
        for (table_id = 0; table_id < RS_MAX_VEL_TABLES; table_id++) {
            LESTable *les = LES_get_frame(L, table_id);
            //LES_show_table_summary(les);
            RS_set_wind_data_to_LES_table(S, les);
        }
		
        ADMTable *adm = ADM_get_frame(A);
        //ADM_show_table_summary(adm);
        RS_clear_adm_data(S);
        RS_set_adm_data_to_ADM_table(S, adm);
        
        RCSTable *rcs = RCS_get_frame(R);
        RS_clear_rcs_data(S);
        RS_set_rcs_data_to_RCS_table(S, rcs);
        
        //RS_set_rcs_data_to_
        
		//RS_set_prt(S, 1.0f);
        //RS_set_prt(S, 0.5f);
        RS_set_prt(S, 0.03f);
		//RS_set_prt(S, 0.01f);

		az_deg = 0.0f;
        el_deg = 4.9f;
	}
	return self;
}

- (void)dealloc
{
	RS_free(S);
	LES_free(L);
	[super dealloc];
}

#pragma mark -
#pragma mark Simulation State

- (void)shareVBOsWithGL:(GLuint [][8])vbos
{
	RS_share_mem_with_vbo(S, 8, vbos);
}

- (void)upload
{
	RS_upload(S);
	S->sim_tic = 0;
	S->sim_toc = 0;
	S->sim_time = 0.0f;
}

- (void)populate
{
    RS_set_dsd_to_mp(S);
    
	RS_populate(S);

//    float x = S->domain.origin.x + 0.5f * S->domain.size.x;
//    float y = S->domain.origin.y + 0.5f * S->domain.size.y;
//    float r = sqrtf(x * x + y * y);
//    el_deg = atan2f(S->domain.origin.z + 0.5f * S->domain.size.z, r) * 180.0f / M_PI;
    el_deg = 5.0f;

    RS_set_beam_pos(S, az_deg, el_deg);
}

- (void)explode
{
	RS_explode(S);
}

- (void)advanceTime
{
	RS_advance_time(S);
	//RS_make_pulse(S);
}

- (void)advanceBeamPosition
{
	az_deg = fmodf(az_deg + 0.05f + 15.0f, 30.0f) - 15.0f;
//    az_deg = fmodf(az_deg + 0.2f + 45.0f, 90.0f) - 45.0f;
	RS_set_beam_pos(S, az_deg, el_deg);
	RS_update_colors_only(S);
}

- (void)advanceTimeAndBeamPosition
{
    az_deg = fmodf(az_deg + 0.05f + 12.0f, 24.0f) - 12.0f;
	RS_set_beam_pos(S, az_deg, el_deg);
	RS_advance_time(S);
}

- (void)randomBeamPosition
{
	az_deg = (float)rand() / RAND_MAX * 24.0f - 12.0f;
	RS_set_beam_pos(S, az_deg, el_deg);
	RS_update_colors_only(S);
}

- (void)homeBeamPosition
{
    az_deg = 0.0f;
    RS_set_beam_pos(S, az_deg, el_deg);
    RS_update_colors_only(S);
}

- (void)run
{
	[NSThread detachNewThreadSelector:@selector(runInBackground) toTarget:self withObject:nil];
}

#pragma mark -
#pragma mark Private Methods

- (void)runInBackground
{
	if (busy) {
		@autoreleasepool {
			NSLog(@"Simulation is already running...");
		}
		return;
	}
	
	busy = TRUE;
	
	@autoreleasepool {
		NSLog(@"Commencing simulation ...");
		while (busy) {
			RS_advance_time(S);
			
			[delegate timeAdvanced:self];
			
			usleep(10000);
		}
	}
}

#pragma mark -
#pragma Simulation Citizens

- (NSInteger)deviceCount
{
    return (NSInteger)S->num_workers;
}

- (cl_float4 *)points
{
	return S->scat_pos;
}

- (NSInteger)pointCount
{
	return (NSInteger)S->num_scats;
}

- (NSInteger)pointCountForDevice:(cl_uint)deviceId
{
    return (NSInteger)S->worker[deviceId].num_scats;
}

- (cl_float4 *)anchors
{
	return S->anchor_pos;
}

- (NSInteger)anchorCount
{
	return (NSInteger)S->num_anchors;
}

- (cl_float4 *)anchorLines
{
	return S->anchor_lines;
}

- (NSInteger)anchorLineCount
{
	return (NSInteger)S->num_anchor_lines;
}

- (RSVolume)simulationDomain
{
	return S->domain;
}

#pragma mark -
#pragma mark Simulation parameters

- (GLint)decreasePopulationForSpecies:(const int)speciesId returnCounts:(GLint *)counts
{
    if (speciesId == 0) {
        return -1;
    }
    size_t pop = RS_get_debris_count(S, speciesId);
    if (pop > 2000) {
        pop -= 1000;
    } else if (pop >= 100) {
        pop -= 100;
    } else if (pop == 0) {
        return -1;
    }
    RS_set_debris_count(S, speciesId, pop);
    
    RS_get_all_worker_debris_counts(S, speciesId, returnCounts);

    for (int i = 0; i < S->num_workers; i++) {
        counts[i] = (GLint)returnCounts[i];
    }
    
    return (GLuint)pop;
}

- (GLint)increasePopulationForSpecies:(const int)speciesId returnCounts:(GLint *)counts
{
    if (speciesId == 0) {
        return -1;
    }
    size_t pop = RS_get_debris_count(S, speciesId);
    if (pop >= 1000 && pop < S->num_scats - 1000) {
        pop += 1000;
    } else if (pop < S->num_scats - 100) {
        pop += 100;
    }
    RS_set_debris_count(S, speciesId, pop);

    RS_get_all_worker_debris_counts(S, speciesId, returnCounts);
    
    for (int i = 0; i < S->num_workers; i++) {
        counts[i] = (GLint)returnCounts[i];
    }

    return (GLuint)pop;
}

- (GLint)populationForSpecies:(const int)speciesId
{
    return (GLint)RS_get_debris_count(S, speciesId);
}

- (GLint)populationForSpecies:(const int)speciesId forDevice:(const int)deviceId
{
    return (GLint)RS_get_worker_debris_count(S, speciesId, deviceId);
}

@end
