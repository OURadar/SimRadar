//
//  pos.h
//  Radar Simulation Framework
//
//  Created by Boonleng Cheong 9/12/2018
//  Copyright (c) 2018 Boonleng Cheong. All rights reserved.
//
#ifndef _radarsim_pos_h
#define _radarsim_pos_h

#define POS_MAX_PATTERN_COUNT 100

typedef struct pos {
    float az;
    float el;
    uint32_t count;
    uint32_t index;
} POSPosition;

typedef struct pos_pattern {
    POSPosition positions[POS_MAX_PATTERN_COUNT];
    uint32_t count;
    uint32_t index;                 // The index of position
    uint32_t scan_index;            // The index of scan
    float az;                       // Current azimuth to use
    float el;                       // Current elevation to use
} POSPattern;

#endif
