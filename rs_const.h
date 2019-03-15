//
//  rs_const.h
//  Radar Simulator Framework
//
//  Created by Boon Leng Cheong on 2/10/16.
//  Copyright © 2016 Boon Leng Cheong. All rights reserved.
//

#ifndef rs_const_h
#define rs_const_h

#define RS_C                 29979458.0
#define RS_DOMAIN_PAD               2.0
#define RS_MAX_STR               4096
#define RS_MAX_GPU_PLATFORM        40
#define RS_MAX_GPU_DEVICE           8
#define RS_MAX_KERNEL_LINES      2048
#define RS_MAX_KERNEL_SRC      131072
#define RS_ALIGN_SIZE             128     // Align size. Be sure to have a least 16 for SSE, 32 for AVX, 64 for AVX-512
#define RS_MAX_GATES              512
#define RS_CL_GROUP_ITEMS          64
#define RS_MAX_DEBRIS_TYPES         8
#define RS_MAX_ADM_TABLES           RS_MAX_DEBRIS_TYPES
#define RS_MAX_RCS_TABLES           RS_MAX_DEBRIS_TYPES

#define RS_MAX_NUM_SCATS    120000000               // Maximum tested = 110M, 2016-03-003 (25k body/cell)
#define RS_BODY_PER_CELL          100.0f            // Default scatterer density
#define RS_PARAMS_LAMBDA            0.1f            // Default wavelength in m
#define RS_PARAMS_PRT               1.0e-3f         // Default PRT in s
#define RS_PARAMS_TAU               0.2e-6f         // Default pulse width in s
#define RS_PARAMS_PULSEWIDTH        RS_PARAMS_TAU   // Default pulse width in s, same as RS_PARAMS_TAU
#define RS_PARAMS_BEAMWIDTH         1.0f
#define RS_PARAMS_GATEWIDTH         30.0f

enum RSStatus {
    RSStatusNull                         = 0,
    RSStatusPopulationDefined            = 1 << 1,
    RSStatusOriginsOffsetsDefined        = 1 << 2,
    RSStatusWorkersAllocated             = 1 << 3,
    RSStatusDomainPopulated              = 1 << 4,
    RSStatusScattererSignalNeedsUpdate   = 1 << 5,
    RSStatusDebrisRCSNeedsUpdate         = 1 << 6
};

enum RS_CL_PASS_2 {
    RS_CL_PASS_2_UNIVERSAL,
    RS_CL_PASS_2_IN_RANGE,
    RS_CL_PASS_2_IN_LOCAL
};

typedef char RSMethod;
enum RSMethod {
    RS_METHOD_CPU,
    RS_METHOD_GPU
};

#endif /* rs_const_h */
