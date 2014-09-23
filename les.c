//
//  les.c
//  Radar Simulation Framework
//
//  Created by Boon Leng Cheong on 4/7/14.
//  Copyright (c) 2014 Boon Leng Cheong. All rights reserved.
//

#include "les.h"

#define LES_num           20
#define LES_file_nblock   10

// Private structure

typedef struct _les_mem {
    char data_path[1024];
    char files[LES_num/LES_file_nblock+1][1024];
	LESGrid *enclosing_grid;
	LESGrid *data_grid;
	int ibuf;
	float tr;
	size_t data_id[LES_num];
	LESTable *data_boxes[LES_num];
} LESMem;

// Private functions
void show_row(const char *prefix, const char *posfix, const float *f, const int n);
void show_slice(const float *values, const int nx, const int ny, const int nz);
void show_volume(const float *values, const int nx, const int ny, const int nz);
void show_dots(const char *prefix, const char *posfix);
void show_slice_dots(void);

//LESTable *LES_table_from_file(const char *grid_filename, const char *table_filename);
LESGrid *LES_enclosing_grid_create_from_file(const char *filename);
LESGrid *LES_data_grid_create_from_enclosing_grid(LESGrid *grid);
void LES_grid_free(LESGrid *grid);
void LES_show_grid_summary(const LESGrid *grid);

LESTable *LES_table_create(const LESGrid *grid);
void LES_table_free(LESTable *table);

//void LES_table_fill(LESTable *table, const LESGrid *grid, const char *filename);


#define FMT   "%+8.4f"
#define CFMT  "%s" FMT " " FMT "  " FMT " .. " FMT "%s"
void show_row(const char *prefix, const char *posfix, const float *f, const int n) {
	printf(CFMT, prefix, f[0], f[1], f[2], f[n-1], posfix);
}


void show_slice(const float *values, const int nx, const int s, const int nz) {
    show_row("  [ ", " ]", &values[0], nx);
	show_row("  [ ", " ]", &values[s], nx);
	show_row("  [ ", " ]  ..", &values[2 * s], nx);
	show_row("  [ ", " ]\n", &values[(nz - 1) * s], nx);
}


void show_volume(const float *values, const int nx, const int ny, const int nz) {
	int o = 0;
	int s = nx * ny;
		
	o = 0;                show_slice(&values[o], nx, s, nz);
	o = nx;               show_slice(&values[o], nx, s, nz);
	o = 2 * nx;           show_slice(&values[o], nx, s, nz);
	
	show_slice_dots();

	o = (ny - 1) * nx;    show_slice(&values[o], nx, s, nz);
	
	printf("\n");
}


void show_dots(const char *prefix, const char *posfix) {
	char buf[1024];
	sprintf(buf, CFMT, prefix, 1.0f, 1.0f, 1.0f, 1.0f, posfix);
	for (int i=(int)strlen(prefix); i<strlen(buf)-strlen(posfix); i++) {
		if (buf[i] == '.' && buf[i+1] == '0') {
			buf[i] = ':';
		} else {
			buf[i] = ' ';
		}
	}
	printf("%s", buf);
}

void show_slice_dots() {
	show_dots("  [ ", " ]");
	show_dots("  [ ", " ]");
	show_dots("  [ ", " ]  ..");
	show_dots("  [ ", " ]\n");
}


LESGrid *LES_enclosing_grid_create_from_file(const char *filename) {
	LESGrid *grid = (LESGrid *)malloc(sizeof(LESGrid));
	if (grid == NULL) {
		fprintf(stderr, "Unable to allocate LES grid.\n");
		return NULL;
	}
	FILE *fid = fopen(filename, "r");
	if (fid == NULL) {
        free(grid);
		return NULL;
	}
	fread(grid, 1, 16, fid);
	// Now, we know how many the cell counts
	size_t count = grid->nx * grid->ny * grid->nz;
	grid->x = (float *)malloc(count * sizeof(float));
	grid->y = (float *)malloc(count * sizeof(float));
	grid->z = (float *)malloc(count * sizeof(float));
	if (grid->x == NULL || grid->y == NULL || grid->z == NULL) {
		fprintf(stderr, "Error allocating memory for grid values.\n");
		return NULL;
	}
	fseek(fid, 2 * sizeof(float), SEEK_CUR);
	fread(grid->x, sizeof(float), count, fid);
	fseek(fid, 2 * sizeof(float), SEEK_CUR);
	fread(grid->y, sizeof(float), count, fid);
	fseek(fid, 2 * sizeof(float), SEEK_CUR);
	fread(grid->z, sizeof(float), count, fid);
	fclose(fid);
	
	return grid;
}


LESGrid *LES_data_grid_create_from_enclosing_grid(LESGrid *grid) {
	LESGrid *subgrid = (LESGrid *)malloc(sizeof(LESGrid));
	// Sub-domain size
	subgrid->nx = grid->nx - 30;
	subgrid->ny = grid->ny - 30;
	subgrid->nz = 51;
	size_t count = subgrid->nx * subgrid->ny * subgrid->nz;
	subgrid->x = (float *)malloc(count * sizeof(float));
	subgrid->y = (float *)malloc(count * sizeof(float));
	subgrid->z = (float *)malloc(count * sizeof(float));
	if (grid->x == NULL || grid->y == NULL || grid->z == NULL) {
		fprintf(stderr, "Error allocating memory for [LESGrid] values.\n");
        free(subgrid);
		return NULL;
	}
	int k = 0;
	float s = 250.0f * 250.0f / 9.8f;
	for (int iz = 0; iz < 51; iz++) {
		for (int iy = 0; iy < grid->ny - 30; iy++) {
			size_t o = iz * grid->ny * grid->nx + (iy + 14) * grid->nx + 14;
			for (int i=0; i<grid->nx - 30; i++) {
				subgrid->x[k] = grid->x[i + o] * s;
				subgrid->y[k] = grid->y[i + o] * s;
				subgrid->z[k] = grid->z[i + o] * s;
				k++;
			}
		}
	}
	return subgrid;
}


void LES_grid_free(LESGrid *grid) {
	free(grid->x);
	free(grid->y);
	free(grid->z);
	free(grid);
}


void LES_show_grid_summary(const LESGrid *grid) {
	size_t count = grid->nx * grid->ny * grid->nz;
	printf("%d x %d x %d = %zu\n", grid->nx, grid->ny, grid->nz, count);

	printf(" x =\n");
	show_volume(grid->x, grid->nx, grid->ny, grid->nz);

	printf(" y =\n");
	show_volume(grid->y, grid->nx, grid->ny, grid->nz);
	
	printf(" z =\n");
	show_volume(grid->z, grid->nx, grid->ny, grid->nz);
}


LESTable *LES_table_create(const LESGrid *grid) {
	LESTable *table = (LESTable *)malloc(sizeof(LESTable));
	if (table == NULL) {
		fprintf(stderr, "Error allocating table.\n");
		return NULL;
	}
	table->nx = grid->nx;
	table->ny = grid->ny;
	table->nz = grid->nz;
	table->nn = grid->nz * grid->ny * grid->nx;
	table->nt = LES_file_nblock;
	table->x = grid->x;
	table->y = grid->y;
	table->z = grid->z;
	table->u = (float *)malloc(table->nn * sizeof(float));
	table->v = (float *)malloc(table->nn * sizeof(float));
	table->w = (float *)malloc(table->nn * sizeof(float));
	table->p = (float *)malloc(table->nn * sizeof(float));
	table->t = (float *)malloc(table->nn * sizeof(float));
	if (table->u == NULL || table->v == NULL || table->w == NULL || table->p == NULL || table->t == NULL) {
		fprintf(stderr, "Error allocating memory for [LESTable] values.\n");
        free(table);
		return NULL;
	}
	return table;
}


void LES_table_free(LESTable *table) {
	// NOTE: table->u, table->v & table->w are allocated but
	//       table->x, table->y & table->z are assigned to grid->x, grid->y & grid->z
	free(table->u);
	free(table->v);
	free(table->w);
	free(table->p);
	free(table->t);
	free(table);
}


void LES_show_table_summary(const LESTable *table) {
	
	printf(" u =\n");
	show_volume(table->u, table->nx, table->ny, table->nz);

	printf(" v =\n");
	show_volume(table->v, table->nx, table->ny, table->nz);

	printf(" w =\n");
	show_volume(table->w, table->nx, table->ny, table->nz);

//	printf(" p =\n");
//	show_volume(table->p, table->nx, table->ny, table->nz);
//
	printf(" t =\n");
	show_volume(table->t, table->nx, table->ny, table->nz);
}


LESHandle *LES_init_with_config_path(const LESConfig config, const char *path) {
    // Find the path
    char cwd[1024];
    if (getcwd(cwd, sizeof(cwd)) == NULL)
        fprintf(stderr, "Error in getcwd()\n");
    
    char search_paths[10][1024] = {"./les"};
	
    if (path == NULL) {
        snprintf(search_paths[1], 1024, "%s/%s", cwd, "Contents/Resources/les");
    } else {
		snprintf(search_paths[1], 1024, "%s/%s", path, "les");
    }

	char *ctmp = getenv("HOME");
	if (ctmp != NULL) {
		printf("HOME = %s\n", ctmp);
		snprintf(search_paths[2], 1024, "%s/Desktop/les", ctmp);
		snprintf(search_paths[3], 1024, "%s/Douments/les", ctmp);
		snprintf(search_paths[4], 1024, "%s/Downloads/les", ctmp);
	}
	
    struct stat path_stat, file_stat;
    char *les_path, les_file_path[1024];
    int dir_ret, file_ret;
    for (int i=0; i<sizeof(search_paths)/sizeof(search_paths[0]); i++) {
        les_path = search_paths[i];
		snprintf(les_file_path, 1024, "%s/twocell/fort.10_2", les_path);
        dir_ret = stat(les_path, &path_stat);
		file_ret = stat(les_file_path, &file_stat);
        if (dir_ret == 0 && S_ISDIR(path_stat.st_mode) && S_ISREG(file_stat.st_mode)) {

//#ifdef DEBUG
            printf("Found LES folder @ %s\n", les_path);
//#endif

            break;
        }
    }
    if (dir_ret < 0) {
        fprintf(stderr, "Unable to find the LES data folder.\n");
        return NULL;
    }
	
    // Initialize a memory location for the handler
	LESMem *h = (LESMem *)malloc(sizeof(LESMem));
	if (h == NULL) {
		fprintf(stderr, "Unable to allocate resources for LES framework.\n");
		return NULL;
	}
    
    snprintf(h->data_path, sizeof(h->data_path), "%s/%s", les_path, config);
	h->ibuf = 0;
	h->tr = 50.0f;
    
    char grid_file[1024];
    snprintf(grid_file, 1024, "%s/fort.10_2", h->data_path);
    
#ifdef DEBUG
    printf("index @ %s\n", grid_file);
#endif
    
	h->enclosing_grid = LES_enclosing_grid_create_from_file(grid_file);
	h->data_grid = LES_data_grid_create_from_enclosing_grid(h->enclosing_grid);
	
    const int file_count = LES_num / LES_file_nblock;
    
    for (int k=0; k<file_count; k++) {
        snprintf(h->files[k], sizeof(h->files[k]), "%s/LES_mean_1_6_fnum%d.dat", h->data_path, k + 1);
    }
    
	// Allocate data boxes
	for (int i=0; i<LES_num; i++) {
		h->data_boxes[i] = LES_table_create(h->data_grid);
		h->data_boxes[i]->tr = h->tr;
		h->data_id[i] = (size_t)-1;
	}
	return (LESHandle *)h;
}

LESHandle *LES_init() {
    return LES_init_with_config_path(LESConfigTwoCell, NULL);
}


LESTable *LES_get_frame(LESHandle *i, const int n) {
	LESTable *table;
	LESMem *h = (LESMem *)i;

	const float v0 = 250.0f;
	
	int k = 0;
	while (n != h->data_id[k] && k < LES_num) {
		k++;
	}
	
	// If it is a table that has been ingested and still in the cache, just return it.
	if (k < LES_num && h->data_id[k] == n) {
		return h->data_boxes[k];
	} else {
		// Need to read in
		int file_id = n / LES_file_nblock;


#ifdef DEBUG
		printf("Ingest from file %s ...\n", table_file[file_id]);
#endif

		// Derive filename to ingest a set of LESTables
        FILE *fid = fopen(h->files[file_id], "r");
		if (fid == NULL) {
			return NULL;
		}
		
		// First 32-bit is probably some kind of revision number
		uint32_t ver;
		fread(&ver, sizeof(uint32_t), 1, fid);
//		printf("ver = %d\n", ver);
		
		float time;
		int saved_ibuf = h->ibuf;

		// Read in all blocks since there is only a small number of them.
		for (int b=0; b<LES_file_nblock; b++) {

#ifdef DEBUG
			printf("Reading new LES table in data_boxes[%d] ...\n", h->ibuf);
#endif

			h->data_id[h->ibuf] = file_id * LES_file_nblock + b;
			
			table = h->data_boxes[h->ibuf];
			
			fread(&time, sizeof(float), 1, fid);
			fseek(fid, 2 * sizeof(uint32_t), SEEK_CUR);

			// printf("time = %.4f\n", time * v0 / g);

			//LES_show_grid_summary(h->data_grid);
			

			fread(table->u, sizeof(float), table->nn, fid);
			fseek(fid, 2 * sizeof(int32_t), SEEK_CUR);

			fread(table->v, sizeof(float), table->nn, fid);
			fseek(fid, 2 * sizeof(int32_t), SEEK_CUR);

			fread(table->w, sizeof(float), table->nn, fid);
			fseek(fid, 2 * sizeof(int32_t), SEEK_CUR);

			fread(table->p, sizeof(float), table->nn, fid);
			fseek(fid, 2 * sizeof(int32_t), SEEK_CUR);

			fread(table->t, sizeof(float), table->nn, fid);
			fseek(fid, 2 * sizeof(int32_t), SEEK_CUR);
			
			for (int k=0; k<table->nn; k++) {
				table->u[k] *= v0;
				table->v[k] *= v0;
				table->w[k] *= v0;
				table->p[k] *= v0 * v0;
				table->t[k] *= v0 * v0;
			}
			
			h->ibuf = h->ibuf == LES_num - 1 ? 0 : h->ibuf + 1;
		}
		
		fclose(fid);
		
		table = h->data_boxes[saved_ibuf];
	}
	
	return table;
}


void LES_free(LESHandle *i) {
	LESMem *h = (LESMem *)i;
	LES_grid_free(h->enclosing_grid);
	LES_grid_free(h->data_grid);
	for (int i=0; i<LES_num; i++) {
		LES_table_free(h->data_boxes[i]);
	}
	free(h);
}
