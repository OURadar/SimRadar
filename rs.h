//
//  rs.h
//  Radar Simulation Framework
//
//  Created by Boon Leng Cheong.
//

#ifndef _rs_h
#define _rs_h

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdarg.h>
#include <unistd.h>
#include <math.h>
#include <time.h>
#include <string.h>
#include <sys/time.h>
#include <pthread.h>

#include "rs_types.h"
#include "les.h"
#include "adm.h"
#include "rcs.h"

#ifdef __APPLE__
#include <OpenCL/opencl.h>
#else
#include <CL/cl.h>
#endif

#if defined (__APPLE__) && defined (_SHARE_OBJ_)
#include <OpenGL/OpenGL.h>
#endif

#define RS_DOMAIN_PAD               2.0
#define RS_MAX_STR               4096
#define RS_MAX_GPU_PLATFORM        10
#define RS_MAX_GPU_DEVICE           8
#define RS_MAX_KERNEL_LINES      1024
#define RS_MAX_KERNEL_SRC       65536
#define RS_ALIGN_SIZE             128     // Align size. Be sure to have a least 32 for AVX
#define RS_MAX_GATES              512
#define RS_MAX_NUM_SCATS      4000000
#define RS_BODY_PER_CELL           50.0
#define RS_CL_GROUP_ITEMS          32
#define RS_MAX_VEL_TABLES          20
#define RS_MAX_ADM_TABLES           4
#define RS_MAX_RCS_TABLES           4

#ifndef MAX
#define MAX(X, Y)      ((X) > (Y) ? (X) : (Y))
#endif
#ifndef MIN
#define MIN(X, Y)      ((X) > (Y) ? (Y) : (X))
#endif

#define DTIME(T_begin, T_end)  ((double)(T_end.tv_sec - T_begin.tv_sec) + 1.0e-6 * (double)(T_end.tv_usec - T_begin.tv_usec))

enum {
	RS_STATUS_DOMAIN_NULL        = 0x00,
	RS_STATUS_DOMAIN_POPULATED   = 0x01
};

enum {
	RS_CL_PASS_2_UNIVERSAL,
	RS_CL_PASS_2_IN_RANGE,
	RS_CL_PASS_2_IN_LOCAL
};

typedef char RSMethod;
enum RSMethod {
	RS_METHOD_CPU,
	RS_METHOD_GPU
};

#define CL_CHECK(_expr)                                                         \
   do {                                                                         \
     cl_int _err = _expr;                                                       \
     if (_err == CL_SUCCESS)                                                    \
       break;                                                                   \
     fprintf(stderr, "OpenCL Error: '%s' returned %d!\n", #_expr, (int)_err);   \
} while (0)


typedef struct _reduction_params {
	cl_uint  count;
	cl_uint  cl_max_group_size;
	cl_uint  user_max_groups;
	cl_uint  user_max_work_items;
	
	cl_uint  pass_counts;
	cl_uint  *entry_counts;
	cl_uint  *group_counts;
	cl_uint  *work_item_counts;
} ReductionParams;


typedef struct _rs_pulse_params {
	unsigned int  num_scats;
	unsigned int  user_max_groups;
	unsigned int  user_max_work_items;
	unsigned int  cl_pass_2_method;

	unsigned int  range_count;
	float         range_start;
	float         range_delta;

	unsigned int  entry_counts[2];    // entry count of the 2-pass reduction
	unsigned int  group_counts[2];    // group count of the 2-pass reduction

	size_t        global[2];          // global count of the 2-pass reduction
	size_t        local[2];           // local count of the 2-pass reduction
	size_t        local_mem_size[2];  // local size of the 2-pass reduction in bytes
} RSMakePulseParams;


// A table (texture) for antenna/range pattern
typedef struct _rs_table {
	float         x0;                 // offset to the 1st element in the table
	float         xm;                 // maximum index in float
	float         dx;                 // scaling to map to table index
	uint32_t      reserved;           // n/a
	float         *data;              // table values
} RSTable;


// A table (texture) for air-drag parameters
typedef struct _rs_table2d {
    float         xs;                 // x scaling to map to table index
    float         xo;                 // x offset to the 1st element in the table
    float         xm;                 // x maximum index in float
    uint32_t      x_;
    float         ys;                 // y scaling to map to table index
    float         yo;                 // y offset to the 1st element in the table
    float         ym;                 // y maximum index in float
    uint32_t      y_;
    cl_float4     *data;              // Data in float4 grid, e.g., [x, y, z, _], [u, v, w, _]
} RSTable2D;


// A table (texture) for 3D wind parameters
typedef struct _rs_table3d {
	float         xs;                 // x scaling to map to table index
	float         xo;                 // x offset to the 1st element in the table
	float         xm;                 // x maximum index in float
	uint32_t      x_;
	float         ys;                 // y scaling to map to table index
	float         yo;                 // y offset to the 1st element in the table
	float         ym;                 // y maximum index in float
	uint32_t      y_;
	float         zs;                 // z scaling to map to table index
	float         zo;                 // z offset to the 1st element in the table
	float         zm;                 // z maximum index in float
	uint32_t      z_;
	float         tr;                 // replenishing time constant
	float         reserved[3];        // n/a. simply pad to 128-bit
	cl_float4     *data;              // Data in float4 grid, e.g., u, v, w, t
} RSTable3D;


// A typical convention for table description, which is a set of parameters
// along with a table
enum {
    RSTableDescriptionScaleX      =  0,
    RSTableDescriptionScaleY      =  1,
    RSTableDescriptionScaleZ      =  2,
    RSTableDescriptionRefreshTime =  3,
    RSTableDescriptionOriginX     =  4,
    RSTableDescriptionOriginY     =  5,
    RSTableDescriptionOriginZ     =  6,
    RSTableDescription7           =  7,
    RSTableDescriptionMaximumX    =  8,
    RSTableDescriptionMaximumY    =  9,
    RSTableDescriptionMaximumZ    = 10,
    RSTableDescription11          = 11,
    RSTableDescriptionRecipInLnX  = 12,
    RSTableDescriptionRecipInLnY  = 13,
    RSTableDescriptionRecipInLnZ  = 14,
    RSTableDescriptionTachikawa   = 15,
};

enum {
    RSSimulationParameterBeamUnitX     =  0,
    RSSimulationParameterBeamUnitY     =  1,
    RSSimulationParameterBeamUnitZ     =  2,
    RSSimulationParameterDebrisCount   =  3,
    RSSimulationParameter4             =  4,
    RSSimulationParameter5             =  5,
    RSSimulationParameter6             =  6,
    RSSimulationParameter7             =  7,
    RSSimulationParameterBoundOriginX  =  8,  // hi.s0
    RSSimulationParameterBoundOriginY  =  9,  // hi.s1
    RSSimulationParameterBoundOriginZ  =  10, // hi.s2
    RSSimulationParameterPRT           =  11,
    RSSimulationParameterBoundSizeX    =  12, // hi.s4
    RSSimulationParameterBoundSizeY    =  13, // hi.s5
    RSSimulationParameterBoundSizeZ    =  14, // hi.s6
    RSSimulationParameterAgeIncrement  =  15, // PRT / vel_desc.tr
};

//
//
//  Worker (per GPU) handle
//
typedef struct _rs_worker {
	char                   name;
	char                   verb;

	// OpenCL device
	cl_device_id           dev;
	cl_uint                num_cus;

	// Scatter bodies
	size_t                 num_scats;
	
	RSMakePulseParams      make_pulse_params;

	// GPU side memory
	cl_mem                 scat_pos;   // x, y, z coordinates
	cl_mem                 scat_vel;   // u, v, w wind components
	cl_mem                 scat_ori;   // alpha, beta, gamma angles
    cl_mem                 scat_tum;   // alpha, beta, gamma tumbling
	cl_mem                 scat_att;   // type, dot products, range, etc.
	cl_mem                 scat_sig;   // signal: Ih Qh Iv Qv
	cl_mem                 scat_rnd;   // random seed
	cl_mem                 work;
	cl_mem                 pulse;

	cl_mem                 range_weight;
	cl_float4              range_weight_desc;
	
	cl_mem                 angular_weight;
	cl_float4              angular_weight_desc;
	
    cl_mem                 adm_cd[RS_MAX_ADM_TABLES];
    cl_mem                 adm_cm[RS_MAX_ADM_TABLES];
    cl_float16             adm_desc[RS_MAX_ADM_TABLES];
    
    cl_mem                 rcs_real[RS_MAX_RCS_TABLES];
    cl_mem                 rcs_imag[RS_MAX_RCS_TABLES];
    cl_float16             rcs_desc[RS_MAX_RCS_TABLES];
    
	cl_mem                 vel[RS_MAX_VEL_TABLES];
	cl_float16             vel_desc;

    cl_uint                mem_size;

#if defined (__APPLE__) && defined (_SHARE_OBJ_)
	
	dispatch_queue_t       que;
	dispatch_semaphore_t   sem;
	cl_ndrange             ndrange_scat;
	cl_ndrange             ndrange_pulse_pass_1;
	cl_ndrange             ndrange_pulse_pass_2;
	
	// GPU side VBO's
	unsigned int           vbo_scat_pos;
	unsigned int           vbo_scat_clr;
	unsigned int           vbo_scat_ori;

	cl_mem                 scat_clr;   // color
	
#else
	
	cl_context             context;
	
	cl_program             prog;
	
    cl_kernel              kern_io;
    cl_kernel              kern_dummy;
    cl_kernel              kern_scat_atts;
	cl_kernel              kern_make_pulse_pass_1;
	cl_kernel              kern_make_pulse_pass_2;
	cl_kernel              kern_make_pulse_pass_2_group;
	cl_kernel              kern_make_pulse_pass_2_local;
	cl_kernel              kern_make_pulse_pass_2_range;

	cl_command_queue       que;
	
#endif

} RSWorker;


//
//  Master handle
//
typedef struct _rs_handle {
	char                   verb;
	char                   method;
	RSVolume               domain;
	RSParams               params;

	// Various simualtor state variables
	char                   status;
	size_t                 sim_tic;
	size_t                 sim_toc;
	RSfloat                sim_time;
    cl_float16             sim_desc;

    // Table related variables
    uint32_t               vel_idx;
    uint32_t               vel_count;
    uint32_t               adm_idx;
    uint32_t               adm_count;
    uint32_t               rcs_idx;
    uint32_t               rcs_count;
    cl_float4              inv_inln;
    cl_float               Ta;

	// Scatter bodies
	size_t                 num_scats;

	// CPU side memory (for upload/download)
	cl_float4              *scat_pos;       // position
	cl_float4              *scat_vel;       // velocity
	cl_float4              *scat_ori;       // orientation
    cl_float4              *scat_tum;       // tumble
	cl_float4              *scat_att;       // attributes
	cl_float4              *scat_sig;       // signal
	cl_float4              *work;
	cl_float4              *pulse;

	cl_float4              *pulse_tmp[RS_MAX_GPU_DEVICE];
	
	// OpenCL device
	cl_uint                num_devs;
	cl_uint                num_workers;
	cl_uint                num_cus[RS_MAX_GPU_DEVICE];
	cl_device_id           devs[RS_MAX_GPU_DEVICE];

	// GPU side memory
	RSWorker               worker[RS_MAX_GPU_DEVICE];
	size_t                 offset[RS_MAX_GPU_DEVICE];

	// Anchors
	ssize_t               num_anchors;
	ssize_t               num_anchor_lines;

	// CPU side memory
	cl_float4             *anchor_pos;
	cl_float4             *anchor_lines;
	cl_float4             beam_pos;
	
} RSHandle;


char *commaint(long long num);
char *now();

void get_device_info(cl_uint *num_devices, cl_device_id *devices, cl_uint *num_cus, cl_int detail_level);
void pfn_prog_notify(cl_program program, void *user_data);
void pfn_notify(const char *errinfo, const void *private_info, size_t cb, void *user_data);
cl_uint read_kernel_source_from_files(char *src_ptr[], ...);
ReductionParams *make_reduction_params(cl_uint count, cl_uint user_max_groups, cl_uint user_max_work_items);
void free_reduction_params(ReductionParams *params);
float read_table(const float *table, const float index_last, const float index);

#pragma mark -

// Initializes a simulation space
RSHandle *RS_init_with_path(const char *bundle_path, RSMethod method, const char verb);
RSHandle *RS_init_for_cpu_verbose(const char verb);
RSHandle *RS_init_verbose(const char verb);
RSHandle *RS_init();
void RS_free(RSHandle *H);

RSMakePulseParams RS_make_pulse_params(const cl_uint count, const cl_uint group_items, cl_uint user_group_counts,
								   const float range_start, const float range_delta, const unsigned int range_count);
#pragma mark -

void RS_set_prt(RSHandle *H, const float prt);
void RS_set_density(RSHandle *H, const float density);
void RS_set_antenna_params(RSHandle *H, RSfloat beamwidth_deg, RSfloat gain_dbi);
void RS_set_tx_params(RSHandle *H, RSfloat pulsewidth, RSfloat tx_power_watt);
void RS_set_scan_box(RSHandle *H,
					 RSfloat range_start, RSfloat range_end, RSfloat range_gate,
					 RSfloat azimuth_start, RSfloat azimuth_end, RSfloat azimuth_gate,
					 RSfloat elevation_start, RSfloat elevation_end, RSfloat elevation_gate);
void RS_set_beam_pos(RSHandle *H, RSfloat az_deg, RSfloat el_deg);
void RS_set_verbosity(RSHandle *H, const char verb);
void RS_set_worker_count(RSHandle *H, char count);

void RS_set_range_weight(RSHandle *H, const float *weights, const float table_index_start, const float table_index_delta, unsigned int table_size);
void RS_set_range_weight_to_triangle(RSHandle *H, float pulse_width_m);
void RS_set_angular_weight(RSHandle *H, const float *weights, const float table_index_start, const float table_index_delta, unsigned int table_size);
void RS_set_angular_weight_to_standard(RSHandle *H, float beamwidth_deg);
void RS_set_angular_weight_to_double_cone(RSHandle *H, float beamwidth_deg);

void RS_set_wind_data(RSHandle *H, const RSTable3D table);
void RS_set_wind_data_to_LES_table(RSHandle *H, const LESTable *table);
void RS_set_wind_data_to_cube27(RSHandle *H);
void RS_set_wind_data_to_cube125(RSHandle *H);
void RS_clear_wind_data(RSHandle *H);

void RS_set_adm_data(RSHandle *H, const RSTable2D table_cd, const RSTable2D table_cm);
void RS_set_adm_data_to_ADM_table(RSHandle *H, const ADMTable *table);
void RS_set_adm_data_to_unity(RSHandle *H);
void RS_clear_adm_data(RSHandle *H);

void RS_set_rcs_data(RSHandle *H, const RSTable2D table_real, const RSTable2D table_imag);
void RS_set_rcs_data_to_RCS_table(RSHandle *H, const RCSTable *table);
void RS_set_rcs_data_to_unity(RSHandle *H);
void RS_clear_rcs_data(RSHandle *H);

#if defined (__APPLE__) && defined (_SHARE_OBJ_)
#pragma mark -

void RS_share_mem_with_vbo(RSHandle *H, unsigned int *vbo);
void RS_update_colors_only(RSHandle *H);
void RS_explode(RSHandle *H);

#endif

void RS_io_test(RSHandle *H);
void RS_dummy_test(RSHandle *H);

void RS_populate(RSHandle *H);

void RS_upload(RSHandle *H);
void RS_download(RSHandle *H);
void RS_download_position_only(RSHandle *H);
void RS_download_pulse_only(RSHandle *H);

void RS_advance_time(RSHandle *H);
//void RS_advance_time_cpu(RSHandle *H);

void RS_make_pulse(RSHandle *H);
//void RS_make_pulse_cpu(RSHandle *H);

#pragma mark -

RSTable RS_table_init(size_t numel);
void RS_table_free(RSTable T);
RSTable2D RS_table2d_init(size_t numel);
void RS_table2d_free(RSTable2D T);
RSTable3D RS_table3d_init(size_t numel);
void RS_table3d_free(RSTable3D T);

#pragma mark -

void RS_show_scat_pos(RSHandle *H);
void RS_show_pulse(RSHandle *H);

#endif
