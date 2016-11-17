//
//  obj.c
//  Radar Simulation Framework
//
//  Created by Boon Leng Cheong on 11/17/15.
//  Copyright (c) 2016 Boon Leng Cheong. All rights reserved.
//
#include "obj.h"


OBJHandle *OBJ_init_with_path(const char *path) {
    return NULL;
}

OBJHandle *OBJ_init(void) {
    return OBJ_init_with_path(NULL);
}

void OBJ_free(OBJHandle *O) {
    free(O);
}

void OBJ_get_tables(ADMTable *A, RCSTable *R, OBJConfig type) {
    switch (type) {
        case OBJConfigWoodboard2x4:
//            ADM_get_table(<#const ADMHandle *#>, ADMConfigSquarePlate);
//            RCS_get_
            break;
            
        default:
            break;
    }
}
