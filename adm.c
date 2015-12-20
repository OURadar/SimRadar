//
//  adm.c
//  Radar Simulation Framework
//
//  Created by Boon Leng Cheong on 1/19/15.
//  Copyright (c) 2015 Boon Leng Cheong. All rights reserved.
//

#include "adm.h"

// Private structure
typedef struct _adm_mem {
    char data_path[1024];
    char file[1024];
    ADMGrid grid;
    ADMTable table;
} ADMMem;

// Private functions
void ADM_show_blk(const char *prefix, const char *posfix);
void ADM_show_row(const char *prefix, const char *posfix, const float *f, const int n);
void ADM_show_slice(const float *values, const int nb, const int na);


#define ADM_FMT   "%+9.4f"
#define ADM_CFMT  "%s" ADM_FMT " " ADM_FMT "  " ADM_FMT " ... " ADM_FMT "%s"

void ADM_show_blk(const char *prefix, const char *posfix) {
    char buf[1024];
    sprintf(buf, ADM_CFMT, prefix, 1.0f, 1.0f, 1.0f, 1.0f, posfix);
    for (int i=(int)strlen(prefix); i<strlen(buf)-strlen(posfix); i++) {
        if (buf[i] == '.' && buf[i+1] == '0') {
            buf[i] = ':';
        } else {
            buf[i] = ' ';
        }
    }
    printf("%s", buf);
}


void ADM_show_row(const char *prefix, const char *posfix, const float *f, const int n) {
    printf(ADM_CFMT, prefix, f[0], f[1], f[2], f[n-1], posfix);
}


void ADM_show_slice(const float *values, const int nb, const int na) {
    ADM_show_row("  [ ", " ]\n", &values[0], nb);
    ADM_show_row("  [ ", " ]\n", &values[nb], nb);
    ADM_show_row("  [ ", " ]\n", &values[2 * nb], nb);
    ADM_show_blk("  [ ", " ]\n");
    ADM_show_row("  [ ", " ]\n\n", &values[(na - 1) * nb], nb);
}


ADMHandle *ADM_init_with_config_path(const ADMConfig config, const char *path) {
    
    char search_paths[10][1024] = {"./les"};
    
    if (path == NULL) {
        char cwd[1024];
        if (getcwd(cwd, sizeof(cwd)) == NULL) {
            fprintf(stderr, "Error in getcwd()\n");
            return NULL;
        }
        snprintf(search_paths[1], 1024, "%s/%s", cwd, "Contents/Resources/les");
    } else {
        snprintf(search_paths[1], 1024, "%s", path);
    }
    
    char *ctmp = getenv("HOME");
    if (ctmp != NULL) {
        //printf("[ADM] HOME = %s\n", ctmp);
        snprintf(search_paths[2], 1024, "%s/Downloads/tables", ctmp);
        snprintf(search_paths[3], 1024, "%s/Desktop/les", ctmp);
        snprintf(search_paths[4], 1024, "%s/Douments/les", ctmp);
        snprintf(search_paths[5], 1024, "%s/Downloads/les", ctmp);
    }
    
    struct stat path_stat;
    struct stat file_stat;
    char *dat_path = NULL;
    char dat_file_path[1024];
    int dir_ret;
    int file_ret;
    int found_dir = 0;
    
    for (int i=0; i<6; i++) {
        dat_path = search_paths[i];
        snprintf(dat_file_path, 1024, "%s/%s.adm", dat_path, ADMConfigSquarePlate);
        dir_ret = stat(dat_path, &path_stat);
        file_ret = stat(dat_file_path, &file_stat);
        if (dir_ret < 0 || file_ret < 0) {
            continue;
        }
        //printf("testing %s (%d)  %s (%d)\n", dat_path, S_ISDIR(path_stat.st_mode), dat_file_path, S_ISREG(file_stat.st_mode));
        if (dir_ret == 0 && S_ISDIR(path_stat.st_mode) && S_ISREG(file_stat.st_mode)) {
            
            #ifdef DEBUG
            printf("Found ADM folder @ %s\n", dat_path);
            #endif
            
            found_dir = 1;
            break;
        }
    }
    if (found_dir == 0) {
        fprintf(stderr, "Unable to find the ADM data folder.\n");
        return NULL;
    }
    
    // Initialize a memory location for the handler
    ADMMem *h = (ADMMem *)malloc(sizeof(ADMMem));
    if (h == NULL) {
        fprintf(stderr, "Unable to allocate resources for ADM framework.\n");
        return NULL;
    }
    
    // Full path of the data file
    snprintf(h->data_path, sizeof(h->data_path), "%s/%s.adm", dat_path, config);

    FILE *fid = fopen(h->data_path, "r");
    if (fid == NULL) {
        fprintf(stderr, "Error opening file.\n");
        return NULL;
    }
    
    // Data grid
    h->grid.rev = 1;
    uint16_t nbna[2];
    fread(nbna, sizeof(uint16_t), 2, fid);
    h->grid.nb = nbna[0];  // x-axis = beta
    h->grid.na = nbna[1];  // y-axis = alpha
    if (h->grid.nb == 0 || h->grid.na == 0) {
        fprintf(stderr, "None of the grid elements can be zero.\n");
        fclose(fid);
        return NULL;
    }
    
    #ifdef DEBUG
    printf("%s    nb = %d    na = %d\n", h->data_path, h->data_grid->nb, h->data_grid->na);
    #endif
    
    h->grid.b = (float *)malloc(h->grid.nb * sizeof(float));
    h->grid.a = (float *)malloc(h->grid.na * sizeof(float));
    
    uint16_t i;
    
    for (i = 0; i < h->grid.nb; i++) {
        h->grid.b[i] = (float)i / (float)(h->grid.nb - 1) * 360.0f - 180.0f;
    }
    for (i=0; i<h->grid.na; i++) {
        h->grid.a[i] = (float)i / (float)(h->grid.na - 1) * 180.0f;
    }

    // Populate a to-be returned table
    h->table.nb = h->grid.nb;
    h->table.na = h->grid.na;
    h->table.nn = h->grid.nb * h->grid.na;
    h->table.data.b = h->grid.b;
    h->table.data.a = h->grid.a;
    if (h->table.nn == 0) {
        fprintf(stderr, "Empty table (ADMTable)?\n");
        fclose(fid);
        return NULL;
    }
    h->table.data.cdx = (float *)malloc(h->table.nn * sizeof(float));
    h->table.data.cdy = (float *)malloc(h->table.nn * sizeof(float));
    h->table.data.cdz = (float *)malloc(h->table.nn * sizeof(float));
    h->table.data.cmx = (float *)malloc(h->table.nn * sizeof(float));
    h->table.data.cmy = (float *)malloc(h->table.nn * sizeof(float));
    h->table.data.cmz = (float *)malloc(h->table.nn * sizeof(float));
    
    // Fill in the table
    fread(h->table.data.cdx, sizeof(float), h->table.nn, fid);
    fread(h->table.data.cdy, sizeof(float), h->table.nn, fid);
    fread(h->table.data.cdz, sizeof(float), h->table.nn, fid);
    fread(h->table.data.cmx, sizeof(float), h->table.nn, fid);
    fread(h->table.data.cmy, sizeof(float), h->table.nn, fid);
    fread(h->table.data.cmz, sizeof(float), h->table.nn, fid);

    fclose(fid);
    
    // Physica description
    h->table.phys.x = 0.002f;
    h->table.phys.y = 0.040f;
    h->table.phys.z = 0.040f;
    h->table.phys.rho = 1120.0f;

    // Derive other physical parameters
    ADM_compute_properties(&h->table.phys);
    
    return (ADMHandle *)h;
}


ADMHandle *ADM_init(void) {
    return ADM_init_with_config_path(ADMConfigSquarePlate, "les");
}


void ADM_free(ADMHandle *i) {
    ADMMem *h = (ADMMem *)i;
    free(h->table.data.cdx);
    free(h->table.data.cdy);
    free(h->table.data.cdz);
    free(h->table.data.cmx);
    free(h->table.data.cmy);
    free(h->table.data.cmz);
    free(h->grid.b);
    free(h->grid.a);
    free(h);
}


ADMTable *ADM_get_frame(const ADMHandle *i) {
    ADMMem *h = (ADMMem *)i;
    return &h->table;
}


char *ADM_data_path(const ADMHandle *i) {
    ADMMem *h = (ADMMem * )i;
    return h->data_path;
}


void ADM_show_table_summary(const ADMTable *T) {
    printf(" beta =\n");
    ADM_show_row("  [ ", " ]\n\n", T->data.b, T->nb);

    printf(" alpha =\n");
    ADM_show_row("  [ ", " ]\n\n", T->data.a, T->na);

    printf(" cdx =\n");
    ADM_show_slice(T->data.cdx, T->nb, T->na);

    printf(" cdy =\n");
    ADM_show_slice(T->data.cdy, T->nb, T->na);

    printf(" cdz =\n");
    ADM_show_slice(T->data.cdz, T->nb, T->na);
    
    printf(" cmx =\n");
    ADM_show_slice(T->data.cmx, T->nb, T->na);

    printf(" cmy =\n");
    ADM_show_slice(T->data.cmy, T->nb, T->na);

    printf(" cmz =\n");
    ADM_show_slice(T->data.cmz, T->nb, T->na);
}


void ADM_transform_scale(ADMTable *T, const float x, const float y, const float z, const float r) {
    T->phys.x *= x;
    T->phys.y *= y;
    T->phys.z *= z;
    T->phys.rho *= r;
    ADM_compute_properties(&T->phys);
}


void ADM_dimension_set(ADMTable *T, const float x, const float y, const float z, const float r) {
    T->phys.x = x;
    T->phys.y = y;
    T->phys.z = z;
    T->phys.rho = r;
    ADM_compute_properties(&T->phys);
}


void ADM_compute_properties(ADMBase *phys) {
    const float g = 9.8f;
    const float v0 = 100.0f;
    const float rho_air = 1.21f;
    
    phys->mass = phys->x * phys->y * phys->z * phys->rho;
    
    float ix = (phys->y * phys->y + phys->z * phys->z) * phys->mass / 12.0f;
    float iy = (phys->x * phys->x + phys->z * phys->z) * phys->mass / 12.0f;
    float iz = (phys->x * phys->x + phys->y * phys->y) * phys->mass / 12.0f;
    
    //    float inln_x = ix * g * phys->x / (phys->mass * phys->y * phys->z * v0 * v0);
    //    float inln_y = iy * g * phys->y / (phys->mass * phys->x * phys->z * v0 * v0);
    //    float inln_z = iz * g * phys->z / (phys->mass * phys->x * phys->z * v0 * v0);
    
    phys->Ta = rho_air * (phys->y * phys->z * v0 * v0) / (2.0f * phys->mass * g);
    
    // De-dimensionalize
    // Velocity should have v0 * v0 / g whenever velocity is retrieved but pre-done here
    // Angular momentum's len needs to be dimensionalized by v0 * v0 / g
    phys->inv_inln_x = (phys->mass * phys->x) / (ix * g * g);
    phys->inv_inln_y = (phys->mass * phys->y) / (iy * g * g);
    phys->inv_inln_z = (phys->mass * phys->z) / (iz * g * g);
    
    phys->Ta *= g / (v0 * v0);
}
