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
    // Find the path
    char cwd[1024];
    if (getcwd(cwd, sizeof(cwd)) == NULL)
        fprintf(stderr, "Error in getcwd()\n");
    
    // 10 search paths with the first one being the relative subfolder 'les'
    char search_paths[10][1024] = {"./obj"};
    
    int k = 0;
    if (path == NULL) {
        snprintf(search_paths[k++], 1024, "%s/%s", cwd, "Contents/Resources/tables");
    } else {
        snprintf(search_paths[k++], 1024, "%s/%s", path, "tables");
    }
    
    char *ctmp = getenv("HOME");
    if (ctmp != NULL) {
        //printf("HOME = %s\n", ctmp);
        snprintf(search_paths[k++], 1024, "%s/Documents/tables", ctmp);
        snprintf(search_paths[k++], 1024, "%s/Downloads/tables", ctmp);
    }
    
//    struct stat path_stat;
//    struct stat file_stat;
//    char *les_path = NULL;
//    char les_file_path[1024];
//    int dir_ret;
//    int file_ret;
//    int found_dir = 0;
    
//    for (int i = 0; i < sizeof(search_paths) / sizeof(search_paths[0]); i++) {
//        les_path = search_paths[i];
//        snprintf(les_file_path, 1024, "%s/obj/%s.obj", les_path, config);
//        dir_ret = stat(les_path, &path_stat);
//        file_ret = stat(les_file_path, &file_stat);
//        if (dir_ret < 0 || file_ret < 0) {
//            continue;
//        }
//        if (dir_ret == 0 && S_ISDIR(path_stat.st_mode) && S_ISREG(file_stat.st_mode)) {
//
//#ifdef DEBUG
//            rsprint("Found LES folder @ %s\n", les_path);
//#endif
//
//            found_dir = 1;
//            break;
//        }
//    }
//    if (found_dir == 0 || les_path == NULL) {
//        fprintf(stderr, "Unable to find the LES data folder.\n");
//        return NULL;
//    }
    
    // Initialize a memory location for the handler
    OBJMem *h = (OBJMem *)malloc(sizeof(OBJMem));
    
    h->adm_h = ADM_init_with_path(path);
    if (h->adm_h == NULL) {
        free(h);
        return NULL;
    }
    h->rcs_h = RCS_init_with_path(path);
    if (h->rcs_h == NULL) {
        free(h);
        return NULL;
    }
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
    switch (type) {
        case OBJConfigWoodboard2x4:
            obj_table->adm_table = ADM_get_table(O->adm_h, ADMConfigSquarePlate);
            obj_table->rcs_table = RCS_get_table(O->rcs_h, RCSConfigWoodBoard);
            // Modify dimensions to 2 x 12 x 4 inches (depth x height x width) and density = 500 kg/m^3
            ADM_dimension_set(obj_table->adm_table, 0.0508f, 0.3048f, 0.1016f, 500.0f);
            break;
		case OBJConfigWoodboard4x8:
			obj_table->adm_table = ADM_get_table(O->adm_h, ADMConfigSquarePlate);
			obj_table->rcs_table = RCS_get_table(O->rcs_h, RCSConfigWoodBoard);
			// Modify dimensions to 4 x 12 x 8 inches (depth x height x width) and density = 500 kg/m^3
			ADM_dimension_set(obj_table->adm_table, 0.1016f, 0.3048f, 0.2032f, 500.0f);
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
    //printf("OBJ count : %d \n", O->count);
    return obj_table;
}

OBJTable *OBJ_get_table_using_config_file(const OBJHandle in, const char *config) {
    OBJMem *O = (OBJMem *)in;
    OBJTable *obj_table = &O->obj_table[O->count];
    
    
    O->count++;
    //printf("OBJ count : %d \n", O->count);
    return obj_table;
}
