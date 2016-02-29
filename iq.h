//
//  iq.h
//
//  Created by Boon Leng Cheong on 7/29/15.
//  Copyright (c) 2015 Boon Leng Cheong. All rights reserved.
//

#ifndef iq_h
#define iq_h

#include "rs_types.h"
#include "rs_const.h"

// Basic structure of a complex sample
typedef struct iq_complex {
    float i;
    float q;
} IQComplex;

// Header of a raw file
typedef union fileheader {
    char      raw[1024];
    struct {
        RSParams  params;
        uint32_t  debris_population[RS_MAX_DEBRIS_TYPES];
        char      scan_mode[16];
        float     scan_start;
        float     scan_end;
        float     scan_delta;
    };
} IQFileHeader;

// Header of each pulse
typedef union pulseheader {
    char raw[32];
    struct {
        float      time;
        float      el_deg;
        float      az_deg;
    };
} IQPulseHeader;

#endif /* iq_h */
