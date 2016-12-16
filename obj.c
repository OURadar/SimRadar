//
//  obj.c
//  Radar Simulation Framework
//
//  Created by Arturo Umeyama on 11/17/15.
//  Copyright (c) 2016 Arturo Umeyama. All rights reserved.
//
#include "obj.h"

// Private structure
typedef struct _obj_mem {
    ADMHandle adm_h;
    RCSHandle rcs_h;
    OBJTable obj_table[256];
    int count;
} OBJMem;

OBJHandle OBJ_init_with_path(const char *path) {
    // Initialize a memory location for the handler
    OBJMem *h = (OBJMem *)malloc(sizeof(OBJMem));
    
    h->adm_h = ADM_init();
    h->rcs_h = RCS_init();
    h->count = 0;
    
    return (OBJHandle *)h;
}

OBJHandle OBJ_init(void) {
    return OBJ_init_with_path(NULL);
}

void OBJ_free(OBJHandle in) {
    OBJMem *h = (OBJMem *)in;
    
    ADM_free(h->adm_h);
    RCS_free(h->rcs_h);
    free(h);
}

OBJTable *OBJ_get_table(const OBJHandle in, OBJConfig type) {
    OBJMem *O = (OBJMem *)in;
    OBJTable *obj_table = &O->obj_table[O->count];
    //printf("OBJ count : %d \n", O->count);
    switch (type) {
        case OBJConfigWoodboard2x4:
            obj_table->adm_table = ADM_get_table(O->adm_h, ADMConfigSquarePlate);
            obj_table->rcs_table = RCS_get_table(O->rcs_h, RCSConfigWoodBoard);
            // Modify dimensions to 2 x 12 x 4 inches (depth x height x width) and density = 500 kg/m^3
            ADM_dimension_set(obj_table->adm_table, 0.0508f, 0.3048f, 0.1016f, 500.0f);
            break;
        case OBJConfigLeaf:
            obj_table->adm_table = ADM_get_table(O->adm_h, ADMConfigModelPlate);
            obj_table->rcs_table = RCS_get_table(O->rcs_h, RCSConfigLeaf);
            ADM_dimension_set(obj_table->adm_table, 0.002f, 0.04f, 0.04f, 1120.0f);
            break;
        case OBJConfigLeafBig:
            obj_table->adm_table = ADM_get_table(O->adm_h, ADMConfigModelPlate);
            obj_table->rcs_table = RCS_get_table(O->rcs_h, RCSConfigLeaf);
            // Modify dimensions to 0.1 x 8 x 6 cm (depth x height x width) and density = 350 kg / m^3
            ADM_dimension_set(obj_table->adm_table, 0.001f, 0.08f, 0.06f, 350.0f);
            break;
        case OBJConfigMetalSheet:
            obj_table->adm_table = ADM_get_table(O->adm_h, ADMConfigSquarePlate);
            obj_table->rcs_table = RCS_get_table(O->rcs_h, RCSConfigPlate);
            // Modify dimensions to 0.1 x 100 x 100 cm and density to 350 kg / m^3
            ADM_dimension_set(obj_table->adm_table, 0.001f, 1.0f, 1.0f, 7850.0f);
            break;
        case OBJConfigBrick:
            obj_table->adm_table = ADM_get_table(O->adm_h, ADMConfigSquarePlate);
            obj_table->rcs_table = RCS_get_table(O->rcs_h, RCSConfigBrick);
            // Modify dimensions to 6.5 x 21.5 x 11.25 cm (depth x height x width) and density = 2200 kg/m^3
            ADM_dimension_set(obj_table->adm_table, 0.065f, 0.215f, 0.1125f, 2200.0f);
            break;
        default:
            break;
    }
    
    O->count++;
    return obj_table;
}
