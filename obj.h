//
//  obj.h
//  Radar Simulation Framework
//
//  Created by Arturo Umeyama on 11/17/15.
//  Copyright (c) 2016 Arturo Umeyama. All rights reserved.
//
#ifndef _radarsim_obj_h
#define _radarsim_obj_h

#include "adm.h"
#include "rcs.h"

typedef int OBJConfig;

enum OBJConfig {
    OBJConfigUnknown,
    OBJConfigWoodboard2x4,
    OBJConfigWoodboard4x8,
    OBJConfigLeaf,
    OBJConfigLeafBig,
    OBJConfigMetalSheet,
    OBJConfigBrick
};

typedef struct _obj_table {
    ADMTable *adm_table;
    RCSTable *rcs_table;
} OBJTable;

typedef void * OBJHandle;

OBJHandle OBJ_init_with_path(const char *path);
OBJHandle OBJ_init(void);
void OBJ_free(OBJHandle);

OBJTable *OBJ_get_table(const OBJHandle, OBJConfig);

#endif
