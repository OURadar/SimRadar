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
    RCSTable table[256];
    int count;
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


RCSHandle RCS_init(void) {
    return RCS_init_with_path("rcs");
}


RCSHandle RCS_init_with_path(const char *path) {
    char search_paths[10][1024] = {"./rcs"};

    int k = 0;
    if (path == NULL) {
        char cwd[1024];
        if (getcwd(cwd, sizeof(cwd)) == NULL) {
            fprintf(stderr, "Error in getcwd()\n");
            return NULL;
        }
        snprintf(search_paths[k++], 1024, "%s/%s", cwd, "Contents/Resources/rcs");
    } else {
        snprintf(search_paths[k++], 1024, "%s", path);
    }
    
    char *ctmp = getenv("HOME");
    if (ctmp != NULL) {
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
        snprintf(dat_file_path, 1024, "%s/%s.rcs", dat_path, RCSConfigLeaf);
        dir_ret = stat(dat_path, &path_stat);
        file_ret = stat(dat_file_path, &file_stat);
        if (dir_ret < 0 || file_ret < 0) {
            continue;
        }
        //printf("testing %s (%d)  %s (%d)\n", dat_path, S_ISDIR(path_stat.st_mode), dat_file_path, S_ISREG(file_stat.st_mode));
        if (dir_ret == 0 && S_ISDIR(path_stat.st_mode) && S_ISREG(file_stat.st_mode)) {
            
            #ifdef DEBUG
            rsprint("Found RCS folder @ %s\n", dat_path);
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
    snprintf(h->data_path, sizeof(h->data_path), "%s", dat_path);
    
    // No table has been loaded yet
    h->count = 0;

    return (RCSHandle *)h;
}

void RCS_free(RCSHandle i) {
    RCSMem *h = (RCSMem *)i;
    for (int i=0; i<h->count; i++) {
        // Free each table that has been allocated previously
        RCSTable *table = &h->table[i];
        free(table->data.a);
        free(table->data.b);
        free(table->data.hh_real);
        free(table->data.vv_real);
        free(table->data.hv_real);
        free(table->data.hh_imag);
        free(table->data.vv_imag);
        free(table->data.hv_imag);
    }
    free(h);
}


RCSTable *RCS_get_table(const RCSHandle in, const RCSConfig config) {
    RCSMem *h = (RCSMem *)in;
    
    int i;

    // Full path of the data file
    char fullpath[1024];
    snprintf(fullpath, sizeof(fullpath), "%s/%s.rcs", h->data_path, config);
    
    // Now, we open the file for reading
    FILE *fid = fopen(fullpath, "r");
    if (fid == NULL) {
        fprintf(stderr, "Error opening file %s.\n", fullpath);
        return NULL;
    }

    // The first two 16-bit numbers are the grid dimensions
    uint16_t nbna[2];
    fread(nbna, sizeof(uint16_t), 2, fid);
    
    // Get the table pointer from the handler
    RCSTable *table = &h->table[h->count];
    
    // Populate the dimension details
    table->na = nbna[0];  // x-axis = alpha
    table->nb = nbna[1];  // y-axis = beta
    table->nn = table->na * table->nb;
    if (h->table->nn == 0) {
        fprintf(stderr, "Empty table (RCSTable)?\n");
        fclose(fid);
        return NULL;
    }
    table->lambda = 0.1f;

    // Allocate the space needed
    table->data.a = (float *)malloc(table->na * sizeof(float));
    table->data.b = (float *)malloc(table->nb * sizeof(float));
    table->data.hh_real = (float *)malloc(table->nn * sizeof(float));
    table->data.vv_real = (float *)malloc(table->nn * sizeof(float));
    table->data.hv_real = (float *)malloc(table->nn * sizeof(float));
    table->data.hh_imag = (float *)malloc(table->nn * sizeof(float));
    table->data.vv_imag = (float *)malloc(table->nn * sizeof(float));
    table->data.hv_imag = (float *)malloc(table->nn * sizeof(float));
    
    // Fill in the table
    snprintf(table->name, 1024, "%s", config);
    snprintf(table->path, 1024, "%s", fullpath);
    for (i=0; i<table->na; i++) {
        table->data.a[i] = (float)i / (float)(table->na - 1) * 360.0f - 180.0f;
    }
    for (i=0; i<table->nb; i++) {
        table->data.b[i] = (float)i / (float)(table->nb - 1) * 180.0f;
    }
    fread(table->data.hh_real, sizeof(float), table->nn, fid);
    fread(table->data.vv_real, sizeof(float), table->nn, fid);
    fread(table->data.hv_real, sizeof(float), table->nn, fid);
    fread(table->data.hh_imag, sizeof(float), table->nn, fid);
    fread(table->data.vv_imag, sizeof(float), table->nn, fid);
    fread(table->data.hv_imag, sizeof(float), table->nn, fid);
    
    h->count++;

    fclose(fid);
    
    return table;
}


char *RCS_data_path(const RCSHandle i) {
    RCSMem *h = (RCSMem *)i;
    return h->data_path;
}


void RCS_show_table_summary(const RCSTable *T) {
    printf(" alpha =\n");
    RCS_show_row("  [ ", " ]\n\n", T->data.a, T->na);
    
    printf(" beta =\n");
    RCS_show_row("  [ ", " ]\n\n", T->data.b, T->nb);
    
    printf(" hh =\n");
    RCS_show_slice_complex(T->data.hh_real, T->data.hh_imag, T->na, T->nb);
    
    printf(" vv =\n");
    RCS_show_slice_complex(T->data.vv_real, T->data.vv_imag, T->na, T->nb);
    
    printf(" hv =\n");
    RCS_show_slice_complex(T->data.hv_real, T->data.hv_imag, T->na, T->nb);
}
