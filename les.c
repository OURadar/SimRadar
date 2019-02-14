//
//  les.c
//  Radar Simulation Framework
//
//  Created by Boon Leng Cheong on 4/7/14.
//  Copyright (c) 2014 Boon Leng Cheong. All rights reserved.
//

#include "les.h"

#define LES_num                     4
#define LES_file_nblock             10
#define LES_FMT                     "%+8.4f"
#define LES_CFMT                    "%s" LES_FMT " " LES_FMT "  " LES_FMT " .. " LES_FMT "%s"
#define LES_FRAME_TIME_STAMP_BYTES  4
#define LES_FRAME_PADDING_BYTES     8

// Private structure

typedef struct _les_mem {
    char      config[256];
    char      data_path[1024];
    char      files[1024][1024];
    size_t    nfiles;
    size_t    nvol;
    size_t    ncubes;
	LESGrid   *enclosing_grid;
	LESGrid   *data_grid;
	int       ibuf;
	float     tr;
    float     tp;
    float     v0;
    float     p0;
    float     t0;
    float     ax;             // Base value "a" in geometric series a r ^ n in x direction
    float     ay;             // Base value "a" in geometric series a r ^ n in y direction
    float     az;             // Base value "a" in geometric series a r ^ n in z direction
    float     rx;             // Ratio value "r" in the geometric series in x direction
    float     ry;             // Ratio value "r" in the geometric series in y direction
    float     rz;             // Ratio value "r" in the geometric series in z direction
	int       data_id[LES_num];
	LESTable  *data_boxes[LES_num];
    pthread_t tid;
    bool      active;
    bool      delayed_read;
    int       req;
} LESMem;

// Private functions
void *LES_background_read(LESHandle i);

void LES_show_row(const char *prefix, const char *posfix, const float *f, const int n);
void LES_show_slice(const float *values, const int nx, const int ny, const int nz);
void LES_show_volume(const float *values, const int nx, const int ny, const int nz);
void LES_show_dots(const char *prefix, const char *posfix);
void LES_show_slice_dots(void);

//LESTable *LES_table_from_file(const char *grid_filename, const char *table_filename);
LESGrid *LES_enclosing_grid_create_from_file(const char *filename);
LESGrid *LES_data_grid_create_from_enclosing_grid(LESGrid *grid, const int ox, const int oy);
void LES_grid_free(LESGrid *grid);
void LES_show_grid_summary(const LESGrid *grid);

LESTable *LES_table_create(const LESGrid *grid);
void LES_table_free(LESTable *table);

//void LES_table_fill(LESTable *table, const LESGrid *grid, const char *filename);

#pragma mark -

LESHandle LES_init_with_config_path(const LESConfig config, const char *path) {
    // Find the path
    char cwd[1024];
    if (getcwd(cwd, sizeof(cwd)) == NULL)
        fprintf(stderr, "Error in getcwd()\n");

    // 10 search paths with the first one being the relative subfolder 'les'
    char search_paths[10][1024] = {"./les"};

    int k = 0;
    if (path == NULL) {
        snprintf(search_paths[k++], 1024, "%s/%s", cwd, "Contents/Resources/les");
    } else {
        snprintf(search_paths[k++], 1024, "%s/%s", path, "tables");
    }

    char *ctmp = getenv("HOME");
    if (ctmp != NULL) {
        //printf("HOME = %s\n", ctmp);
        snprintf(search_paths[k++], 1024, "%s/Documents/tables", ctmp);
        snprintf(search_paths[k++], 1024, "%s/Downloads/tables", ctmp);
        snprintf(search_paths[k++], 1024, "%s/Desktop/les", ctmp);
        snprintf(search_paths[k++], 1024, "%s/Documents/les", ctmp);
        snprintf(search_paths[k++], 1024, "%s/Downloads/les", ctmp);
    }

    struct stat path_stat;
    struct stat file_stat;
    char *les_path = NULL;
    char les_file_path[1024];
    int dir_ret;
    int file_ret;
    int found_dir = 0;

    for (int i = 0; i < sizeof(search_paths) / sizeof(search_paths[0]); i++) {
        les_path = search_paths[i];
        snprintf(les_file_path, 1024, "%s/les/%s/fort.10_2", les_path, config);
        dir_ret = stat(les_path, &path_stat);
        file_ret = stat(les_file_path, &file_stat);
        if (dir_ret < 0 || file_ret < 0) {
            continue;
        }
        if (dir_ret == 0 && S_ISDIR(path_stat.st_mode) && S_ISREG(file_stat.st_mode)) {

            #ifdef DEBUG
            rsprint("Found LES folder @ %s\n", les_path);
            #endif

            found_dir = 1;
            break;
        }
    }
    if (found_dir == 0 || les_path == NULL) {
        fprintf(stderr, "Unable to find the LES data folder.\n");
        return NULL;
    }

    // Initialize a memory location for the handler
    LESMem *h = (LESMem *)malloc(sizeof(LESMem));
    if (h == NULL) {
        fprintf(stderr, "Unable to allocate resources for LES framework.\n");
        return NULL;
    }
    memset(h, 0, sizeof(LESMem));

    snprintf(h->config, sizeof(h->config), "%s", config);
    snprintf(h->data_path, sizeof(h->data_path), "%s/les/%s", les_path, config);
    h->ibuf = 0;
    h->tr = 50.0f;

    //    char grid_file[1024];
    //    snprintf(grid_file, 1024, "%s/fort.10_2", h->data_path);

    #ifdef DEBUG
    rsprint("LES index @ %s\n", les_file_path);
    #endif

    h->enclosing_grid = LES_enclosing_grid_create_from_file(les_file_path);
    if (h->enclosing_grid == NULL) {
        fprintf(stderr, "Unable to get the enclosing grid for LES framework.\n");
        return NULL;
    }
    rsprint("LES enclosing_grid = %u x %u x %u\n", h->enclosing_grid->nx, h->enclosing_grid->ny, h->enclosing_grid->nz);

    // Extract only a sub-domain at a given origin. This is not complete, will come back for it.
    h->data_grid = LES_data_grid_create_from_enclosing_grid(h->enclosing_grid, 0, 0);

    // Override if needed
    if (!strcmp(config, LESConfigSuctionVortices) || !strcmp(config, LESConfigSuctionVorticesLarge)) {
        // Stretched grid
        h->v0 = 100.0f;
        h->p0 = h->v0 * h->v0;
        h->t0 = h->v0 * h->v0;
        h->ax = 2.0f;
        h->ay = 2.0f;
        h->az = 2.0f;
        h->rx = 1.0212f;
        h->ry = 1.0212f;
        h->rz = 1.05f;
        h->tp = 2.0f;
        h->data_grid->is_stretched = true;
    } else if (!strcmp(config, LESConfigTwoCell)) {
        h->v0 = 225.0f;
        h->p0 = h->v0 * h->v0;
        h->t0 = h->v0 * h->v0;
        h->ax = 1.0f;
        h->ay = 1.0f;
        h->az = 1.0f;
        h->rx = 1.0f;
        h->ry = 1.0f;
        h->rz = 1.0f;
        h->tp = 5.0f;
    } else if (!strcmp(config, LESConfigFlat)) {
        h->v0 = 25.0f;
        h->p0 = 1.0f;                 // p is used as cn2
        h->t0 = h->v0 * h->v0;
        h->ax = 0.0f;
        h->ay = 0.0f;
        h->az = 0.0f;
        h->rx = 1.0e3f * (h->data_grid->x[1]                                   - h->data_grid->x[0]);
        h->ry = 1.0e3f * (h->data_grid->y[h->data_grid->nx]                    - h->data_grid->y[0]);
        h->rz = 1.0e3f * (h->data_grid->z[h->data_grid->nx * h->data_grid->ny] - h->data_grid->z[0]);
        h->tp = 60.0f;
    } else {
        h->v0 = 100.0f;
        h->p0 = h->v0 * h->v0;
        h->t0 = h->v0 * h->v0;
        h->ax = 1.0f;
        h->ay = 1.0f;
        h->az = 1.0f;
        h->rx = 1.0f;
        h->ry = 1.0f;
        h->rz = 1.0f;
        h->tp = 5.0f;
    }
    rsprint("LES grid spacing = %.2f / %.2f   %.2f / %.2f   %.2f / %.2f  (%s)\n",
            h->ax, h->rx,
            h->ay, h->ry,
            h->az, h->rz,
            h->data_grid->is_stretched ? "streched" : "uniform");

    // Go through and check available tables
    k = 0;
    while (true) {
        snprintf(h->files[k], sizeof(h->files[k]), "%s/LES_mean_1_6_fnum%d.dat", h->data_path, k + 1);
        if (access(h->files[k], F_OK) != -1) {
            if (h->nfiles == 0) {
                // Use the first file to derive the number of volumes in a file
                file_ret = stat(h->files[k], &file_stat);
                if (file_ret == 0) {
                    size_t s = file_stat.st_size;
                    // 5 variables: u, v, w, p, t
                    size_t nn = h->enclosing_grid->nx * h->enclosing_grid->ny * h->enclosing_grid->nz * 5;
                    h->nvol = s / (LES_FRAME_TIME_STAMP_BYTES + LES_FRAME_PADDING_BYTES + nn * sizeof(float) + LES_FRAME_PADDING_BYTES);
                } else {
                    fprintf(stderr, "Unable to get filesize. Assume %d\n", LES_file_nblock);
                    h->nvol = LES_file_nblock;
                }
                if (h->nvol != LES_file_nblock) {
                    fprintf(stderr, "Each LES data file contains %zu volumes, expected %d.\n", h->nvol, LES_file_nblock);
                }
            }
            h->nfiles++;
        } else {
            break;
        }
        k++;
    }

    h->ncubes = h->nfiles * h->nvol;

    #ifdef DEBUG
    rsprint("LES file count = %zu    nvol = %zu    ncubes = %zu\n", h->nfiles, h->nvol, h->ncubes);
    #endif

    // Allocate data boxes
    for (int i = 0; i < LES_num; i++) {
        h->data_boxes[i] = LES_table_create(h->data_grid);
        if (h->data_boxes[i] == NULL) {
            fprintf(stderr, "[LES] LES_table_create() returned a NULL.\n");
            return NULL;
        }
        h->data_boxes[i]->tr = h->tr;
        h->data_boxes[i]->nc = (uint32_t)h->ncubes;
        h->data_id[i] = -1;
    }

    // Other non-zero parameters
    h->active = true;

    // Background read
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    struct sched_param param;
    param.sched_priority = 99;
    pthread_attr_setschedpolicy(&attr, SCHED_OTHER);
    pthread_attr_setschedparam(&attr, &param);
    if (pthread_create(&h->tid, &attr, LES_background_read, h)) {
        fprintf(stderr, "LES : Error. Unable to create thread.\n");
        exit(EXIT_FAILURE);
    }
    // Wait until one frame is ingested.
    do {
        usleep(10000);
    } while (h->ibuf == 0);
#ifdef DEBUG_HEAVY
    int policy = -1;
    if (pthread_attr_getschedparam(&attr, &param) == 0 &&
        pthread_attr_getschedpolicy(&attr, &policy) == 0) {
        printf("policy=%s  priority=%d\n",
               (policy == SCHED_FIFO)  ? "SCHED_FIFO" :
               (policy == SCHED_RR)    ? "SCHED_RR" :
               (policy == SCHED_OTHER) ? "SCHED_OTHER" :
               "???",
               param.sched_priority);
    }
#endif

    return (LESHandle)h;
}

LESHandle LES_init() {
    return LES_init_with_config_path(LESConfigSuctionVortices, NULL);
}


void LES_free(LESHandle i) {
    LESMem *h = (LESMem *)i;
    h->active = false;
    pthread_join(h->tid, NULL);
    LES_grid_free(h->enclosing_grid);
    LES_grid_free(h->data_grid);
    for (int i=0; i<LES_num; i++) {
        LES_table_free(h->data_boxes[i]);
    }
    free(h);
}

#pragma mark -

void LES_set_delayed_read(LESHandle i) {
    LESMem *h = (LESMem *)i;
    h->delayed_read = true;
}

#pragma mark -

void *LES_background_read(LESHandle i) {
    LESMem *h = (LESMem *)i;
    int frame;
    LESTable *table;

    // Read ahead
    while (h->active) {
        frame = h->req;

        // The file number of the list of files to read
        int file_id = frame / LES_file_nblock;

        #ifdef DEBUG
        rsprint("Background ingest from file %s for frame %d to slot %d ...\n", h->files[file_id], h->req, h->ibuf);
        #endif

        // The table in collection of data boxes
        table = h->data_boxes[h->ibuf];

        // Copy over some base parameters
        table->ax = h->ax;
        table->ay = h->ay;
        table->az = h->az;
        table->rx = h->rx;
        table->ry = h->ry;
        table->rz = h->rz;
        table->tp = h->tp;
        table->tr = h->tr;

        long offset = sizeof(uint32_t) +                     // version number
        (frame % LES_file_nblock) *
        (sizeof(float) + 2 * sizeof(uint32_t)                // time
         + table->nn * sizeof(float) + 2 * sizeof(uint32_t)  // u
         + table->nn * sizeof(float) + 2 * sizeof(uint32_t)  // v
         + table->nn * sizeof(float) + 2 * sizeof(uint32_t)  // w
         + table->nn * sizeof(float) + 2 * sizeof(uint32_t)  // p
         + table->nn * sizeof(float) + 2 * sizeof(uint32_t)  // t
         );

        // Derive filename to ingest a set of LESTables
        FILE *fid = fopen(h->files[file_id], "r");
        if (fid == NULL) {
            fprintf(stderr, "Error opening LES table file %s %d\n", h->files[file_id], file_id);
            return NULL;
        }
        fseek(fid, offset, SEEK_SET);
        // Timestamp of the frame
        fread(table->data.a, sizeof(float), 1, fid);
        fseek(fid, 2 * sizeof(uint32_t), SEEK_CUR);
        // Wind u
        fread(table->data.u, sizeof(float), table->nn, fid);
        fseek(fid, 2 * sizeof(int32_t), SEEK_CUR);
        // Wind v
        fread(table->data.v, sizeof(float), table->nn, fid);
        fseek(fid, 2 * sizeof(int32_t), SEEK_CUR);
        // Wind w
        fread(table->data.w, sizeof(float), table->nn, fid);
        fseek(fid, 2 * sizeof(int32_t), SEEK_CUR);
        // Pressure p
        fread(table->data.p, sizeof(float), table->nn, fid);
        fseek(fid, 2 * sizeof(int32_t), SEEK_CUR);
        // Something t
        fread(table->data.t, sizeof(float), table->nn, fid);
        fseek(fid, 2 * sizeof(int32_t), SEEK_CUR);
        fclose(fid);

        // Scale back & remap
        for (int k = 0; k < table->nn; k++) {
            table->data.u[k] *= h->v0;
            table->data.v[k] *= h->v0;
            table->data.w[k] *= h->v0;
            table->data.p[k] *= h->p0;
            table->data.t[k] *= h->t0;
            table->uvwt[k][0] = table->data.u[k];
            table->uvwt[k][1] = table->data.v[k];
            table->uvwt[k][2] = table->data.w[k];
            table->uvwt[k][3] = table->data.t[k];
        }

        // Record down the frame id
        h->data_id[h->ibuf] = frame;

        // Update the index
        h->ibuf = h->ibuf == LES_num - 1 ? 0 : h->ibuf + 1;

        do {
            usleep(100000);
        } while (h->active && frame == h->req);
        if (h->delayed_read) {
            usleep(200000);
        }
    }
    return NULL;
}

#pragma mark -

void LES_show_row(const char *prefix, const char *posfix, const float *f, const int n) {
	printf(LES_CFMT, prefix, f[0], f[1], f[2], f[n-1], posfix);
}


void LES_show_slice(const float *values, const int nx, const int s, const int nz) {
    LES_show_row("  [ ", " ]", &values[0], nx);
	LES_show_row("  [ ", " ]", &values[s], nx);
	LES_show_row("  [ ", " ]  ..", &values[2 * s], nx);
	LES_show_row("  [ ", " ]\n", &values[(nz - 1) * s], nx);
}


void LES_show_volume(const float *values, const int nx, const int ny, const int nz) {
	int o = 0;
	int s = nx * ny;
		
	o = 0;                LES_show_slice(&values[o], nx, s, nz);
	o = nx;               LES_show_slice(&values[o], nx, s, nz);
	o = 2 * nx;           LES_show_slice(&values[o], nx, s, nz);
	
	LES_show_slice_dots();

	o = (ny - 1) * nx;    LES_show_slice(&values[o], nx, s, nz);
	
	printf("\n");
}


void LES_show_dots(const char *prefix, const char *posfix) {
	char buf[1024];
	sprintf(buf, LES_CFMT, prefix, 1.0f, 1.0f, 1.0f, 1.0f, posfix);
	for (int i=(int)strlen(prefix); i<strlen(buf)-strlen(posfix); i++) {
		if (buf[i] == '.' && buf[i+1] == '0') {
			buf[i] = ':';
		} else {
			buf[i] = ' ';
		}
	}
	printf("%s", buf);
}


void LES_show_slice_dots() {
	LES_show_dots("  [ ", " ]");
	LES_show_dots("  [ ", " ]");
	LES_show_dots("  [ ", " ]  ..");
	LES_show_dots("  [ ", " ]\n");
}


LESGrid *LES_enclosing_grid_create_from_file(const char *filename) {
	LESGrid *grid = (LESGrid *)malloc(sizeof(LESGrid));
    memset(grid, 0, sizeof(LESGrid));
	if (grid == NULL) {
		fprintf(stderr, "Unable to allocate LES grid.\n");
		return NULL;
	}
	FILE *fid = fopen(filename, "r");
	if (fid == NULL) {
        free(grid);
		return NULL;
	}
    // First 4 uint32_t describes the dimensions
	fread(grid, 1, 4 * sizeof(uint32_t), fid);
	// Now, we know how many the cell counts
	size_t count = grid->nx * grid->ny * grid->nz;
    // Allocate spaces for the data
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
	
    #ifdef DEBUG_LES
    printf("x @ %.2f %.2f %.2f ...\n", grid->x[0], grid->x[1], grid->x[2]);
    printf("y @ %.2f %.2f %.2f ...\n", grid->y[0], grid->y[grid->nx], grid->y[2 * grid->nx]);
    printf("z @ %.2f %.2f %.2f ...\n", grid->z[0], grid->z[grid->nx * grid->ny], grid->z[2 * grid->nx * grid->ny]);
    #endif
    
	return grid;
}


LESGrid *LES_data_grid_create_from_enclosing_grid(LESGrid *grid, const int ox, const int oy) {
	LESGrid *subgrid = (LESGrid *)malloc(sizeof(LESGrid));
    memset(subgrid, 0, sizeof(LESGrid));
	// Sub-domain size
	subgrid->nx = grid->nx - (2 * ox);
	subgrid->ny = grid->ny - (2 * oy);
	subgrid->nz = grid->nz;
    subgrid->is_stretched = grid->is_stretched;
	size_t count = subgrid->nx * subgrid->ny * subgrid->nz;
    //fprintf(stderr, "subgrid [ %d %d %d ]\n", subgrid->nx, subgrid->ny, subgrid->nz);
	subgrid->x = (float *)malloc(count * sizeof(float));
	subgrid->y = (float *)malloc(count * sizeof(float));
	subgrid->z = (float *)malloc(count * sizeof(float));
	if (grid->x == NULL || grid->y == NULL || grid->z == NULL) {
		fprintf(stderr, "Error allocating memory for [LESGrid] values.\n");
        free(subgrid);
		return NULL;
	}
	int k = 0;
	for (int iz = 0; iz < subgrid->nz; iz++) {
		for (int iy = 0; iy < subgrid->ny; iy++) {
			size_t o = iz * grid->ny * grid->nx + (iy + oy) * grid->nx + ox;
			for (int i=0; i<subgrid->nx; i++) {
				subgrid->x[k] = grid->x[i + o];
				subgrid->y[k] = grid->y[i + o];
				subgrid->z[k] = grid->z[i + o];
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
	LES_show_volume(grid->x, grid->nx, grid->ny, grid->nz);

	printf(" y =\n");
	LES_show_volume(grid->y, grid->nx, grid->ny, grid->nz);
	
	printf(" z =\n");
	LES_show_volume(grid->z, grid->nx, grid->ny, grid->nz);
}


LESTable *LES_table_create(const LESGrid *grid) {
	LESTable *table = (LESTable *)malloc(sizeof(LESTable));
	if (table == NULL) {
		fprintf(stderr, "Error allocating table (LESTable).\n");
		return NULL;
	}
	table->nx = grid->nx;
	table->ny = grid->ny;
	table->nz = grid->nz;
	table->nn = grid->nz * grid->ny * grid->nx;
	table->nt = LES_file_nblock;
    table->nc = 0;
    table->tr = 1.0f;
    table->tp = 5.0f;
	table->data.x = grid->x;
	table->data.y = grid->y;
	table->data.z = grid->z;
    table->data.a = (float *)malloc(4 * sizeof(float));
	table->data.u = (float *)malloc(table->nn * sizeof(float));
	table->data.v = (float *)malloc(table->nn * sizeof(float));
	table->data.w = (float *)malloc(table->nn * sizeof(float));
	table->data.p = (float *)malloc(table->nn * sizeof(float));
	table->data.t = (float *)malloc(table->nn * sizeof(float));
    table->uvwt = (LESFloat4 *)malloc(table->nn * sizeof(LESFloat4));
	if (table->data.u == NULL || table->data.v == NULL || table->data.w == NULL || table->data.p == NULL || table->data.t == NULL || table->uvwt == NULL) {
        fprintf(stderr, "Error allocating memory for [LESTable] values.\n");
        free(table);
        return NULL;
	}
    memset(table->data.u, 0, table->nn * sizeof(float));
    memset(table->data.v, 0, table->nn * sizeof(float));
    memset(table->data.w, 0, table->nn * sizeof(float));
    memset(table->data.p, 0, table->nn * sizeof(float));
    memset(table->data.t, 0, table->nn * sizeof(float));
    memset(table->uvwt, 0, table->nn * sizeof(LESFloat4));
	return table;
}


void LES_table_free(LESTable *table) {
	// NOTE: table->data.u, table->data.v & table->data.w are allocated but
	//       table->data.x, table->data.y & table->data.z are assigned to grid->data.x, grid->data.y & grid->data.z
    free(table->data.a);
	free(table->data.u);
	free(table->data.v);
	free(table->data.w);
	free(table->data.p);
	free(table->data.t);
    free(table->uvwt);
	free(table);
}


void LES_show_table_summary(const LESTable *table) {

    printf(" time = %.4f   nx = %d   ny = %d   nz = %d   nt = %d\n\n", table->data.a[0], table->nx, table->ny, table->nz, table->nt);
    
	printf(" u =\n");
	LES_show_volume(table->data.u, table->nx, table->ny, table->nz);

	printf(" v =\n");
	LES_show_volume(table->data.v, table->nx, table->ny, table->nz);

	printf(" w =\n");
	LES_show_volume(table->data.w, table->nx, table->ny, table->nz);

	printf(" p =\n");
	LES_show_volume(table->data.p, table->nx, table->ny, table->nz);

	printf(" t =\n");
	LES_show_volume(table->data.t, table->nx, table->ny, table->nz);
}


void LES_show_handle_summary(const LESHandle i) {
    LESMem *h = (LESMem *)i;
    printf("LES Configuration:\n");
    printf(" path: %s\n", h->data_path);
    printf("   v0: %.2f m/s\n", h->v0);
}


//LESTable *LES_get_frame_0(const LESHandle i, const int n) {
//	LESTable *table;
//	LESMem *h = (LESMem *)i;
//
//	const float v0 = h->v0;
//	
//	int k = 0;
//	while (n != h->data_id[k] && k < LES_num) {
//		k++;
//	}
//	
//	// If it is a table that has been ingested and still in the cache, just return it.
//	if (k < LES_num && h->data_id[k] == n) {
//        printf("Found n = %d @ k = %d\n", n, k);
//		return h->data_boxes[k];
//	} else {
//		// Need to read in
//		int file_id = n / LES_file_nblock;
//
//        #ifdef DEBUG
//		printf("LES DEBUG : Ingest from file %s ...\n", h->files[file_id]);
//        #endif
//
//        // To do: spin a separate thread to read in this entire file so that the requested
//        // block can be available as soon as it is read
//
//        // Derive filename to ingest a set of LESTables
//        FILE *fid = fopen(h->files[file_id], "r");
//		if (fid == NULL) {
//			return NULL;
//		}
//		
//		// First 32-bit is probably some kind of revision number
//		uint32_t ver;
//		fread(&ver, sizeof(uint32_t), 1, fid);
////		printf("ver = %d\n", ver);
//		
//		int rbuf = n % LES_file_nblock;
//
//		// Read in all blocks since there is only a small number of them.
//		for (int b = 0; b < LES_file_nblock; b++) {
//
//            #ifdef DEBUG
//			printf("LES DEBUG : Reading new LES table in data_boxes[%d] ...\n", h->ibuf);
//            #endif
//
//			h->data_id[h->ibuf] = file_id * LES_file_nblock + b;
//			
//			table = h->data_boxes[h->ibuf];
//			
//            // Copy over some base parameters
//            table->ax = h->ax;
//            table->ay = h->ay;
//            table->az = h->az;
//            table->rx = h->rx;
//            table->ry = h->ry;
//            table->rz = h->rz;
//            table->tp = h->tp;
//            table->tr = h->tr;
//            
//            // Timestamp from the file
//            fread(table->data.a, sizeof(float), 1, fid);
//			fseek(fid, 2 * sizeof(uint32_t), SEEK_CUR);
//
//			//LES_show_grid_summary(h->data_grid);
//
//			fread(table->data.u, sizeof(float), table->nn, fid);
//			fseek(fid, 2 * sizeof(int32_t), SEEK_CUR);
//
//			fread(table->data.v, sizeof(float), table->nn, fid);
//			fseek(fid, 2 * sizeof(int32_t), SEEK_CUR);
//
//			fread(table->data.w, sizeof(float), table->nn, fid);
//			fseek(fid, 2 * sizeof(int32_t), SEEK_CUR);
//
//			fread(table->data.p, sizeof(float), table->nn, fid);
//			fseek(fid, 2 * sizeof(int32_t), SEEK_CUR);
//
//			fread(table->data.t, sizeof(float), table->nn, fid);
//			fseek(fid, 2 * sizeof(int32_t), SEEK_CUR);
//			
//			for (int k=0; k<table->nn; k++) {
//				table->data.u[k] *= v0;
//				table->data.v[k] *= v0;
//				table->data.w[k] *= v0;
//				table->data.p[k] *= v0 * v0;
//				table->data.t[k] *= v0 * v0;
//			}
//			
//			h->ibuf = h->ibuf == LES_num - 1 ? 0 : h->ibuf + 1;
//		}
//		
//		fclose(fid);
//		
//		table = h->data_boxes[rbuf];
//	}
//	
//	return table;
//}


LESTable *LES_get_frame(const LESHandle i, const int n) {
    LESTable *table = NULL;
    LESMem *h = (LESMem *)i;
    int k = LES_num;
    do {
        k--;
    } while (n != h->data_id[k] && k > 0);
    if (n == h->data_id[k]) {
        #ifdef DEBUG
        rsprint("Found n = %d = %d @ k = %d / %d\n", n, h->data_id[k], k, LES_num);
        #endif
        table = h->data_boxes[k];
        // What to read in next
        h->req = n == h->ncubes - 1 ? 0 : n + 1;
    } else {
        // Let background read ingest the desired frame.
        int ibuf = h->ibuf;
        h->req = n;
        //printf("Wait for background read.\n");
        do {
            usleep(10000);
        } while (ibuf == h->ibuf);
        table = h->data_boxes[ibuf];
        // What to read in next
        h->req = n == h->ncubes - 1 ? 0 : n + 1;
    }
    table->is_stretched = h->data_grid->is_stretched;
    return table;
}


char *LES_data_path(const LESHandle i) {
    LESMem *h = (LESMem *)i;
    return h->data_path;
}


float LES_get_table_period(const LESHandle i) {
    LESMem *h = (LESMem *)i;
    return h->tp;
}


size_t LES_get_table_count(const LESHandle i) {
    LESMem *h = (LESMem *)i;
    return h->ncubes;
}
