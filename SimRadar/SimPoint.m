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
    return [self initWithDelegate:nil];
}

- (id)initWithDelegate:(id<SimPointDelegate>)newDelegate
{
	self = [super init];
	if (self) {
        delegate = newDelegate;

        BOOL reportProgress = [delegate respondsToSelector:@selector(progressUpdated:message:)];

        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];

        if (reportProgress) {
            [delegate progressUpdated:2.0 message:@"Initializing ..."];
        }
        
        S = RS_init_with_path([resourcePath UTF8String], RS_METHOD_GPU, 2);
        if (S == NULL) {
            return nil;
        }
        
        if (S->vendors[0] == RS_GPU_VENDOR_INTEL) {
            if (S->num_cus[0] <= 16) {
                RS_set_density(S, 1.5f);
            } else if (S->num_cus[0] <= 24) {
                RS_set_density(S, 3.0f);
            }
        }

        // Copy out some convenient constants
        nearest_thousand = (size_t)ceilf(1000.0f / S->preferred_multiple) * S->preferred_multiple;
        nearest_hundred = (size_t)ceilf(100.0f / S->preferred_multiple) * S->preferred_multiple;
        
//		L = LES_init_with_config_path(LESConfigSuctionVortices, NULL);
        L = LES_init_with_config_path(LESConfigSuctionVorticesLarge, NULL);

        A = ADM_init_with_config_path(ADMConfigSquarePlate, NULL);

        R = RCS_init_with_config_path(RCSConfigLeaf, NULL);

        NSLog(@"LES @ %s", LES_data_path(L));
        NSLog(@"ADM @ %s", ADM_data_path(A));
        NSLog(@"RCS @ %s", RCS_data_path(R));
        
        if (A == NULL || L == NULL || S == NULL || S == NULL) {
            NSLog(@"Some error(s) in RS_init(), LES_init(), ADM_init() or RCS_init() occurred.");
            [delegate progressUpdated:3.0 message:@"LES / ADM / RCS table not found."];
            return nil;
        }
        
        if (reportProgress) {
            [delegate progressUpdated:3.0 message:[NSString stringWithFormat:@"LES @ %s", LES_data_path(L)]];
        }

		#ifdef DEBUG
		RS_set_verbosity(S, 3);
		#endif

        if (reportProgress) {
            [delegate progressUpdated:10.0 message:[NSString stringWithFormat:@"Configuring radar parameters ..."]];
        }

		RS_set_antenna_params(S, 1.0f, 44.5f);                // 1.0-deg, 44.5 dBi gain
		
        RS_set_tx_params(S, 30.0f * 2.0f / 3.0e8f, 10.0e3);   // Resolution in m, power in W

        NSLog(@"S->preferred_multiple = %d", (int)S->preferred_multiple);
        RS_set_debris_count(S, 1, 10000);
        RS_set_debris_count(S, 2, 500);
        RS_revise_debris_counts_to_gpu_preference(S);
        
        RS_set_prt(S, 1.0f / 60.0f);
        
        BOOL useLES = TRUE;
        
        RSBox box;
        if (useLES) {
            for (table_id = 0; table_id < RS_MAX_VEL_TABLES; table_id++) {
                if (reportProgress) {
                    [delegate progressUpdated:(10.0 + (double)table_id / RS_MAX_VEL_TABLES * 70.0)
                                      message:[NSString stringWithFormat:@"Loading LES table %d to GPU ...", table_id]];
                }
                LESTable *les = LES_get_frame(L, table_id);
                //LES_show_table_summary(les);
                RS_set_vel_data_to_LES_table(S, les);
            }
            box = RS_suggest_scan_doamin(S, 16);
        }
        
        ADMTable *adm = ADM_get_frame(A);

        RS_set_adm_data_to_ADM_table(S, adm);
        
        ADM_transform_scale(adm, 1.0f, 3.0f, 3.0f, 1.0f);
        RS_set_adm_data_to_ADM_table(S, adm);
        
        RS_set_adm_data_to_ADM_table(S, adm);

        if (reportProgress) {
            [delegate progressUpdated:90.0 message:@"ADM table"];
        }
        
        RCSTable *rcs = RCS_get_frame(R);

        RS_set_rcs_data_to_RCS_table(S, rcs);
        RS_set_rcs_data_to_RCS_table(S, rcs);
        RS_set_rcs_data_to_RCS_table(S, rcs);

        if (reportProgress) {
            [delegate progressUpdated:95.0 message:@"RCS table"];
        }

        if (useLES) {
            RS_set_scan_box(S,
                            box.origin.r, box.origin.r + box.size.r, 30.0f,   // Range
                            box.origin.a, box.origin.a + box.size.a, 1.0f,    // Azimuth
                            box.origin.e, box.origin.e + box.size.e, 1.0f);   // Elevation
        } else {
            RS_set_scan_box(S,
                            3.42e3, 4.18e3, 30.0f,                // Range
                            -7.0f, 7.0f, 1.0f,                    // Azimuth
                            0.0f, 12.0f, 1.0f);                   // Elevation

            cl_float4 vel = (cl_float4){0.0f, 0.0f, 0.0f, 0.0f};
            
            RS_set_vel_data_to_uniform(S, vel);
        }
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
    
    if ([delegate respondsToSelector:@selector(progressUpdated:message:)]) {
        [delegate progressUpdated:100.0f message:@"Ready"];
    }
}

- (void)advanceTime
{
	RS_advance_time(S);
//    RS_download_position_only(S);
//    RS_download(S);
//    RS_make_pulse(S);
//    RS_download_orientation_only(S);
    
//    unsigned long debris_ind;
//    
//    for (int i = 0; i < 1; i++) {
//        debris_ind = S->worker[0].species_global_offset + S->worker[0].species_origin[1] + i;
//        fwrite(&S->scat_ori[debris_ind], sizeof(cl_float4), 1, ori_fid);
//    }
    
}

- (void)advanceBeamPosition
{
	az_deg = fmodf(az_deg + 0.05f + 15.0f, 30.0f) - 15.0f;
//    az_deg = fmodf(az_deg + 0.2f + 45.0f, 90.0f) - 45.0f;
	RS_set_beam_pos(S, az_deg, el_deg);
    RS_make_pulse(S);
    RS_update_colors(S);
}

- (void)advanceTimeAndBeamPosition
{
    az_deg = fmodf(az_deg + 0.05f + 12.0f, 24.0f) - 12.0f;
	RS_set_beam_pos(S, az_deg, el_deg);
    RS_make_pulse(S);
    RS_update_colors(S);
	RS_advance_time(S);
}

- (void)randomBeamPosition
{
	az_deg = (float)rand() / RAND_MAX * 24.0f - 12.0f;
	RS_set_beam_pos(S, az_deg, el_deg);
	RS_update_colors(S);
}

- (void)homeBeamPosition
{
    az_deg = 0.0f;
    RS_set_beam_pos(S, az_deg, el_deg);
//    RS_update_colors_only(S);
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
	
	busy = true;
	
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
	//return S->domain;
    return RS_get_domain(S);
}

#pragma mark -
#pragma mark Simulation parameters

- (GLint)decreasePopulationForSpecies:(const int)speciesId returnCounts:(GLint *)counts
{
    if (speciesId == 0) {
        return -1;
    }
    size_t pop = RS_get_debris_count(S, speciesId);
    if (pop >= nearest_thousand) {
        pop -= nearest_thousand;
    } else if (pop >= nearest_hundred) {
        pop -= nearest_hundred;
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
    if (pop >= nearest_thousand && pop <= S->num_scats - nearest_thousand) {
        pop += nearest_thousand;
    } else {
        pop += nearest_hundred;
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

- (GLfloat)recommendedViewRange
{
    RSVolume v = RS_get_domain(S);
    return 1.2f * v.size.z;
}

@end
