//
//  pos.h
//  Radar Simulation Framework
//
//  Created by Boonleng Cheong 9/12/2018
//  Copyright (c) 2018 Boonleng Cheong. All rights reserved.
//
#ifndef _radarsim_pos_h
#define _radarsim_pos_h

#include "log.h"

#define POS_MAX_PATTERN_COUNT    10000
#define POS_MAX_SWEEP_COUNT      50

// Test with this:
// radarsim -p50 -SD:0,75,10/90,75,10/0,90,10 -N
//


typedef void * POSHandle;

typedef struct pos_pos {
    float       az;
    float       el;
    uint32_t    index;                                 // Iteration of this position
    uint32_t    count;                                 // Repetition of this position
} POSPosition;

typedef struct pos_sweep {
    float       azStart;
    float       azEnd;
    float       azDelta;
    float       elStart;
    float       elEnd;
    float       elDelta;
} POSSweep;

typedef struct pos_pattern {
    char        mode;
    char        reserved1;
    char        reserved2;
    char        reserved3;
    uint32_t    index;                                 // The index of POSPosition elements
    uint32_t    count;                                 // The count of POSPosition elements
    uint32_t    sweepIndex;                            // The index of POSSweep elements
    uint32_t    sweepCount;                            // The count of POSSweep elements
    POSPosition positions[POS_MAX_PATTERN_COUNT];      // Array of positions
    POSSweep    sweeps[POS_MAX_SWEEP_COUNT];           // For summary generation only
    float       az;                                    // Current azimuth to use
    float       el;                                    // Current elevation to use
    uint32_t    tic;
} POSPattern;

POSPattern *POS_init(void);
POSPattern *POS_init_with_string(const char *);
void POS_free(POSPattern *);

int POS_get_next_angles(POSPattern *scan);
int POS_parse_from_string(POSPattern *scan, const char *string);
bool POS_is_ppi(const POSPattern *scan);
bool POS_is_rhi(const POSPattern *scan);
bool POS_is_dbs(const POSPattern *scan);
bool POS_is_empty(const POSPattern *scan);

void POS_summary(POSHandle P);

#endif
