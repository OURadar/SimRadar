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
    ADMTable table[256];
    int count;
} ADMMem;

// Private functions
void ADM_show_blk(const char *prefix, const char *posfix);
void ADM_show_row(const char *prefix, const char *posfix, const float *f, const int n);
void ADM_show_slice(const float *values, const int nb, const int na);
void ADM_compute_properties(ADMBase *);


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


ADMHandle ADM_init_with_path(const char *path) {
    
    char search_paths[10][1024] = {"./les"};

    int k = 0;
    if (path == NULL) {
        char cwd[1024];
        if (getcwd(cwd, sizeof(cwd)) == NULL) {
            fprintf(stderr, "Error in getcwd()\n");
            return NULL;
        }
        snprintf(search_paths[k++], 1024, "%s/%s", cwd, "Contents/Resources/les");
    } else {
        snprintf(search_paths[k++], 1024, "%s", path);
    }
    
    char *ctmp = getenv("HOME");
    if (ctmp != NULL) {
        //printf("[ADM] HOME = %s\n", ctmp);
        snprintf(search_paths[k++], 1024, "%s/Documents/tables", ctmp);
        snprintf(search_paths[k++], 1024, "%s/Downloads/tables", ctmp);
        snprintf(search_paths[k++], 1024, "%s/tables", ctmp);
    }
    
    struct stat path_stat;
    struct stat file_stat;
    char *dat_path = NULL;
    char dat_file_path[1024];
    int dir_ret;
    int file_ret;
    int found_dir = 0;
    
    for (int i = 0; i < sizeof(search_paths) / sizeof(search_paths[0]); i++) {
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
            printf("DEBUG ADM: Found ADM folder @ %s\n", dat_path);
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
    snprintf(h->data_path, sizeof(h->data_path), "%s", dat_path);
    
    // No table has been loaded yet
    h->count = 0;
    
    return (ADMHandle *)h;
}


ADMHandle ADM_init(void) {
    return ADM_init_with_path(NULL);
}


void ADM_free(ADMHandle i) {
    ADMMem *h = (ADMMem *)i;
    for (int i = 0; i < h->count; i++) {
        // Free each table that has been allocated previously
        ADMTable *table = &h->table[i];
        free(table->data.a);
        free(table->data.b);
        free(table->data.cdx);
        free(table->data.cdy);
        free(table->data.cdz);
        free(table->data.cmx);
        free(table->data.cmy);
        free(table->data.cmz);
    }
    free(h);
}


ADMTable *ADM_get_table(const ADMHandle in, const ADMConfig config) {
    ADMMem *h = (ADMMem *)in;
    
    int i;
    
    // Full path of the data
    char fullpath[1024];
    snprintf(fullpath, sizeof(fullpath), "%s/%s.adm", h->data_path, config);

    // Now, we open the file
    FILE *fid = fopen(fullpath, "r");
    if (fid == NULL) {
        fprintf(stderr, "Error opening file %s.\n", fullpath);
        return NULL;
    }
    
    // The first two 16-bit numbers are the grid dimensions
    uint16_t nbna[2];
    fread(nbna, sizeof(uint16_t), 2, fid);
    
    // Get the table pointer from the handler
    ADMTable *table = &h->table[h->count];
    
    // Populate the dimension details
    table->nb = nbna[0];  // x-axis = beta
    table->na = nbna[1];  // y-axis = alpha
    table->nn = table->na * table->nb;
    if (table->nn == 0) {
        fprintf(stderr, "None of the grid elements can be zero.\n");
        fclose(fid);
        return NULL;
    }
    
    // Allocate the space needed
    table->data.b = (float *)malloc(table->nb * sizeof(float));
    table->data.a = (float *)malloc(table->na * sizeof(float));
    table->data.cdx = (float *)malloc(table->nn * sizeof(float));
    table->data.cdy = (float *)malloc(table->nn * sizeof(float));
    table->data.cdz = (float *)malloc(table->nn * sizeof(float));
    table->data.cmx = (float *)malloc(table->nn * sizeof(float));
    table->data.cmy = (float *)malloc(table->nn * sizeof(float));
    table->data.cmz = (float *)malloc(table->nn * sizeof(float));

    // Fill in with values
    snprintf(table->name, 1024, "%s", config);
    snprintf(table->path, 1024, "%s", fullpath);
    for (i = 0; i < table->nb; i++) {
        table->data.b[i] = (float)i / (float)(table->nb - 1) * 360.0f - 180.0f;
    }
    for (i = 0; i < table->na; i++) {
        table->data.a[i] = (float)i / (float)(table->na - 1) * 180.0f;
    }
    fread(table->data.cdx, sizeof(float), table->nn, fid);
    fread(table->data.cdy, sizeof(float), table->nn, fid);
    fread(table->data.cdz, sizeof(float), table->nn, fid);
    fread(table->data.cmx, sizeof(float), table->nn, fid);
    fread(table->data.cmy, sizeof(float), table->nn, fid);
    fread(table->data.cmz, sizeof(float), table->nn, fid);
    
    h->count++;
    
    fclose(fid);
    
    // Physical description (dimension in m, density in kg/m^3)
    table->phys.x = 0.002f;
    table->phys.y = 0.040f;
    table->phys.z = 0.040f;
    table->phys.rho = 1120.0f;
    
    // Derive other physical parameters
    ADM_compute_properties(&table->phys);
    
    return table;
}


char *ADM_data_path(const ADMHandle i) {
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
