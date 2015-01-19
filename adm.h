//
//  adm.h
//  Radar Simulation Framework
//
//  Created by Boon Leng Cheong on 1/19/15.
//  Copyright (c) 2015 Boon Leng Cheong. All rights reserved.
//

#ifndef _radarsim_adm_h
#define _radarsim_adm_h

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

#define ADMSquarePlate       "square_plate"
#define ADMRoofTile          "roof_tile"

typedef void* ADMHandle;
typedef char* ADMConfig;

typedef struct adm_grid {
    uint32_t  rev;            // Revision number, perhaps?
    uint32_t  nb;             // Number of cells in beta direction
    uint32_t  na;             // Number of cells in alpha direction
    float     *b;             // Beta values
    float     *a;             // Alpha values
} ADMGrid;

typedef struct _adm_data {
    float *b;
    float *a;
    float *cdx;
    float *cdy;
    float *cdz;
    float *cmx;
    float *cmy;
    float *cmz;
} ADMData;

typedef struct _adm_table {
    uint32_t  nb;             // Number of cells in beta direction
    uint32_t  na;             // Number of cells in alpha direction
    uint32_t  nn;             // Number of cells in all directions combined
    float     *b;
    float     *a;
    float     *cdx;
    float     *cdy;
    float     *cdz;
    float     *cmx;
    float     *cmy;
    float     *cmz;
} ADMTable;

ADMHandle *ADM_init_with_config_path(const ADMConfig config, const char *path);
ADMHandle *ADM_init(void);
void ADM_free(ADMHandle *);

ADMTable *ADM_get_frame(const ADMHandle *);

void ADM_show_table_summary(const ADMTable *);

#endif
