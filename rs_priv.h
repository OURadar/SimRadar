//
//  rs_priv.h
//
//  Created by Boon Leng Cheong on 4/15/15.
//  Copyright (c) 2015 Boon Leng Cheong. All rights reserved.
//

#ifndef rs_priv_h
#define rs_priv_h

#include "rs_types.h"

enum RSDebrisRCSKernelArgument {
    RSDebrisRCSKernelArgumentPosition,
    RSDebrisRCSKernelArgumentOrientation,
    RSDebrisRCSKernelArgumentRadarCrossSection,
    RSDebrisRCSKernelArgumentRadarCrossSectionReal,
    RSDebrisRCSKernelArgumentRadarCrossSectionImag,
    RSDebrisRCSKernelArgumentRadarCrossSectionDescription,
    RSDebrisRCSKernelArgumentSimulationDescription
};

enum RSBackgroundAttributeKernelArgument {
    RSBackgroundAttributeKernelArgumentPosition,
    RSBackgroundAttributeKernelArgumentVelocity,
    RSBackgroundAttributeKernelArgumentRadarCrossSection,
    RSBackgroundAttributeKernelArgumentRandomSeed,
    RSBackgroundAttributeKernelArgumentBackgroundVelocity,
    RSBackgroundAttributeKernelArgumentBackgroundCn2Pressure,
    RSBackgroundAttributeKernelArgumentBackgroundDescription,
    RSBackgroundAttributeKernelArgumentEllipsoidRCS,
    RSBackgroundAttributeKernelArgumentEllipsoidRCSDescription,
    RSBackgroundAttributeKernelArgumentSimulationDescription
};

enum RSDebrisAttributeKernelArgument {
    RSDebrisAttributeKernelArgumentPosition,
    RSDebrisAttributeKernelArgumentOrientation,
    RSDebrisAttributeKernelArgumentVelocity,
    RSDebrisAttributeKernelArgumentTumble,
    RSDebrisAttributeKernelArgumentRadarCrossSection,
    RSDebrisAttributeKernelArgumentRandomSeed,
    RSDebrisAttributeKernelArgumentBackgroundVelocity,
    RSDebrisAttributeKernelArgumentBackgroundCn2Pressure,
    RSDebrisAttributeKernelArgumentBackgroundVelocityDescription,
    RSDebrisAttributeKernelArgumentAirDragModelDrag,
    RSDebrisAttributeKernelArgumentAirDragModelMomentum,
    RSDebrisAttributeKernelArgumentAirDragModelDescription,
    RSDebrisAttributeKernelArgumentRadarCrossSectionReal,
    RSDebrisAttributeKernelArgumentRadarCrossSectionImag,
    RSDebrisAttributeKernelArgumentRadarCrossSectionDescription,
    RSDebrisAttributeKernelArgumentDebrisFluxField,
    RSDebrisAttributeKernelArgumentDebrisFluxFieldDescription,
    RSDebrisAttributeKernelArgumentSimulationDescription
};

enum RSScattererColorKernelArgument {
    RSScattererColorKernelArgumentColor,
    RSScattererColorKernelArgumentPosition,
    RSScattererColorKernelArgumentAuxiliary,
    RSScattererColorKernelArgumentRadarCrossSection,
    RSScattererColorKernelArgumentDrawMode
};

enum RSScattererSignalDropSizeDistributionKernalArgument {
    RSScattererSignalDropSizeDistributionKernalArgumentRadarCrossSection,
    RSScattererSignalDropSizeDistributionKernalArgumentPosition,
    RSScattererSignalDropSizeDistributionKernalArgumentAuxiliary,
    RSScattererSignalDropSizeDistributionKernalArgumentSimulationDescription
};

enum RSScattererAngularWeightKernalArgument {
    RSScattererAngularWeightKernalArgumentSignal,
    RSScattererAngularWeightKernalArgumentAuxiliary,
    RSScattererAngularWeightKernalArgumentPosition,
    RSScattererAngularWeightKernalArgumentRadarCrossSection,
    RSScattererAngularWeightKernalArgumentWeightTable,
    RSScattererAngularWeightKernalArgumentWeightTableDescription,
    RSScattererAngularWeightKernalArgumentSimulationDescription
};

#pragma mark -
#pragma mark General Methods

void get_device_info(cl_device_type device_type, cl_uint *num_devices, cl_device_id *devices, cl_uint *num_cus, cl_uint *vendors, cl_int detail_level);
void pfn_prog_notify(cl_program program, void *user_data);
void pfn_notify(const char *errinfo, const void *private_info, size_t cb, void *user_data);
cl_uint read_kernel_source_from_files(char *src_ptr[], ...);
ReductionParams *make_reduction_params(cl_uint count, cl_uint user_max_groups, cl_uint user_max_work_items);
void free_reduction_params(ReductionParams *params);
float read_table(const float *table, const float index_last, const float index);

cl_float4 complex_multiply(const cl_float4 a, const cl_float4 b);
cl_float4 complex_divide(const cl_float4 a, const cl_float4 b);
cl_double4 double_complex_multiply(const cl_double4 a, const cl_double4 b);
cl_double4 double_complex_divide(const cl_double4 a, const cl_double4 b);

#pragma mark -

void RS_worker_init(RSWorker *C, cl_device_id dev, cl_uint src_size, const char **src_ptr, cl_context_properties sharegroup, const char verb);
void RS_worker_free(RSWorker *C);
void RS_worker_malloc(RSHandle *H, const int worker_id);

void RS_merge_pulse_tmp(RSHandle *H);
void RS_update_origins_offsets(RSHandle *H);
void RS_update_auxiliary_attributes(RSHandle *H);

// Functions to upload to to GPU memory
void RS_set_vel_data(RSHandle *H, const RSTable3D table);
void RS_set_adm_data(RSHandle *H, const RSTable2D table_cd, const RSTable2D table_cm);
void RS_set_rcs_data(RSHandle *H, const RSTable2D table_real, const RSTable2D table_imag);

// Functions to copy a table into master handler
void RS_set_adm_data_to_ADM_table(RSHandle *H, const ADMTable *table);
void RS_set_adm_data_to_unity(RSHandle *H);
void RS_clear_adm_data(RSHandle *H);
void RS_set_rcs_data_to_RCS_table(RSHandle *H, const RCSTable *table);
void RS_set_rcs_data_to_unity(RSHandle *H);
void RS_clear_rcs_data(RSHandle *H);

void RS_set_obj_data_to_config(RSHandle *H, OBJConfig type);

void RS_set_rcs_ellipsoid_table(RSHandle *H, const cl_float4 *weights, const float table_index_start, const float table_index_delta, unsigned int table_size);

void RS_revise_population(RSHandle *H);

#endif
