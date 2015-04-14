//
//  les.h
//  Radar Simulation Framework
//
//  Created by Boon Leng Cheong on 4/7/14.
//  Copyright (c) 2014 Boon Leng Cheong. All rights reserved.
//

#ifndef _radarsim_les_h
#define _radarsim_les_h

#define LESConfigTwoCell          "twocell"
#define LESConfigSuctionVortices  "suct_vort"

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

typedef void* LESHandle;
typedef char* LESConfig;

typedef struct les_grid {
	uint32_t  rev;            // Revision number, perhaps?
	uint32_t  nx;             // Number of cells in x direction
	uint32_t  ny;             // Number of cells in y direction
	uint32_t  nz;             // Number of cells in z direction
	float     *x;             // X values
	float     *y;             // Y values
	float     *z;             // Z values
} LESGrid;

typedef struct _les_value {
	float *x;
	float *y;
	float *z;
	float *u;
	float *v;
	float *w;
	float *p;
	float *t;
} LESValue;

typedef struct _les_table {
	uint32_t  nx;             // Number of cells in x direction
	uint32_t  ny;             // Number of cells in y direction
	uint32_t  nz;             // Number of cells in z direction
	uint32_t  nn;             // Number of cells in all directions combined
	uint32_t  nt;             // Number of time steps
	float     tr;             // Replenishing time constant
	float     *x;
	float     *y;
	float     *z;
	float     *u;
	float     *v;
	float     *w;
	float     *p;
	float     *t;
} LESTable;


LESHandle *LES_init_with_config_path(const LESConfig config, const char *path);
LESHandle *LES_init(void);
void LES_free(LESHandle *);

LESTable *LES_get_frame(const LESHandle *, const int n);
char *LES_data_path(const LESHandle *);

void LES_show_table_summary(const LESTable *table);

#endif
