//
//  rcs.h
//  Radar Simulation Framework
//
//  Created by Boon Leng Cheong on 3/16/15.
//  Copyright (c) 2015 Boon Leng Cheong. All rights reserved.
//

#ifndef _radarsim_rcs_h
#define _radarsim_rcs_h

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

#define RCSConfigLeaf              "leaf"
#define RCSConfigBrick             "brick"
#define RCSConfigWoodBoard         "woodboard"
#define RCSConfigWoodBoardDish     "woodboardish"

typedef void* RCSHandle;
typedef char* RCSConfig;

typedef struct rcs_grid {
    uint32_t  rev;            // Revision number, perhaps?
    uint32_t  na;             // Number of cells in alpha direction
    uint32_t  nb;             // Number of cells in beta direction
    float     *a;             // Alpha values
    float     *b;             // Beta values
} RCSGrid;

typedef struct _rcs_data {
    float *a;
    float *b;
    float *hh_real;
    float *vv_real;
    float *hv_real;
    float *hh_imag;
    float *vv_imag;
    float *hv_imag;
} RCSData;

typedef struct _rcs_table {
    uint32_t  na;             // Number of cells in alpha direction
    uint32_t  nb;             // Number of cells in beta direction
    uint32_t  nn;             // Number of cells in all directions combined
    RCSData   data;
    char      *name;
    char      *path;
} RCSTable;

RCSHandle *RCS_init_with_config_path(const RCSConfig config, const char *path);
RCSHandle *RCS_init_with_path(const char *path);
RCSHandle *RCS_init(void);
void RCS_free(RCSHandle *);

RCSTable *RCS_get_frame(const RCSHandle *);
RCSTable *RCS_get_table(const RCSHandle *, const RCSConfig config);
char *RCS_data_path(const RCSHandle *);

void RCS_show_table_summary(const RCSTable *);

#endif
