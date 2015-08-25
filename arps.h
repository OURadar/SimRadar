//
//  arps.h
//  Radar Simulation Framework
//
//  Created by Boon Leng Cheong on 8/25/15.
//  Copyright © 2015 Boon Leng Cheong. All rights reserved.
//

#ifndef arps_c
#define arps_c

#define ARPSConfigA52          "A52_OKC50m_sb1603"

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <hdf5.h>

typedef void* ARPSHandle;
typedef char* ARPSConfig;

typedef struct arps_grid {
	uint32_t  rev;            // Revision number, perhaps?
	uint32_t  nx;             // Number of cells in x direction
	uint32_t  ny;             // Number of cells in y direction
	uint32_t  nz;             // Number of cells in z direction
	float     *x;             // X values
	float     *y;             // Y values
	float     *z;             // Z values
} ARPSGrid;

typedef struct _arps_value {
	float *x;
	float *y;
	float *z;
	float *u;
	float *v;
	float *w;
	float *p;
	float *t;
} ARPSValue;

typedef struct _arps_table {
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
} ARPSTable;


ARPSHandle *ARPS_init_with_config_path(const ARPSConfig config, const char *path);
ARPSHandle *ARPS_init(void);
void ARPS_free(ARPSHandle *);

ARPSTable *ARPS_get_frame(const ARPSHandle *, const int n);
char *ARPS_data_path(const ARPSHandle *);

void ARPS_show_table_summary(const ARPSTable *table);

#endif /* arps_c */
