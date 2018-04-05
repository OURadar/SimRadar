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
	OBJConfigUnknown       = 0,
	OBJConfigLeaf          = 1,
	OBJConfigLeafBig       = 2,
    OBJConfigWoodboard2x4  = 3,
    OBJConfigWoodboard4x8  = 4,
    OBJConfigMetalSheet    = 5,
    OBJConfigBrick         = 6,
	OBJConfigCount
};

#define OBJConfigString(x) \
(x == OBJConfigLeaf ? "Leaf" : \
(x == OBJConfigLeafBig ? "Big Leaf" : \
(x == OBJConfigWoodboard2x4 ? "2x4 Woodboard" : \
(x == OBJConfigWoodboard4x8 ? "4x8 Woodboard" : \
(x == OBJConfigMetalSheet ? "Metal Sheet" : \
(x == OBJConfigBrick ? "Brick" : "Unknown" ))))))

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
