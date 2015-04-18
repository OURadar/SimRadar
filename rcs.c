//
//  rcs.c
//  Radar Simulation Framework
//
//  Created by Boon Leng Cheong on 3/16/15.
//  Copyright (c) 2015 Boon Leng Cheong. All rights reserved.
//

#include "rcs.h"

// Private structure
typedef struct _rcs_mem {
    char data_path[1024];
    char file[1024];
    RCSGrid *data_grid;
    RCSTable *data_value;
} RCSMem;

// Private functions
void RCS_show_blk(const char *prefix, const char *posfix);
void RCS_show_row(const char *prefix, const char *posfix, const float *f, const int n);
void RCS_show_slice(const float *values, const int na, const int nb);
void RCS_show_blk_complex(const char *prefix, const char *posfix);
void RCS_show_row_complex(const char *prefix, const char *posfix, const float *r, const float *i, const int n);
void RCS_show_slice_complex(const float *values_real, const float *values_imag, const int na, const int nb);


#define RCS_RFMT   "%+9.4f"
#define RCS_CFMT   "%+9.4f%+9.4fi"
#define RCS_CRFMT  "%s" RCS_RFMT " " RCS_RFMT "  " RCS_RFMT " ... " RCS_RFMT "%s"
#define RCS_CCFMT  "%s" RCS_CFMT " " RCS_CFMT "  " RCS_CFMT " ... " RCS_CFMT "%s"

void RCS_show_blk(const char *prefix, const char *posfix) {
    char buf[1024];
    sprintf(buf, RCS_CRFMT, prefix, 1.0f, 1.0f, 1.0f, 1.0f, posfix);
    for (int i=(int)strlen(prefix); i<strlen(buf)-strlen(posfix); i++) {
        if (buf[i] == '.' && buf[i+1] == '0') {
            buf[i] = ':';
        } else {
            buf[i] = ' ';
        }
    }
    printf("%s", buf);
}


void RCS_show_row(const char *prefix, const char *posfix, const float *f, const int n) {
    printf(RCS_CRFMT, prefix, f[0], f[1], f[2], f[n-1], posfix);
}


void RCS_show_slice(const float *values, const int na, const int nb) {
    RCS_show_row("  [ ", " ]\n", &values[0], na);
    RCS_show_row("  [ ", " ]\n", &values[na], na);
    RCS_show_row("  [ ", " ]\n", &values[2 * na], na);
    RCS_show_blk("  [ ", " ]\n");
    RCS_show_row("  [ ", " ]\n\n", &values[(nb - 1) * na], na);
}


void RCS_show_blk_complex(const char *prefix, const char *posfix) {
    char buf[1024];
    sprintf(buf, RCS_CCFMT, prefix, 1.0f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f, posfix);
    for (int i=(int)strlen(prefix); i<strlen(buf)-strlen(posfix); i++) {
        if (buf[i] == '.' && buf[i+1] == '0') {
            buf[i] = ':';
        } else {
            buf[i] = ' ';
        }
    }
    printf("%s", buf);
}


void RCS_show_row_complex(const char *prefix, const char *posfix, const float *r, const float *i, const int n) {
    printf(RCS_CCFMT, prefix, r[0], i[0], r[1], i[1], r[2], i[2], r[n-1], i[n-1], posfix);
}


void RCS_show_slice_complex(const float *values_real, const float *values_imag, const int na, const int nb) {
    RCS_show_row_complex("  [ ", " ]\n", &values_real[0], &values_imag[0], na);
    RCS_show_row_complex("  [ ", " ]\n", &values_real[na], &values_imag[na], na);
    RCS_show_row_complex("  [ ", " ]\n", &values_real[2 * na], &values_imag[2 * na], na);
    RCS_show_blk_complex("  [ ", " ]\n");
    RCS_show_row_complex("  [ ", " ]\n\n", &values_real[(nb - 1) * na], &values_imag[(nb - 1) * na], na);
}


RCSHandle *RCS_init_with_config_path(const RCSConfig config, const char *path) {
    
    char search_paths[10][1024] = {"./rcs"};
    
    if (path == NULL) {
        char cwd[1024];
        if (getcwd(cwd, sizeof(cwd)) == NULL) {
            fprintf(stderr, "Error in getcwd()\n");
            return NULL;
        }
        snprintf(search_paths[1], 1024, "%s/%s", cwd, "Contents/Resources/rcs");
    } else {
        snprintf(search_paths[1], 1024, "%s", path);
    }
    
    char *ctmp = getenv("HOME");
    if (ctmp != NULL) {
        snprintf(search_paths[2], 1024, "%s/Downloads/tables", ctmp);
    }
    
    struct stat path_stat;
    struct stat file_stat;
    char *dat_path = NULL;
    char dat_file_path[1024];
    int dir_ret;
    int file_ret;
    int found_dir = 0;
    
    for (int i=0; i<3; i++) {
        dat_path = search_paths[i];
        snprintf(dat_file_path, 1024, "%s/%s.rcs", dat_path, config);
        dir_ret = stat(dat_path, &path_stat);
        file_ret = stat(dat_file_path, &file_stat);
        if (dir_ret < 0 || file_ret < 0) {
            continue;
        }
        //printf("testing %s (%d)  %s (%d)\n", dat_path, S_ISDIR(path_stat.st_mode), dat_file_path, S_ISREG(file_stat.st_mode));
        if (dir_ret == 0 && S_ISDIR(path_stat.st_mode) && S_ISREG(file_stat.st_mode)) {
            
            #ifdef DEBUG
            printf("Found RCS folder @ %s\n", dat_path);
            #endif
            
            found_dir = 1;
            break;
        }
    }
    if (found_dir == 0) {
        fprintf(stderr, "Unable to find the RCS data folder.\n");
        return NULL;
    }
    
    // Initialize a memory location for the handler
    RCSMem *h = (RCSMem *)malloc(sizeof(RCSMem));
    if (h == NULL) {
        fprintf(stderr, "Unable to allocate resources for RCS framework.\n");
        return NULL;
    }
    
    // Full path of the data file
    snprintf(h->data_path, sizeof(h->data_path), "%s/%s.rcs", dat_path, config);
    
    FILE *fid = fopen(h->data_path, "r");
    if (fid == NULL) {
        fprintf(stderr, "Error opening file.\n");
        return NULL;
    }
    
    // Allocate the data grid
    h->data_grid = (RCSGrid *)malloc(sizeof(RCSGrid));
    if (h->data_grid == NULL) {
        fprintf(stderr, "Error allocating table (RCSGrid).\n");
        fclose(fid);
        return NULL;
    }
    h->data_grid->rev = 1;
    uint16_t nbna[2];
    fread(nbna, sizeof(uint16_t), 2, fid);
    h->data_grid->na = nbna[0];  // x-axis = alpha
    h->data_grid->nb = nbna[1];  // y-axis = beta
    if (h->data_grid->na == 0 || h->data_grid->nb == 0) {
        fprintf(stderr, "None of the grid elements can be zero.\n");
        fclose(fid);
        return NULL;
    }
    
    #ifdef DEBUG
    printf("%s    na = %d    nb = %d\n", h->data_path, h->data_grid->na, h->data_grid->nb);
    #endif
    
    h->data_grid->a = (float *)malloc(h->data_grid->na * sizeof(float));
    h->data_grid->b = (float *)malloc(h->data_grid->nb * sizeof(float));
    
    uint16_t i;
    
    for (i=0; i<h->data_grid->na; i++) {
        h->data_grid->a[i] = (float)i / (float)(h->data_grid->na - 1) * 360.0f - 180.0f;
    }
    for (i=0; i<h->data_grid->nb; i++) {
        h->data_grid->b[i] = (float)i / (float)(h->data_grid->nb - 1) * 180.0f;
    }
    
    // Allocate data table
    h->data_value = (RCSTable *)malloc(sizeof(RCSTable));
    if (h->data_value == NULL) {
        fprintf(stderr, "Error allocating table (RCSTable).\n");
        fclose(fid);
        return NULL;
    }
    h->data_value->na = h->data_grid->na;
    h->data_value->nb = h->data_grid->nb;
    h->data_value->nn = h->data_grid->na * h->data_grid->nb;
    h->data_value->a = h->data_grid->a;
    h->data_value->b = h->data_grid->b;
    h->data_value->hh_real = (float *)malloc(h->data_value->nn * sizeof(float));
    h->data_value->vv_real = (float *)malloc(h->data_value->nn * sizeof(float));
    h->data_value->hv_real = (float *)malloc(h->data_value->nn * sizeof(float));
    h->data_value->hh_imag = (float *)malloc(h->data_value->nn * sizeof(float));
    h->data_value->vv_imag = (float *)malloc(h->data_value->nn * sizeof(float));
    h->data_value->hv_imag = (float *)malloc(h->data_value->nn * sizeof(float));
    
    // Fill in the table
    fread(h->data_value->hh_real, sizeof(float), h->data_value->nn, fid);
    fread(h->data_value->vv_real, sizeof(float), h->data_value->nn, fid);
    fread(h->data_value->hv_real, sizeof(float), h->data_value->nn, fid);
    fread(h->data_value->hh_imag, sizeof(float), h->data_value->nn, fid);
    fread(h->data_value->vv_imag, sizeof(float), h->data_value->nn, fid);
    fread(h->data_value->hv_imag, sizeof(float), h->data_value->nn, fid);
    
    fclose(fid);
    
    return (RCSHandle *)h;
}


RCSHandle *RCS_init(void) {
    return RCS_init_with_config_path(RCSConfigLeaf, "rcs");
}


void RCS_free(RCSHandle *i) {
    RCSMem *h = (RCSMem *)i;
    free(h->data_value->hh_real);
    free(h->data_value->vv_real);
    free(h->data_value->hv_real);
    free(h->data_value->hh_imag);
    free(h->data_value->vv_imag);
    free(h->data_value->hv_imag);
    free(h->data_value);
    free(h->data_grid->a);
    free(h->data_grid->b);
    free(h->data_grid);
    free(h);
}


RCSTable *RCS_get_frame(const RCSHandle *i) {
    RCSMem *h = (RCSMem *)i;
    return h->data_value;
}


char *RCS_data_path(const RCSHandle *i) {
    RCSMem *h = (RCSMem *)i;
    return h->data_path;
}


void RCS_show_table_summary(const RCSTable *T) {
    printf(" alpha =\n");
    RCS_show_row("  [ ", " ]\n\n", T->a, T->na);
    
    printf(" beta =\n");
    RCS_show_row("  [ ", " ]\n\n", T->b, T->nb);
    
    printf(" hh =\n");
    RCS_show_slice_complex(T->hh_real, T->hh_imag, T->na, T->nb);
    
    printf(" vv =\n");
    RCS_show_slice_complex(T->vv_real, T->vv_imag, T->na, T->nb);
    
    printf(" hv =\n");
    RCS_show_slice_complex(T->hv_real, T->hv_imag, T->na, T->nb);
}
