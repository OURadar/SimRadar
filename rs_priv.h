//
//  rs_priv.h
//
//  Created by Boon Leng Cheong on 4/15/15.
//  Copyright (c) 2015 Boon Leng Cheong. All rights reserved.
//

#ifndef rs_priv_h
#define rs_priv_h

enum RSBackgroundAttributeKernelArgument {
    RSBackgroundAttributeKernelArgumentPosition,
    RSBackgroundAttributeKernelArgumentVelocity,
    RSBackgroundAttributeKernelArgumentRandomSeed,
    RSBackgroundAttributeKernelArgumentBackgroundVelocity,
    RSBackgroundAttributeKernelArgumentBackgroundVelocityDescription,
    RSBackgroundAttributeKernelArgumentSimulationDescription
};

enum RSEllipsoidAttributeKernelArgument {
    RSEllipsoidAttributeKernelArgumentPosition,
    RSEllipsoidAttributeKernelArgumentVelocity,
    RSEllipsoidAttributeKernelArgumentRandomSeed,
    RSEllipsoidAttributeKernelArgumentBackgroundVelocity,
    RSEllipsoidAttributeKernelArgumentBackgroundVelocityDescription,
    RSEllipsoidAttributeKernelArgumentSimulationDescription
};

enum RSDebrisAttributeKernelArgument {
    RSDebrisAttributeKernelArgumentPosition,
    RSDebrisAttributeKernelArgumentOrientation,
    RSDebrisAttributeKernelArgumentVelocity,
    RSDebrisAttributeKernelArgumentTumble,
    RSDebrisAttributeKernelArgumentSignal,
    RSDebrisAttributeKernelArgumentRandomSeed,
    RSDebrisAttributeKernelArgumentBackgroundVelocity,
    RSDebrisAttributeKernelArgumentBackgroundVelocityDescription,
    RSDebrisAttributeKernelArgumentAirDragModelDrag,
    RSDebrisAttributeKernelArgumentAirDragModelMomentum,
    RSDebrisAttributeKernelArgumentAirDragModelDescription,
    RSDebrisAttributeKernelArgumentRadarCrossSectionReal,
    RSDebrisAttributeKernelArgumentRadarCrossSectionImag,
    RSDebrisAttributeKernelArgumentRadarCrossSectionDescription,
    RSDebrisAttributeKernelArgumentSimulationDescription
};

enum RSScattererColorKernelArgument {
    RSScattererColorKernelArgumentColor,
    RSScattererColorKernelArgumentPosition,
    RSScattererColorKernelArgumentAuxiliary,
    RSScattererColorKernelArgumentDrawMode
};

enum RSScattererSignalDropSizeDistributionKernalArgument {
    RSScattererSignalDropSizeDistributionKernalArgumentSignal,
    RSScattererSignalDropSizeDistributionKernalArgumentPosition,
    RSScattererSignalDropSizeDistributionKernalArgumentAuxiliary
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

void get_device_info(cl_device_type device_type, cl_uint *num_devices, cl_device_id *devices, cl_uint *num_cus, cl_uint *vendors, cl_int detail_level);
void pfn_prog_notify(cl_program program, void *user_data);
void pfn_notify(const char *errinfo, const void *private_info, size_t cb, void *user_data);
cl_uint read_kernel_source_from_files(char *src_ptr[], ...);
ReductionParams *make_reduction_params(cl_uint count, cl_uint user_max_groups, cl_uint user_max_work_items);
void free_reduction_params(ReductionParams *params);
float read_table(const float *table, const float index_last, const float index);

void RS_worker_init(RSWorker *C, cl_device_id dev, cl_uint src_size, const char **src_ptr, const char verb);
void RS_worker_free(RSWorker *C);
void RS_worker_malloc(RSHandle *H, const int worker_id, const size_t sub_num_scats, const size_t offset);

void RS_init_scat_pos(RSHandle *H);
void RS_merge_pulse_tmp(RSHandle *H);
void RS_update_debris_count(RSHandle *H);

void RS_set_vel_data(RSHandle *H, const RSTable3D table);
void RS_set_adm_data(RSHandle *H, const RSTable2D table_cd, const RSTable2D table_cm);
void RS_set_rcs_data(RSHandle *H, const RSTable2D table_real, const RSTable2D table_imag);

#endif
