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

- (NSInteger)numberOfPoints {
	return (NSInteger)S->num_scats;
}

#pragma mark -
#pragma mark Alloc / Memory

- (id)init
{
	self = [super init];
	if (self) {
		S  = RS_init();
		//S = RS_init_verbose(2);

		//L = LES_init();
        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
        
		L = LES_init_with_config_path(LESConfigSuctionVortices, [resourcePath UTF8String]);
        
        if (L == NULL || S == NULL) {
            NSLog(@"Some error(s) in RS_init() or LES_init() occurred.");
            return nil;
        }
		
		#ifdef DEBUG
		RS_set_verbosity(S, 2);
		#endif

		RS_set_antenna_params(S, 1.0f, 44.5f);
		
		RS_set_scan_box(S,
						10.0e3, 15.0e3, 250.0f,         // Range
						-12.0f, 12.0f, 2.0f,            // Azimuth
						0.0f, 6.0f, 1.0f);              // Elevation
	
		//RS_set_physics_data_to_cube125(S);
		//RS_set_physics_data_to_cube27(S);
		
		table_id = 0;
		LESTable *table = LES_get_frame(L, table_id);
		//LES_show_table_summary(table);
		RS_set_physics_data_to_LES_table(S, table);
		
		//RS_set_prt(S, 1.0f);
        //RS_set_prt(S, 0.5f);
		RS_set_prt(S, 0.1f);

		az_deg = 0.0f;
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

- (void)shareVBOsWithGL:(GLuint *)vbos
{
	unsigned int uivbos[2] = {vbos[0], vbos[1]};
	RS_share_mem_with_vbo(S, uivbos);
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
	RS_populate(S);
}


- (void)explode
{
	RS_explode(S);
}

- (void)advanceTime
{
	RS_advance_time(S);
	//RS_make_pulse(S);
    
	if (S->sim_tic >= S->sim_toc) {
		LESTable *table = LES_get_frame(L, table_id);
		if (table != NULL) {
			RS_set_physics_data_to_LES_table(S, table);
			//NSLog(@"table_id = %d", table_id);
		}
		table_id = (table_id + 1) % 20;
	}
}

- (void)advanceBeamPosition
{
	az_deg = fmodf(az_deg + 0.2f + 12.0f, 24.0f) - 12.0f;
	RS_set_beam_pos(S, az_deg, 2.0f);
	RS_update_colors_only(S);
}

- (void)advanceTimeAndBeamPosition
{
    az_deg = fmodf(az_deg + 0.2f + 12.0f, 24.0f) - 12.0f;
	RS_set_beam_pos(S, az_deg, 2.0f);
	RS_advance_time(S);
}

- (void)randomBeamPosition
{
	az_deg = (float)rand() / RAND_MAX * 24.0f - 12.0f;
	RS_set_beam_pos(S, az_deg, 2.0f);
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


- (cl_float4 *)points
{
	return S->scat_pos;
}

- (NSInteger)pointCount
{
	return (NSInteger)S->num_scats;
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

@end
