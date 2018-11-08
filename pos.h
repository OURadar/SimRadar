//
//  pos.h
//  Radar Simulation Framework
//
//  Created by Boonleng Cheong 9/12/2018
//  Copyright (c) 2018 Boonleng Cheong. All rights reserved.
//
#ifndef _radarsim_pos_h
#define _radarsim_pos_h

#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>

#include "log.h"

#define POS_MAX_PATTERN_COUNT 100

// Test with this:
// radarsim -p50 -SD:0,75,10/90,75,10/0,90,10 -N
//


//typedef void * POSHandle;

typedef struct pos {
    float       az;
    float       el;
    uint32_t    index;                                 // Iteration of this position
    uint32_t    count;                                 // Repetition of this position
} POSPosition;

typedef struct pos_pattern {
    char        mode;
    char        reserved1;
    char        reserved2;
    char        reserved3;
    uint32_t    index;                                 // The index of POSPosition elements
    uint32_t    count;                                 // The count of POSPosition elements
    POSPosition positions[POS_MAX_PATTERN_COUNT];      // Array of positions
    float       az;                                    // Current azimuth to use
    float       el;                                    // Current elevation to use
} POSPattern;

int POS_get_next_angles(POSPattern *scan);
int POS_parse_from_string(POSPattern *scan, const char *string);
bool POS_is_ppi(POSPattern *scan);
bool POS_is_rhi(POSPattern *scan);
bool POS_is_dbs(POSPattern *scan);

#endif
