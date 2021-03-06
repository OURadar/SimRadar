//
//  rs.h
//  Radar Simulation Framework
//
//  Created by Boon Leng Cheong.
//  Copyright (c) 2015-2016 Boon Leng Cheong. All rights reserved.
//

#ifndef _rs_h
#define _rs_h

#include "rs_enum.h"
#include "rs_types.h"
#include "log.h"
#include "les.h"
#include "obj.h"
//#include "arps.h"
#include "pos.h"

#if defined (__APPLE__)
#include <OpenCL/opencl.h>
#else
#include <CL/cl.h>
#include <CL/cl_gl.h>
#endif

#if defined (GUI) || defined (_USE_GCL_)
#include <OpenGL/OpenGL.h>
#endif

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
    float         xs;                 // x scaling to map to table index              or "m" for stretched grid: m * log1p(n * pos.x) + o;
    float         xo;                 // x offset to the 1st element in the table     or "n" for stretched grid: m * log1p(n * pos.x) + o;
    float         xm;                 // x maximum index in float                     or "o" for stretched grid: m * log1p(n * pos.z) + o;
    uint32_t      x_;
    float         ys;                 // y scaling to map to table index
    float         yo;                 // y offset to the 1st element in the table
    float         ym;                 // y maximum index in float
    uint32_t      y_;
    float         zs;                 // z scaling to map to table index;             or "m" for stretched grid: zm * log1p(n * pos.z) + o;
    float         zo;                 // z offset to the 1st element in the table;    or "n" for stretched grid: zm * log1p(n * pos.z) + o;
    float         zm;                 // z maximum index in float                     or "o" for stretched grid: zm * log1p(n * pos.z) + o;
    uint32_t      z_;
    float         tr;                 // replenishing time constant
    float         reserved1;          // n/a. simply pad to 128-bit
    float         reserved2;          // n/a. simply pad to 128-bit
    uint32_t      spacing;            // spacing convention: uniform or stretched (geometric)
    cl_float4     *uvwt;              // Data in float4 grid, e.g., u, v, w, t
    cl_float4     *cpxx;              // Data in float4 grid, e.g., cn2, p, _, _
} RSTable3D;


// A box that describes the origin and size
typedef union
{
    cl_float  CL_ALIGNED(16) s[4];
#if defined( __GNUC__) && ! defined( __STRICT_ANSI__ )
    __extension__ struct{ cl_float   r, a, e, w; };
    __extension__ struct{ cl_float   s0, s1, s2, s3; };
#endif
} RSPolar;

typedef struct _rs_box {
    RSPolar origin;
    RSPolar size;
} RSBox;

typedef uint32_t RSTable1DDescription;
typedef uint32_t RSTable3DDescription;
typedef uint32_t RSTable3DStaggeredDescription;
typedef uint32_t RSTableDescription;
typedef uint32_t RSTableStaggeredDescription;
typedef uint32_t RSSimulationDescription;
typedef uint32_t RSDropSizeDistribution;
typedef uint32_t RSTableSpacing;
typedef uint32_t RSSimulationConcept;

#pragma pack(push, 1)

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
    
    size_t                 origins[RS_MAX_DEBRIS_TYPES];
    size_t                 counts[RS_MAX_DEBRIS_TYPES];
    
    RSMakePulseParams      make_pulse_params;
    
    // GPU side memory
    cl_mem                 scat_pos;                     // x, y, z coordinates
    cl_mem                 scat_vel;                     // u, v, w wind components
    cl_mem                 scat_ori;                     // alpha, beta, gamma angles
    cl_mem                 scat_tum;                     // alpha, beta, gamma tumbling
    cl_mem                 scat_aux;                     // type, dot products, range, etc.
    cl_mem                 scat_rcs;                     // radar cross section: Ih Qh Iv Qv
    cl_mem                 scat_sig;                     // signal: Ih Qh Iv Qv
    cl_mem                 scat_rnd;                     // random seed
    cl_mem                 scat_clr;                     // color
    cl_mem                 work;
    cl_mem                 pulse;
    
    cl_mem                 range_weight;                 // 1D range weight
    cl_float4              range_weight_desc;            // 1D range weight description
    
    cl_mem                 angular_weight;               // 1D angular weight
    cl_float4              angular_weight_desc;          // 1D angular weight description
    
    cl_mem                 angular_weight_2d;            // 2D angular weight
    cl_float16             angular_weight_2d_desc;       // 2D angular weight description
    
    cl_mem                 rcs_ellipsoid;                // RCS of background scatterers
    cl_float4              rcs_ellipsoid_desc;           // RCS-desc of background scatterers
    
    cl_mem                 adm_cd[RS_MAX_ADM_TABLES];    // ADM-cd of debris
    cl_mem                 adm_cm[RS_MAX_ADM_TABLES];    // ADM-cm of debris
    cl_float16             adm_desc[RS_MAX_ADM_TABLES];  // ADM-desc of debris
    cl_uint                adm_count;
    
    cl_mem                 rcs_real[RS_MAX_RCS_TABLES];  // RCS of debris
    cl_mem                 rcs_imag[RS_MAX_RCS_TABLES];  // RCS of debris
    cl_float16             rcs_desc[RS_MAX_RCS_TABLES];  // RCS-desc of debris
    cl_uint                rcs_count;
    
    cl_mem                 les_uvwt[2];                  // Double buffering of u, v, w, t
    cl_mem                 les_cpxx[2];                  // Double buffering of cn2, p, _, _
    cl_float16             les_desc;                     // LES-desc of the table
    unsigned int           les_id;                       // Index of the active buffer
    
    cl_mem                 dff_icdf[2];                  // Debris flux field
    cl_float16             dff_desc;                // Debris flux field description

    size_t                 mem_size;
    size_t                 mem_usage;
    
    // GPU side memory for VBOs
    unsigned int           vbo_scat_pos;
    unsigned int           vbo_scat_clr;
    unsigned int           vbo_scat_ori;
    
#if defined (_USE_GCL_)
    
    dispatch_queue_t       que;
    dispatch_semaphore_t   sem;
    dispatch_semaphore_t   sem_upload;
    cl_ndrange             ndrange_scat_all;
    cl_ndrange             ndrange_scat[RS_MAX_DEBRIS_TYPES];
    cl_ndrange             ndrange_pulse_pass_1;
    cl_ndrange             ndrange_pulse_pass_2;
    
    IOSurfaceRef           surf_range_weight;
    IOSurfaceRef           surf_angular_weight;
    IOSurfaceRef           surf_angular_weight_2d;
    IOSurfaceRef           surf_rcs_ellipsoids;
    IOSurfaceRef           surf_adm_cd[RS_MAX_ADM_TABLES];
    IOSurfaceRef           surf_adm_cm[RS_MAX_ADM_TABLES];
    IOSurfaceRef           surf_rcs_real[RS_MAX_RCS_TABLES];
    IOSurfaceRef           surf_rcs_imag[RS_MAX_RCS_TABLES];
    IOSurfaceRef           surf_uvwt[2];
    IOSurfaceRef           surf_cpxx[2];
    
#else
    
    cl_context             context;
    cl_context_properties  sharegroup;
    
    cl_program             prog;
    
    cl_kernel              kern_io;
    cl_kernel              kern_db_rcs;
    cl_kernel              kern_bg_atts;
    cl_kernel              kern_fp_atts;
    cl_kernel              kern_el_atts;
    cl_kernel              kern_db_atts;
    cl_kernel              kern_scat_clr;
    cl_kernel              kern_scat_sig_aux;
    cl_kernel              kern_make_pulse_pass_1;
    cl_kernel              kern_make_pulse_pass_2;
    cl_kernel              kern_make_pulse_pass_2_group;
    cl_kernel              kern_make_pulse_pass_2_local;
    cl_kernel              kern_make_pulse_pass_2_range;
    
    cl_command_queue       que;
    cl_event               event_upload;
    
#endif
    
    cl_kernel              kern_dummy;
    
} RSWorker;


typedef struct _rs_handle RSHandle;

//
//  Master handle
//
struct _rs_handle {
    char                   verb;
    char                   method;
    RSParams               params;
    unsigned int           random_seed;

    // Various simualtor state variables
    char                   status;
    RSfloat                sim_tic;
    RSfloat                sim_toc;
    cl_float16             sim_desc;
    RSSimulationConcept    sim_concept;
    
    // Table related variables
    uint32_t               vel_idx;
    uint32_t               vel_count;
    uint32_t               adm_idx;
    uint32_t               rcs_idx;
    
    // Table parameter shadow copy: only the constants, not the pointers
    LESTable               vel_desc;
    ADMTable               adm_desc[RS_MAX_DEBRIS_TYPES];
    RCSTable               rcs_desc[RS_MAX_DEBRIS_TYPES];
    
    // Scatter bodies
    size_t                 num_scats;
    size_t                 num_types;
    size_t                 counts[RS_MAX_DEBRIS_TYPES];
    
    // CPU side memory (for upload/download)
    cl_uint4               *scat_uid;       // universal id
    cl_float4              *scat_pos;       // position
    cl_float4              *scat_vel;       // velocity
    cl_float4              *scat_ori;       // orientation
    cl_float4              *scat_tum;       // tumble
    cl_float4              *scat_aux;       // auxiliary
    cl_float4              *scat_rcs;       // rcs
    cl_float4              *scat_sig;       // signal
    cl_uint4               *scat_rnd;       // random seed
    cl_float4              *pulse;
    
    cl_float4              *pulse_tmp[RS_MAX_GPU_DEVICE];
    
    size_t                 mem_size;
    
    // OpenCL device
    cl_uint                num_devs;
    cl_uint                num_workers;
    cl_uint                preferred_multiple;
    cl_uint                num_cus[RS_MAX_GPU_DEVICE];
    cl_uint                vendors[RS_MAX_GPU_DEVICE];
    cl_device_id           devs[RS_MAX_GPU_DEVICE];
    
    // OpenGL sharing
    char                   has_vbo_from_gl;
    
    // GPU side memory
    RSWorker               workers[RS_MAX_GPU_DEVICE];
    size_t                 offset[RS_MAX_GPU_DEVICE];
    
    // Anchors
    ssize_t                num_anchors;
    ssize_t                num_anchor_lines;
    cl_uint4               draw_mode;
    
    // CPU side memory
    cl_float4              *anchor_pos;
    cl_float4              *anchor_lines;
    
    // DSD parameters
    char                   dsd_name;
    RSfloat                dsd_n0;           // DSD parameter for MP, gamma
    RSfloat                dsd_lambda;       // DSD parameter for MP, gamma
    RSfloat                dsd_mu;           // DSD parameter for gamma
    int                    dsd_count;        // DSD bin count
    RSfloat                dsd_nd_sum;       // DSD drop concentration (drops / m^3)
    size_t                 *dsd_pop;
    RSfloat                *dsd_pdf;
    RSfloat                *dsd_cdf;
    RSfloat                *dsd_r;           // DSD radii
    
    // Summary text
    char                   summary[2048];
    
    // Other handlers for LES and OBJ (ADM, RCS)
    LESHandle              L;
    OBJHandle              O;
    POSHandle              P;
};

#pragma pack(pop)

cl_uint RS_gpu_count(void);
char *RS_version_string(void);
int RS_indent_copy(char *dst, char *src, const int width);

#pragma mark -
#pragma mark Initialization and Deallocation

// Initializes a simulation space
RSHandle *RS_init_with_path(const char *bundle_path, RSMethod method, const uint8_t gpu_mask, cl_context_properties sharegroup, const char verb);
RSHandle *RS_init_for_selected_gpu(const uint8_t gpu_mask, const char verb);
RSHandle *RS_init_for_cpu_verbose(const char verb);
RSHandle *RS_init_verbose(const char verb);
RSHandle *RS_init(void);
void RS_free(RSHandle *H);

RSMakePulseParams RS_make_pulse_params(const cl_uint count, const cl_uint group_size_multiple, const cl_uint user_group_counts, const cl_uint max_local_mem_size,
                                       const float range_start, const float range_delta, const unsigned int range_count);
#pragma mark -
#pragma mark Radar and Simulation Parameters

void RS_set_concept(RSHandle *H, RSSimulationConcept c);
char *RS_simulation_concept_string(RSHandle *);
char *RS_simulation_concept_bulleted_string(RSHandle *H);

void RS_set_prt(RSHandle *H, const RSfloat prt);
void RS_set_lambda(RSHandle *H, const RSfloat lambda);
void RS_set_density(RSHandle *H, const RSfloat density);
void RS_set_antenna_params(RSHandle *H, RSfloat beamwidth_deg, RSfloat gain_dbi);
void RS_set_tx_params(RSHandle *H, RSfloat pulsewidth, RSfloat tx_power_watt);
void RS_set_sampling_spacing(RSHandle *H, const RSfloat range, const RSfloat azimuth, const RSfloat elevation);
void RS_set_scan_box(RSHandle *H, RSBox box);
void RS_set_scan_extent(RSHandle *H,
                        RSfloat range_start, RSfloat range_end, RSfloat range_gate,
                        RSfloat azimuth_start, RSfloat azimuth_end, RSfloat azimuth_gate,
                        RSfloat elevation_start, RSfloat elevation_end, RSfloat elevation_gate);
void RS_set_beam_pos(RSHandle *H, RSfloat az_deg, RSfloat el_deg);
void RS_set_verbosity(RSHandle *H, const char verb);
void RS_set_debris_count(RSHandle *H, const int debris_id, const size_t count);
size_t RS_get_debris_count(RSHandle *H, const int debris_id);
size_t RS_get_worker_debris_count(RSHandle *H, const int debris_id, const int worker_id);
size_t RS_get_all_worker_debris_counts(RSHandle *H, const int debris_id, size_t counts[]);
RSVolume RS_get_domain(RSHandle *H);

void RS_set_dsd(RSHandle *H, const float *cdf, const float *diameters, const int count, const char name);
void RS_set_dsd_to_mp(RSHandle *H);
void RS_set_dsd_to_mp_with_sizes(RSHandle *H, const float *ds, const int count);

void RS_set_range_weight(RSHandle *H, const float *weights, const float table_index_start, const float table_index_delta, unsigned int table_size);
void RS_set_range_weight_to_triangle(RSHandle *H, float pulse_width_m);

void RS_set_angular_weight(RSHandle *H, const float *weights, const float table_index_start, const float table_index_delta, unsigned int table_size);
void RS_set_angular_weight_to_standard(RSHandle *H, float beamwidth_deg);
void RS_set_angular_weight_to_double_cone(RSHandle *H, float beamwidth_deg);

void RS_set_vel_data_to_config(RSHandle *, LESConfig);
void RS_set_vel_data_to_LES_table(RSHandle *H, const LESTable *table);
void RS_set_vel_data_to_uniform(RSHandle *H, cl_float4 velocity);
void RS_set_vel_data_to_cube27(RSHandle *H);
void RS_set_vel_data_to_cube125(RSHandle *H);
void RS_clear_vel_data(RSHandle *H);

void RS_set_debris_flux_field_by_pdf(RSHandle *H, RSTable2D *map, const float *pdf);
void RS_set_debris_flux_field_by_icdf(RSHandle *H, RSTable2D *map, const float *icdf);
void RS_set_debris_flux_field_to_center_cell_of_3x3(RSHandle *H);
void RS_set_debris_flux_field_to_checker_board(RSHandle *H, const int);
void RS_set_debris_flux_field_to_checker_board_stretched(RSHandle *H, const LESTable *table);
void RS_set_debris_flux_field_from_LES(RSHandle *H, const LESTable *leslie);

void RS_set_scan_pattern(RSHandle *H, const POSPattern *scan_pattern);
void RS_set_scan_pattern_with_string(RSHandle *H, const char *scan_string);

// New methods
//void RS_set_obj_data_to_config(RSHandle *H, OBJConfig type);
void RS_set_random_seed(RSHandle *H, const unsigned int seed);
void RS_add_debris(RSHandle *H, OBJConfig type, const size_t count);

#pragma mark -

#if defined (GUI) || defined (_USE_GCL_)
void RS_update_colors(RSHandle *H);
void RS_share_mem_with_vbo(RSHandle *H, const int n, unsigned int vbo[][n]);
#endif

#if defined (_USE_GCL_)
void RS_derive_ndranges(RSHandle *H);
#endif

#pragma mark -

void RS_io_test(RSHandle *H);

#pragma mark - Populate the Emulation Domain

void RS_populate(RSHandle *H);

#pragma mark - Accessing Data on the GPUs

void RS_upload(RSHandle *H);
void RS_download(RSHandle *H);
void RS_download_position_only(RSHandle *H);
void RS_download_orientation_only(RSHandle *H);
void RS_download_pulse_only(RSHandle *H);

//void RS_rcs_from_dsd(RSHandle *H);
void RS_compute_rcs_ellipsoids(RSHandle *H);

#pragma mark - Simulation Time Evolution

void RS_advance_time(RSHandle *H);
void RS_advance_beam(RSHandle *H);
void RS_make_pulse(RSHandle *H);

#pragma mark - General Table Allocation

RSTable RS_table_init(size_t numel);
void RS_table_free(RSTable T);
RSTable2D RS_table2d_init(size_t numel);
void RS_table2d_free(RSTable2D T);
RSTable3D RS_table3d_init(size_t numel);
void RS_table3d_free(RSTable3D T);

#pragma mark - Text Output

void RS_show_radar_params(RSHandle *H);
void RS_show_scat_pos(RSHandle *H);
void RS_show_scat_sig(RSHandle *H);
void RS_show_scat_att(RSHandle *H);
void RS_show_pulse(RSHandle *H);

#pragma mark - High-Level Functions to Condition Emulation Setup

RSBox RS_suggest_scan_domain(RSHandle *H);
void RS_revise_debris_counts_to_gpu_preference(RSHandle *H);

char *RS_simulation_description(RSHandle *H);

#endif
