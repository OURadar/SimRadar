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

#define ADMConfigSquarePlate       "square_plate"
#define ADMConfigRoofTile          "roof_tile"

typedef void* ADMHandle;
typedef char* ADMConfig;

typedef struct adm_grid {
    uint32_t  rev;            // Revision number, perhaps?
    uint32_t  nb;             // Number of cells in beta direction
    uint32_t  na;             // Number of cells in alpha direction
    float     *b;             // Beta values
    float     *a;             // Alpha values
} ADMGrid;

typedef struct _adm_base {
    float     x;              // Length in x (m) (local coordinate)
    float     y;              // Length in y (m) (local coordinate)
    float     z;              // Length in z (m) (local coordinate)
    float     rho;            // Density (kg / m^3)
    float     mass;           // Mass (kg)
    float     Ta;             // Tachikawa parameter
    float     inv_inln_x;     // X componenent of 1 / (In Ln)
    float     inv_inln_y;     // Y componenent of 1 / (In Ln)
    float     inv_inln_z;     // Z componenent of 1 / (In Ln)
} ADMBase;

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
    //uint32_t  nt;             // Number of debris types
    uint32_t  nb;             // Number of cells in beta direction
    uint32_t  na;             // Number of cells in alpha direction
    uint32_t  nn;             // Number of cells in all directions combined
    ADMBase   phys;           // Physical description of the debris
    ADMData   data;
    char      **name;
} ADMTable;

ADMHandle *ADM_init_with_config_path(const ADMConfig config, const char *path);
ADMHandle *ADM_init(void);
void ADM_free(ADMHandle *);

ADMTable *ADM_get_frame(const ADMHandle *);
char *ADM_data_path(const ADMHandle *);

void ADM_show_table_summary(const ADMTable *);

#endif
