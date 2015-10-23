//
//  arps.c
//  Radar Simulation Framework
//
//  Created by Boon Leng Cheong on 8/25/15.
//  Copyright © 2015 Boon Leng Cheong. All rights reserved.
//

#include "arps.h"

#define ARPS_num             10

// Private structure

typedef struct _arps_mem {
    char data_path[1024];
    char files[ARPS_num][1024];
    ARPSGrid *enclosing_grid;
    ARPSGrid *data_grid;
    int ibuf;
    size_t data_id[ARPS_num];
    ARPSTable *data_boxes[ARPS_num];
} ARPSMem;


ARPSHandle *ARPS_init_with_config_path(const ARPSConfig config, const char *path) {
    // Find the path
    char cwd[1024];
    if (getcwd(cwd, sizeof(cwd)) == NULL)
    fprintf(stderr, "Error in getcwd()\n");

    // 10 search paths with the first one being relative subfolder 'arps'
    char search_paths[10][1024] = {"./arps"};

    if (path == NULL) {
        snprintf(search_paths[1], 1024, "%s/%s", cwd, "Contents/Resources/arps");
    } else {
        snprintf(search_paths[1], 1024, "%s/%s", path, "arps");
    }
    
    char *ctmp = getenv("HOME");
    if (ctmp != NULL) {
        //printf("HOME = %s\n", ctmp);
        snprintf(search_paths[3], 1024, "%s/Desktop/tables/%s", ctmp, config);
        snprintf(search_paths[4], 1024, "%s/Documents/tables/%s", ctmp, config);
        snprintf(search_paths[5], 1024, "%s/Downloads/tables/%s", ctmp, config);
        snprintf(search_paths[6], 1024, "%s/Desktop/arps/%s", ctmp, config);
        snprintf(search_paths[7], 1024, "%s/Documents/arps/%s", ctmp, config);
        snprintf(search_paths[8], 1024, "%s/Downloads/arps/%s", ctmp, config);
    }

    struct stat path_stat;
    struct stat file_stat;
    char *dir_path;
    char file_path[1024];
    int dir_ret;
    int file_ret;
    int found_dir = 0;
    
    for (int i=0; i<sizeof(search_paths)/sizeof(search_paths[0]); i++) {
        dir_path = search_paths[i];
        snprintf(file_path, 1024, "%s/%s.hdfgrdbas", dir_path, config);
        printf("Trying %s ...\n", file_path);
        dir_ret = stat(dir_path, &path_stat);
        file_ret = stat(file_path, &file_stat);
        if (dir_ret < 0 || file_ret < 0) {
            continue;
        }
        if (dir_ret == 0 && S_ISDIR(path_stat.st_mode) && S_ISREG(file_stat.st_mode)) {
            
#ifdef DEBUG
            printf("Found ARPS folder @ %s\n", dir_path);
#endif
            
            found_dir = 1;
            break;
        }
    }
    if (found_dir == 0) {
        fprintf(stderr, "Unable to find the ARPS data folder.\n");
        return NULL;
    }
    
    // Initialize a memory location for the handler
    ARPSMem *h = (ARPSMem *)malloc(sizeof(ARPSMem));
    if (h == NULL) {
        fprintf(stderr, "Unable to allocate resources for ARPS framework.\n");
        return NULL;
    }
    
    snprintf(h->data_path, sizeof(h->data_path), "%s/%s.hdfgrdbas", dir_path, config);
    
    printf("h->data_path = %s\n", h->data_path);
    
    // Open up the grid base file to get some basic parameters
    hid_t file_id, dset_id, plist_id;
    herr_t status;
    H5D_layout_t layout = H5D_NLAYOUTS;
//    hsize_t dims[2] = {1000, 1000};
    printf("Getting file_id ...\n");
    file_id = H5Fopen(h->data_path, H5F_ACC_RDONLY, H5P_DEFAULT);
    
    printf("Getting dset_id ...\n");
    dset_id = H5Dopen1(file_id, "p");

#define H5_LAYOUT_STRING(s) \
(s == H5D_COMPACT ? "H5D_COMPACT" : \
(s == H5D_CONTIGUOUS ? "H5D_CONTIGUOUS" : \
(s == H5D_CHUNKED ? "H5D_CHUNKED" : \
(s == H5D_NLAYOUTS ? "H5D_NLAYOUTS" : \
(s == H5D_LAYOUT_ERROR ? "H5D_LAYOUT_ERROR" : "UNEXPECTED")))))
    
    printf("Storage layout for DS1 is: %s", H5_LAYOUT_STRING(layout));

    plist_id = H5Dget_create_plist(dset_id);
    layout = H5Pget_layout(plist_id);

    int rdata[1000][1000];
    H5Dread(dset_id, H5T_NATIVE_INT, H5S_ALL, H5S_ALL, H5P_DEFAULT, rdata[0]);
    
    status = H5Pclose(plist_id);
    if (status != 0) {
        fprintf(stderr, "Error closing data creation property list.\n");
    }
    H5Dclose(dset_id);
    H5Dclose(file_id);

    h->ibuf = 0;
    
    return (ARPSHandle *)h;
}

ARPSHandle *ARPS_init(void) {
    return ARPS_init_with_config_path(ARPSConfigA52, NULL);
}

void ARPS_free(ARPSHandle *A) {
    if (A != NULL) {
        free(A);
    }
}

ARPSTable *ARPS_get_frame(const ARPSHandle *i, const int n) {
    ARPSTable *table = NULL;
    return table;
}

char *ARPS_data_path(const ARPSHandle *i) {
    ARPSMem *h = (ARPSMem *)i;
    return h->data_path;
}

void ARPS_show_table_summary(const ARPSTable *table) {
    
}
