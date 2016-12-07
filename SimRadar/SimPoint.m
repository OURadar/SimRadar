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
    return [self initWithDelegate:nil cglShareGroup:nil];
}

- (id)initWithDelegate:(id<SimPointDelegate>)newDelegate cglShareGroup:(CGLShareGroupObj)shareGroup
{
	self = [super init];
	if (self) {
        delegate = newDelegate;

        BOOL reportProgress = [delegate respondsToSelector:@selector(progressUpdated:message:)];

        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];

        if (reportProgress) {
            [delegate progressUpdated:2.0 message:@"Initializing ..."];
        }

        cl_context_properties property = (cl_context_properties)shareGroup;

        S = RS_init_with_path([resourcePath UTF8String], RS_METHOD_GPU, property, 2);
        if (S == NULL) {
            NSLog(@"Some error(s) in RS_init() occurred.");
            [delegate progressUpdated:3.0 message:@"LES / ADM / RCS table not found."];
            return nil;
        }

        // Special cases for laptop demos, etc.
        if (S->vendors[0] == RS_GPU_VENDOR_INTEL) {
            if (S->num_cus[0] <= 16) {
                RS_set_density(S, 1.2f);
            } else if (S->num_cus[0] <= 24) {
                RS_set_density(S, 1.6f);
            }
        } else {
            RS_set_density(S, 50.0f);
        }

        // Copy out some convenient constants
        nearest_thousand = (size_t)ceilf(1000.0f / S->preferred_multiple) * S->preferred_multiple;
        nearest_hundred = (size_t)ceilf(100.0f / S->preferred_multiple) * S->preferred_multiple;

		#ifdef DEBUG_HEAVY
		RS_set_verbosity(S, 3);
		#endif

        if (reportProgress) {
            [delegate progressUpdated:10.0 message:[NSString stringWithFormat:@"Configuring radar parameters ..."]];
        }
        
        RS_set_concept(S,
                       RSSimulationConceptDraggedBackground |
                       RSSimulationConceptBoundedParticleVelocity |
                       RSSimulationConceptUniformDSDScaledRCS);

		RS_set_antenna_params(S, 1.0f, 44.5f);                // 1.0-deg beamwidth, 44.5-dBi gain
		
        RS_set_tx_params(S, 30.0f * 2.0f / 3.0e8f, 10.0e3);   // Resolution in m, power in W

//        NSLog(@"S->preferred_multiple = %d", (int)S->preferred_multiple);
        RS_set_debris_count(S, 1, 10000);
        RS_set_debris_count(S, 2, 512);
        RS_set_debris_count(S, 3, 512);

        RS_revise_debris_counts_to_gpu_preference(S);

        RS_set_prt(S, 1.0f / 60.0f);
        
        BOOL useLES = TRUE;
        
        RSBox box;
        if (useLES) {
            box = RS_suggest_scan_domain(S, 16);
        }

        RS_set_obj_data_to_config(S, OBJConfigLeaf);
        RS_set_obj_data_to_config(S, OBJConfigMetalSheet);
        RS_set_obj_data_to_config(S, OBJConfigBrick);

        if (reportProgress) {
            [delegate progressUpdated:95.0 message:@"ADM / RCS table"];
        }
        if (useLES) {
            RS_set_scan_box(S,
                            box.origin.r, box.origin.r + box.size.r, 60.0f,   // Range
                            box.origin.a, box.origin.a + box.size.a, 1.0f,    // Azimuth
                            box.origin.e, box.origin.e + box.size.e, 1.0f);   // Elevation

            S->draw_mode.s1 = (cl_uint)(box.origin.r + 0.5 * box.size.r);
        } else {
            RS_set_scan_box(S,
                            3.42e3, 4.18e3, 30.0f,                // Range
                            -7.0f, 7.0f, 1.0f,                    // Azimuth
                            0.0f, 12.0f, 1.0f);                   // Elevation

            cl_float4 vel = (cl_float4){50.0f, 0.0f, 0.0f, 0.0f};
            
            RS_set_vel_data_to_uniform(S, vel);

            S->draw_mode.s1 = 5500;
        }

    }
	return self;
}

- (void)dealloc
{
	RS_free(S);

	[super dealloc];
}

#pragma mark -
#pragma mark Simulation State

- (BOOL)isPopulated
{
    return S->status & RSStatusDomainPopulated;
}

- (void)shareVBOsWithGL:(GLuint [][8])vbos
{
    RS_share_mem_with_vbo(S, 8, vbos);
}

- (void)upload
{
	RS_upload(S);
    S->draw_mode.s1 = S->sim_desc.s[RSSimulationDescriptionBoundOriginY] + 0.5f * S->sim_desc.s[RSSimulationDescriptionBoundSizeY];
}

- (void)populate
{
    RS_set_dsd_to_mp(S);
    
	RS_populate(S);

//    float x = S->domain.origin.x + 0.5f * S->domain.size.x;
//    float y = S->domain.origin.y + 0.5f * S->domain.size.y;
//    float r = sqrtf(x * x + y * y);
//    el_deg = atan2f(S->domain.origin.z + 0.5f * S->domain.size.z, r) * 180.0f / M_PI;

    az_deg = 4.0f;
    el_deg = 5.0f;

    RS_set_beam_pos(S, az_deg, el_deg);
    
    if ([delegate respondsToSelector:@selector(progressUpdated:message:)]) {
        [delegate progressUpdated:100.0f message:@"Ready"];
    }
}

- (void)advanceTime
{
	RS_advance_time(S);
    RS_update_colors(S);

    RS_make_pulse(S);

    RS_download_pulse_only(S);
//    NSLog(@"%.2f%+.2fi %.2f%+.2fi ...", S->pulse[0].s0, S->pulse[0].s1, S->pulse[1].s0, S->pulse[1].s1);
}

- (void)advanceBeamPosition
{
//	az_deg = fmodf(az_deg + 0.05f + 15.0f, 30.0f) - 15.0f;
    el_deg = fmodf(el_deg + 0.05f, 20.0f);
	RS_set_beam_pos(S, az_deg, el_deg);
//    RS_make_pulse(S);
    RS_update_colors(S);
}

- (void)advanceTimeAndBeamPosition
{
    //az_deg = fmodf(az_deg + 0.05f + 12.0f, 24.0f) - 12.0f;
    el_deg = fmodf(el_deg + 0.05f, 20.0f);
	RS_set_beam_pos(S, az_deg, el_deg);
    //RS_make_pulse(S);
    RS_update_colors(S);
	RS_advance_time(S);
}

- (void)randomBeamPosition
{
	az_deg = (float)rand() / RAND_MAX * 24.0f - 12.0f;
    el_deg = (float)rand() / RAND_MAX * 24.0f;
	RS_set_beam_pos(S, az_deg, el_deg);
	RS_update_colors(S);
}

- (void)homeBeamPosition
{
    az_deg = 0.0f;
    el_deg = 5.0f;
    RS_set_beam_pos(S, az_deg, el_deg);
    RS_update_colors(S);
}

- (void)run
{
	[NSThread detachNewThreadSelector:@selector(runInBackground) toTarget:self withObject:nil];
}

//- (int)cycleScattererColorMode {
//    S->draw_mode.s0 = S->draw_mode.s0 >= 6 ? 0 : S->draw_mode.s0 + 1;
//    return (int)S->draw_mode.s0;
//}
//
//- (int)cycleReverseScattererColorMode {
//    S->draw_mode.s0 = S->draw_mode.s0 <= 0 ? 6 : S->draw_mode.s0 - 1;
//    return (int)S->draw_mode.s0;
//}

- (void)setScattererColorMode:(int)mode
{
    int k;
    S->draw_mode.s0 = mode;
    switch (S->draw_mode.s0) {
        case 'S':
            tick_lab = [NSArray array];
            for (k = 0; k < S->dsd_count; k++) {
                tick_lab = [tick_lab arrayByAddingObject:[NSString stringWithFormat:@"%.2f", S->dsd_r[k] * 2000.0f]];
                tick_pos[k] = (k + 0.5f) / S->dsd_count;
            }
            strcpy(tick_title, "Drop Size (mm)");
            break;
        case 'A':
        case 'R':
            tick_lab = [NSArray arrayWithObjects:@"0.0", @"0.5", @"1.0", nil];
            tick_pos[0] = 0.00f;
            tick_pos[1] = 0.25f;
            tick_pos[2] = 0.50f;
            tick_pos[3] = 0.75f;
            tick_pos[4] = 1.00f;
            if (S->draw_mode.s0 == 'A') {
                strcpy(tick_title, "Beam Pattern (Linear)");
            } else {
                strcpy(tick_title, "Range Weight (Linear)");
            }
            break;
        case 'B':
            tick_lab = [NSArray arrayWithObjects:@"-40.0", @"-30.0", @"-20.0", @"-10.0", @"0.0", nil];
            tick_pos[0] = 0.00f;
            tick_pos[1] = 0.25f;
            tick_pos[2] = 0.50f;
            tick_pos[3] = 0.75f;
            tick_pos[4] = 1.00f;
            strcpy(tick_title, "Beam Pattern (dB)");
            break;
        case 'H':
        case 'V':
            tick_lab = [NSArray arrayWithObjects:@"0.0", @"10.0", @"20.0", nil];
            tick_pos[0] = 0.0f;
            tick_pos[1] = 0.5f;
            tick_pos[2] = 1.0f;
            if (S->draw_mode.s0 == 'H') {
                strcpy(tick_title, "RCS H");
            } else {
                strcpy(tick_title, "RCS V");
            }
            break;
        case 'D':
            tick_lab = [NSArray arrayWithObjects:@"-6.0", @"-3.0", @"0.0", @"+3.0", @"+6.0", nil];
            tick_pos[0] = 0.00f;
            tick_pos[1] = 0.25f;
            tick_pos[2] = 0.50f;
            tick_pos[3] = 0.75f;
            tick_pos[4] = 1.00f;
            strcpy(tick_title, "H : V (dB)");
            break;
        default:
            tick_lab = [NSArray array];
            break;
    }
}

- (NSArray *)scattererColorTickLabels
{
    return tick_lab;
}

- (float *)scattererColorTickPositions
{
    return tick_pos;
}

- (char *)scattererColorTitle
{
    return tick_title;
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
    return (NSInteger)S->workers[deviceId].num_scats;
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

- (GLint)decreasePopulationForDebris:(const int)debrisId returnCounts:(GLint *)counts
{
    if (debrisId == 0) {
        return -1;
    }
    size_t pop = RS_get_debris_count(S, debrisId);
    if (pop >= nearest_thousand) {
        pop -= nearest_thousand;
    } else if (pop >= nearest_hundred) {
        pop -= nearest_hundred;
    }

    RS_set_debris_count(S, debrisId, pop);

    RS_get_all_worker_debris_counts(S, debrisId, returnCounts);

    for (int i = 0; i < S->num_workers; i++) {
        counts[i] = (GLint)returnCounts[i];
    }
    
    return (GLuint)pop;
}

- (GLint)increasePopulationForDebris:(const int)debrisId returnCounts:(GLint *)counts
{
    if (debrisId == 0) {
        return -1;
    }
    size_t pop = RS_get_debris_count(S, debrisId);
    if (pop >= nearest_thousand && pop <= S->num_scats - nearest_thousand) {
        pop += nearest_thousand;
    } else {
        pop += nearest_hundred;
    }
    RS_set_debris_count(S, debrisId, pop);

    RS_get_all_worker_debris_counts(S, debrisId, returnCounts);
    
    for (int i = 0; i < S->num_workers; i++) {
        counts[i] = (GLint)returnCounts[i];
    }

    return (GLuint)pop;
}

- (GLint)populationForDebris:(const int)debrisId
{
    return (GLint)RS_get_debris_count(S, debrisId);
}

- (GLint)populationForDebris:(const int)debrisId forDevice:(const int)deviceId
{
    return (GLint)RS_get_worker_debris_count(S, debrisId, deviceId);
}

- (GLfloat)recommendedViewRange
{
    RSVolume v = RS_get_domain(S);
    return 1.2f * v.size.z;
}

- (void)increaseDemoRange
{
    S->draw_mode.s1 += 5;
}

- (void)decreaseDemoRange
{
    S->draw_mode.s1 -= 5;
}

- (NSString *)simulationDescription
{
    return [NSString stringWithFormat:@"%s", RS_simulation_description(S)];
}

@end
