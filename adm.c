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
    ADMGrid *data_grid;
    ADMTable *data_value;
} ADMMem;

// Private functions
void ADM_show_row(const char *prefix, const char *posfix, const float *f, const int n);
void ADM_show_blk(const char *prefix, const char *posfix);
void ADM_show_slice(const float *values, const int nb, const int na);


ADMTable *ADM_get_frame(const ADMHandle *i) {
    ADMMem *h = (ADMMem *)i;
    return h->data_value;
}


#define ADM_FMT   "%+9.4f"
#define ADM_CFMT  "%s" ADM_FMT " " ADM_FMT "  " ADM_FMT " ... " ADM_FMT "%s"
void ADM_show_row(const char *prefix, const char *posfix, const float *f, const int n) {
    printf(ADM_CFMT, prefix, f[0], f[1], f[2], f[n-1], posfix);
}


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
        //printf("HOME = %s\n", ctmp);
        snprintf(search_paths[2], 1024, "%s/Desktop/les", ctmp);
        snprintf(search_paths[3], 1024, "%s/Douments/les", ctmp);
        snprintf(search_paths[4], 1024, "%s/Downloads/les", ctmp);
    }
    
    struct stat path_stat;
    struct stat file_stat;
    char *dat_path = NULL;
    char dat_file_path[1024];
    int dir_ret;
    int file_ret;
    int found_dir = 0;
    
    for (int i=0; i<5; i++) {
        dat_path = search_paths[i];
        snprintf(dat_file_path, 1024, "%s/%s.adm", dat_path, ADMSquarePlate);
        dir_ret = stat(dat_path, &path_stat);
        file_ret = stat(dat_file_path, &file_stat);
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
    
    // Allocate the data grid
    h->data_grid = (ADMGrid *)malloc(sizeof(ADMGrid));
    if (h->data_grid == NULL) {
        fprintf(stderr, "Error allocating table (ADMGrid).\n");
        return NULL;
    }
    h->data_grid->rev = 1;
    fread(&h->data_grid->nb, sizeof(uint16_t), 1, fid);
    fread(&h->data_grid->na, sizeof(uint16_t), 1, fid);
    h->data_grid->b = (float *)malloc(h->data_grid->nb * sizeof(float));
    h->data_grid->a = (float *)malloc(h->data_grid->na * sizeof(float));
    
    uint16_t i;
    
    for (i=0; i<h->data_grid->nb; i++) {
        h->data_grid->b[i] = (float)i / (float)(h->data_grid->nb - 1) * 360.0f - 180.0f;
    }
    for (i=0; i<h->data_grid->na; i++) {
        h->data_grid->a[i] = (float)i / (float)(h->data_grid->na - 1) * 180.0f;
    }

#ifdef DEBUG
    printf("%s    nb = %d    na = %d\n", h->data_path, h->data_grid->nb, h->data_grid->na);
#endif
    
    // Allocate data table
    h->data_value = (ADMTable *)malloc(sizeof(ADMTable));
    if (h->data_value == NULL) {
        fprintf(stderr, "Error allocating table (ADMTable).\n");
        return NULL;
    }
    h->data_value->nb = h->data_grid->nb;
    h->data_value->na = h->data_grid->na;
    h->data_value->nn = h->data_grid->nb * h->data_grid->na;
    h->data_value->b = h->data_grid->b;
    h->data_value->a = h->data_grid->a;
    h->data_value->cdx = (float *)malloc(h->data_value->nn * sizeof(float));
    h->data_value->cdy = (float *)malloc(h->data_value->nn * sizeof(float));
    h->data_value->cdz = (float *)malloc(h->data_value->nn * sizeof(float));
    h->data_value->cmx = (float *)malloc(h->data_value->nn * sizeof(float));
    h->data_value->cmy = (float *)malloc(h->data_value->nn * sizeof(float));
    h->data_value->cmz = (float *)malloc(h->data_value->nn * sizeof(float));
    
    // Fill in the table
    fread(h->data_value->cdx, sizeof(float), h->data_value->nn, fid);
    fread(h->data_value->cdy, sizeof(float), h->data_value->nn, fid);
    fread(h->data_value->cdz, sizeof(float), h->data_value->nn, fid);
    fread(h->data_value->cmx, sizeof(float), h->data_value->nn, fid);
    fread(h->data_value->cmy, sizeof(float), h->data_value->nn, fid);
    fread(h->data_value->cmz, sizeof(float), h->data_value->nn, fid);

    fclose(fid);
    
    return (ADMHandle *)h;
}


ADMHandle *ADM_init(void) {
    return ADM_init_with_config_path(ADMSquarePlate, "les");
}


void ADM_free(ADMHandle *i) {
    ADMMem *h = (ADMMem *)i;
    free(h->data_value->cdx);
    free(h->data_value->cdy);
    free(h->data_value->cdz);
    free(h->data_value->cmx);
    free(h->data_value->cmy);
    free(h->data_value->cmz);
    free(h->data_value);
    free(h->data_grid->b);
    free(h->data_grid->a);
    free(h->data_grid);
    free(h);
}


void ADM_show_table_summary(const ADMTable *T) {
    printf(" beta =\n");
    ADM_show_row("  [ ", " ]\n\n", T->b, T->nb);

    printf(" alpha =\n");
    ADM_show_row("  [ ", " ]\n\n", T->a, T->na);

    printf(" cdx =\n");
    ADM_show_slice(T->cdx, T->nb, T->na);

    printf(" cdy =\n");
    ADM_show_slice(T->cdy, T->nb, T->na);

    printf(" cdz =\n");
    ADM_show_slice(T->cdz, T->nb, T->na);
    
    printf(" cmx =\n");
    ADM_show_slice(T->cmx, T->nb, T->na);

    printf(" cmy =\n");
    ADM_show_slice(T->cmy, T->nb, T->na);

    printf(" cmz =\n");
    ADM_show_slice(T->cmz, T->nb, T->na);
}
