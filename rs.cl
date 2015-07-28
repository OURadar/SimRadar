enum RSSimulationParameter {
    RSSimulationParameterBeamUnitX     =  0,
    RSSimulationParameterBeamUnitY     =  1,
    RSSimulationParameterBeamUnitZ     =  2,
    RSSimulationParameterDebrisCount   =  3,
    RSSimulationParameter4             =  4,
    RSSimulationParameter5             =  5,
    RSSimulationParameter6             =  6,
    RSSimulationParameterSimTic        =  7,
    RSSimulationParameterBoundOriginX  =  8,
    RSSimulationParameterBoundOriginY  =  9,
    RSSimulationParameterBoundOriginZ  =  10,
    RSSimulationParameterPRT           =  11,
    RSSimulationParameterBoundSizeX    =  12, // hi.s4
    RSSimulationParameterBoundSizeY    =  13, // hi.s5
    RSSimulationParameterBoundSizeZ    =  14, // hi.s6
    RSSimulationParameterAgeIncrement  =  15  // PRT / vel_desc.tr
};

float4 rand(uint4 *seed);
float4 set_clr(float4 att);
float compute_angular_weight(float4 pos,
                             __constant float *angular_weight,
                             const float4 angular_weight_desc,
                             const float16 sim_desc);
float4 quat_mult(float4 left, float4 right);
float4 quat_conj(float4 quat);
float4 quat_get_x(float4 quat);
float4 quat_get_y(float4 quat);
float4 quat_get_z(float4 quat);
float4 quat_rotate(float4 vector, float4 quat);
float4 quat_identity(void);

/////////////////////////////////////////////////////////////////////////////////////////
//
// Rudimentary function(s)
//

float4 rand(uint4 *seed)
{
    const uint4 a = {16807, 16807, 16807, 16807};
    const uint4 m = {0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF};
    const float4 n = {1.0f / 2147483647.0f, 1.0f / 2147483647.0f, 1.0f / 2147483647.0f, 1.0f / 2147483647.0f};
    
    *seed = (*seed * a) & m;
    
    return convert_float4(*seed) * n;
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Convenient function(s)
//

// Set colors
float4 set_clr(float4 att)
{
    //float g = clamp(fma(log10(att.s3), 0.3f, 1.5f), 0.05f, 0.3f);
    float g = clamp(fma(log10(att.s3), 1.6f, 6.0f), 0.05f, 0.3f);
    
    float4 c;
    
    c.x = clamp(0.4f * att.s1, 0.0f, 1.0f) + 0.6f * g;
    c.y = 0.9f * g;
    c.z = clamp(1.0f - c.x - 3.5f * g, 0.0f, 1.0f) + 0.2f * (g - 0.1f);
    //c.w = 0.3f;
    c.w = 1.0f;
    
    return c;
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Angular weighting function
//

float compute_angular_weight(float4 pos,
                             __constant float *angular_weight,
                             const float4 angular_weight_desc,
                             const float16 sim_desc)
{
    //    RSSimulationParameterBeamUnitX     =  0,
    //    RSSimulationParameterBeamUnitY     =  1,
    //    RSSimulationParameterBeamUnitZ     =  2,
    float angle = acos(dot(sim_desc.s012, normalize(pos.xyz)));
    
    float2 table_s = (float2)(angular_weight_desc.s0, angular_weight_desc.s0);
    float2 table_o = (float2)(angular_weight_desc.s1, angular_weight_desc.s1) + (float2)(0.0f, 1.0f);
    float2 angle_2 = (float2)(angle, angle);

    // scale, offset, clamp to edge
    uint2  iidx_int;
    float2 fidx_int;
    float2 fidx_raw = clamp(fma(angle_2, table_s, table_o), 0.0f, angular_weight_desc.s2);
    float2 fidx_dec = fract(fidx_raw, &fidx_int);
    
    iidx_int = convert_uint2(fidx_int);
    
    return mix(angular_weight[iidx_int.s0], angular_weight[iidx_int.s1], fidx_dec.s0);
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Quaternion arithmetics
//

float4 quat_mult(float4 left, float4 right)
{
    return (float4)(left.w * right.x - left.z * right.y + left.y * right.z + left.x * right.w,
                    left.w * right.y + left.z * right.x + left.y * right.w - left.x * right.z,
                    left.w * right.z + left.z * right.w - left.y * right.x + left.x * right.y,
                    left.w * right.w - left.z * right.z - left.y * right.y - left.x * right.x);
}

float4 quat_conj(float4 quat)
{
    return (float4)(-quat.x, -quat.y, -quat.z, quat.w);
}

float4 quat_get_x(float4 quat)
{
    return quat_mult(quat, (float4)(quat.w, quat.z, -quat.y, quat.x));
}

float4 quat_get_y(float4 quat)
{
    return quat_mult(quat, (float4)(-quat.z, quat.w, quat.x, quat.y));
}

float4 quat_get_z(float4 quat)
{
    return quat_mult(quat, (float4)(quat.y, -quat.x, quat.w, quat.z));
}

float4 quat_rotate(float4 vector, float4 quat)
{
    return quat_mult(quat_mult(quat, vector), quat_conj(quat));
}

//float4 quat_identity()
//{
//    return (float4)(0.0f, 0.0f, 0.0f, 1.0f);
//}
#define quat_identity  (float4)(0.0f, 0.0f, 0.0f, 1.0f)

/////////////////////////////////////////////////////////////////////////////////////////
//
// OpenCL Kernel Functions
//

// Input output for measuring data throughput
//
// i - input
// o - output
//
__kernel void io(__global float4 *i,
                 __global float4 *o)
{
    unsigned int k = get_global_id(0);
    o[k] = i[k];
}

__kernel void dummy(__global float4 *i)
{
    float az = 0.0f;
    float el = 0.0f;

    float4 quat_new_frame
    = (float4)(-0.5f * cos(0.5f * (az - el)) - 0.5f * sin(0.5f * (az + el)),
               +0.5f * cos(0.5f * (az - el)) - 0.5f * sin(0.5f * (az + el)),
               +0.5f * cos(0.5f * (az + el)) - 0.5f * sin(0.5f * (az - el)),
               +0.5f * cos(0.5f * (az + el)) + 0.5f * sin(0.5f * (az - el)));

//    float4 quat_new_frame
//    = (float4)(-0.5f,  0.5f,  0.5f, 0.5f) * cos(0.5f * (float4)(az - el, az - el, az + el, az + el))
//    + (float4)(-0.5f, -0.5f, -0.5f, 0.5f) * sin(0.5f * (float4)(az + el, az + el, az - el, az - el));

    quat_new_frame = quat_mult(quat_new_frame, quat_new_frame);
    
    
    //    float4 az4 = (float4)( az,  az, az, az);
    //    float4 el4 = (float4)(-el, -el, el, el);
    //    float4 quat_new_frame
    //    = (float4)(-0.5f,  0.5f,  0.5f, 0.5f) * cos(0.5f * (az4 + el4))
    //    + (float4)(-0.5f, -0.5f, -0.5f, 0.5f) * sin(0.5f * (az4 - el4));   
}

__kernel void bg_atts(__global float4 *p,
                      __global float4 *v,
                      __global float4 *a,
                      __global uint4 *y,
                      __read_only image3d_t wind_uvw,
                      const float16 wind_desc,
                      __constant float *angular_weight,
                      const float4 angular_weight_desc,
                      const float16 sim_desc)
{

    const unsigned int i = get_global_id(0);
    
    float4 pos = p[i];
    float4 vel = v[i];
    float4 aux = a[i];
    
    const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;
    
    //    RSSimulationParameterBeamUnitX     =  0,
    //    RSSimulationParameterBeamUnitY     =  1,
    //    RSSimulationParameterBeamUnitZ     =  2,
    //    RSSimulationParameterDebrisCount   =  3,
    //    RSSimulationParameter4             =  4,
    //    RSSimulationParameter5             =  5,
    //    RSSimulationParameter6             =  6,
    //    RSSimulationParameter7             =  7,
    //    RSSimulationParameterBoundOriginX  =  8,  // hi.s0
    //    RSSimulationParameterBoundOriginY  =  9,  // hi.s1
    //    RSSimulationParameterBoundOriginZ  =  10, // hi.s2
    //    RSSimulationParameterPRT           =  11,
    //    RSSimulationParameterBoundSizeX    =  12, // hi.s4
    //    RSSimulationParameterBoundSizeY    =  13, // hi.s5
    //    RSSimulationParameterBoundSizeZ    =  14, // hi.s6
    //    RSSimulationParameterAgeIncrement  =  15, // PRT / vel_desc.tr
    const float4 dt = (float4)(sim_desc.sb, sim_desc.sb, sim_desc.sb, 0.0f);
    
    // Background wind
    float4 wind_coord = fma(pos, wind_desc.s0123, wind_desc.s4567);
    
    vel = read_imagef(wind_uvw, sampler, wind_coord);
    
    // Future position, orientation, etc.
    pos += vel * dt;
    
    // Check for bounding constraints
    //    RSSimulationParameterBoundOriginX  =  8,  // hi.s0
    //    RSSimulationParameterBoundOriginY  =  9,  // hi.s1
    //    RSSimulationParameterBoundOriginZ  =  10, // hi.s2
    //    RSSimulationParameterPRT           =  11,
    //    RSSimulationParameterBoundSizeX    =  12, // hi.s4
    //    RSSimulationParameterBoundSizeY    =  13, // hi.s5
    //    RSSimulationParameterBoundSizeZ    =  14, // hi.s6
    //    RSSimulationParameterAgeIncrement  =  15, // PRT / vel_desc.tr
    int is_outside = any(isless(pos.xyz, sim_desc.hi.s012) | isgreater(pos.xyz, sim_desc.hi.s012 + sim_desc.hi.s456));

    if (is_outside | isgreater(aux.s1, 1.0f)) {
        uint4 seed = y[i];
        float4 r = rand(&seed);
        y[i] = seed;
        pos.xyz = r.xyz * sim_desc.hi.s456 + sim_desc.hi.s012;
        aux.s1 = 0.0f;
        vel = (float4)(0.0f, 0.0f, 0.0f, 0.0f);
    } else {
        aux.s1 += sim_desc.sf;
    }
    
    // Range of the point
    aux.s0 = length(pos);

    aux.s3 = compute_angular_weight(pos, angular_weight, angular_weight_desc, sim_desc);
    
    p[i] = pos;
    v[i] = vel;
    a[i] = aux;
}


__kernel void scat_atts(__global float4 *p,
                        __global float4 *o,
                        __global float4 *v,
                        __global float4 *t,
                        __global float4 *a,
                        __global float4 *x,
                        __global uint4 *y,
                        __read_only image3d_t wind_uvw,
                        const float16 wind_desc,
                        __read_only image2d_t adm_cd,
                        __read_only image2d_t adm_cm,
                        const float16 adm_desc,
                        __read_only image2d_t rcs_real,
                        __read_only image2d_t rcs_imag,
                        const float16 rcs_desc,
                        __constant float *angular_weight,
                        const float4 angular_weight_desc,
                        const float16 sim_desc)
{
    const unsigned int i = get_global_id(0);
    
    float4 pos = p[i];
    float4 ori = o[i];
    float4 vel = v[i];
    float4 tum = t[i];
    float4 aux = a[i];
    
    const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;

    //    RSSimulationParameterBeamUnitX     =  0,
    //    RSSimulationParameterBeamUnitY     =  1,
    //    RSSimulationParameterBeamUnitZ     =  2,
    //    RSSimulationParameterDebrisCount   =  3,
    //    RSSimulationParameter4             =  4,
    //    RSSimulationParameter5             =  5,
    //    RSSimulationParameter6             =  6,
    //    RSSimulationParameter7             =  7,
    //    RSSimulationParameterBoundOriginX  =  8,  // hi.s0
    //    RSSimulationParameterBoundOriginY  =  9,  // hi.s1
    //    RSSimulationParameterBoundOriginZ  =  10, // hi.s2
    //    RSSimulationParameterPRT           =  11,
    //    RSSimulationParameterBoundSizeX    =  12, // hi.s4
    //    RSSimulationParameterBoundSizeY    =  13, // hi.s5
    //    RSSimulationParameterBoundSizeZ    =  14, // hi.s6
    //    RSSimulationParameterAgeIncrement  =  15, // PRT / vel_desc.tr
    const float4 dt = (float4)(sim_desc.sb, sim_desc.sb, sim_desc.sb, 0.0f);
    const float el = atan2(sim_desc.s2, length(sim_desc.s01));
    const float az = atan2(sim_desc.s0, sim_desc.s1);

    // Background wind
    float4 wind_coord = fma(pos, wind_desc.s0123, wind_desc.s4567);
    float4 vel_bg = read_imagef(wind_uvw, sampler, wind_coord);
    
    //
    // derive alpha & beta of ADM for ADM table lookup ---------------------------------
    //
    float alpha, beta, gamma;
    
    float4 ur = vel_bg - vel;

    if (length(ur.xyz) > 1.0e-3f) {
        float4 u_hat = normalize(ur);
        
//        // xp, yp, zp - x, y, z axis of the particle
//        float4 xp = quat_get_x(ori);
//        float4 yp = quat_get_y(ori);
//        float4 zp = quat_get_z(ori);

        u_hat = quat_rotate(u_hat, quat_conj(ori));
        
        beta = acos(u_hat.x);
        alpha = atan2(u_hat.z, u_hat.y);
        
        if (alpha < 0.0f) {
            alpha = M_PI_F + alpha;
            beta = -beta;
        }
    } else {
        alpha = M_PI_2_F;
        beta = 0.0f;
    }
    
    float2 adm_coord = fma((float2)(beta, alpha), adm_desc.s01, adm_desc.s45);
    float4 cd = read_imagef(adm_cd, sampler, adm_coord);
    float4 cm = read_imagef(adm_cm, sampler, adm_coord);
    
    //    RSTableDescriptionRecipInLnX  = 12,
    //    RSTableDescriptionRecipInLnY  = 13,
    //    RSTableDescriptionRecipInLnZ  = 14,
    //    RSTableDescriptionTachikawa   = 15,
    const float Ta = adm_desc.sf;
    const float4 inv_inln = (float4)(adm_desc.scde, 0.0f);

    cd = quat_rotate(cd, ori);

//    if (i == 0)
//        printf("ur = %5.2f %5.2f %5.2f %5.2f  cdr = %5.2f %5.2f %5.2f %5.2f\n",
//               ur.x, ur.y, ur.z, ur.w,
//               cd.x, cd.y, cd.z, cd.w);
    
    float ur_norm = length(ur.xyz);
    float ur_norm_sq = ur_norm * ur_norm;
    
    float4 dudt = Ta * ur_norm_sq * cd;
    
    dudt.z -= 9.8f;
    
//    if (length(vel) > length(vel_bg)) {
//        printf("vel = [%5.2f %5.2f %5.2f %5.2f]  vel_bg = [%5.2f %5.2f %5.2f %5.2f]   %5.2f\n",
//               vel.x, vel.y, vel.z, vel.w,
//               vel_bg.x, vel_bg.y, vel_bg.z, vel_bg.w,
//               ur_norm_sq
//               );
//    }
    
#define DEG2RAD(x)  (x * 0.017453292519943f)
#define RAD2DEG(x)  (x * 57.295779513082323f)
    
    float4 dw = DEG2RAD(dt * Ta * ur_norm_sq * cm * inv_inln);
    
    float4 c = cos(dw);
    float4 s = sin(dw);
    tum = (float4)(c.x * s.y * s.z + s.x * c.y * c.z,
                   c.x * s.y * c.z - s.x * c.y * s.z,
                   c.x * c.y * s.z + s.x * s.y * c.z,
                   c.x * c.y * c.z - s.x * s.y * s.z);


    //
    // derive alpha, beta & gamma of RCS for RCS table lookup --------------------------
    //

    float ce = cos(0.5f * el);
    float se = sin(0.5f * el);
    float ca = cos(0.5f * az);
    float sa = sin(0.5f * az);
    
    // I know this part looks like a black box, check reference MATLAB implementation quat2euler.m for the raw version
    float4 F = (float4)(-M_SQRT1_2_F * sa * (ce + se), -M_SQRT1_2_F * ca * (ce + se), M_SQRT1_2_F * ca * (ce - se), -M_SQRT1_2_F * sa * (ce - se));
    float4 quat_rel = quat_mult(quat_mult(F, ori), (float4)(-0.5f, 0.5f, -0.5f, 0.5f));
    
    // 3-2-3 conversion:
    alpha = atan2(quat_rel.y * quat_rel.z + quat_rel.w * quat_rel.x , quat_rel.w * quat_rel.y - quat_rel.x * quat_rel.z);
    beta  =  acos(quat_rel.w * quat_rel.w + quat_rel.z * quat_rel.z - quat_rel.y * quat_rel.y - quat_rel.x * quat_rel.x);
    gamma = atan2(quat_rel.y * quat_rel.z - quat_rel.w * quat_rel.x , quat_rel.x * quat_rel.z + quat_rel.w * quat_rel.y);

    printf("i = %d   ori = [ %.3f %.3f %.3f %.3f ]   BLC = [ %.3f %.3f %.3f %.3f ]  ==> abg = [ %.4f %.4f %.4f ]\n",
           i,
           ori.x, ori.y, ori.z, ori.w,
           quat_rel.x, quat_rel.y, quat_rel.z, quat_rel.w,
           alpha, beta, gamma);
    
    // Update velocity
    vel += dudt * dt;
    
    // Update orientation
    ori = quat_mult(ori, tum);

//#define RAD2DEG(X)  (X * 57.295779513082323f)
//        if (i == 0) {
//            printf("el/az = %5.2f %5.2f   alpha/beta/gamma = %5.2f %5.2f %5.2f   quat_rel = %5.2f %5.2f %5.2f %5.2f\n",
//                   RAD2DEG(el), RAD2DEG(az),
//                   RAD2DEG(alpha), RAD2DEG(beta), RAD2DEG(gamma),
//                   quat_rel.x, quat_rel.y, quat_rel.z, quat_rel.w);
//        }
    
    // Update position
    pos += vel * dt;
    
    // Check for bounding constraints
    //    RSSimulationParameterBoundOriginX  =  8,  // hi.s0
    //    RSSimulationParameterBoundOriginY  =  9,  // hi.s1
    //    RSSimulationParameterBoundOriginZ  =  10, // hi.s2
    //    RSSimulationParameterPRT           =  11,
    //    RSSimulationParameterBoundSizeX    =  12, // hi.s4
    //    RSSimulationParameterBoundSizeY    =  13, // hi.s5
    //    RSSimulationParameterBoundSizeZ    =  14, // hi.s6
    //    RSSimulationParameterAgeIncrement  =  15, // PRT / vel_desc.tr
    int is_outside = any(isless(pos.xyz, sim_desc.hi.s012) | isgreater(pos.xyz, sim_desc.hi.s012 + sim_desc.hi.s456));

    if (is_outside | isgreater(aux.s1, 1.0f)) {
        uint4 seed = y[i];
        float4 r = rand(&seed);
        y[i] = seed;
        
        pos.xyz = r.xyz * sim_desc.hi.s456 + sim_desc.hi.s012;
//        pos.z = 20.0f;
        
        vel = (float4)(0.0f, 0.0f, 0.0f, 0.0f);
    }

    // Range of the point
    aux.s0 = length(pos);

    aux.s3 = compute_angular_weight(pos, angular_weight, angular_weight_desc, sim_desc);

    p[i] = pos;
    o[i] = ori;
    v[i] = vel;
    t[i] = tum;
    a[i] = aux;
}


__kernel void scat_clr(__global float4 *c,
                       __global float4 *a,
                       const unsigned int n)
{
    unsigned int i = get_global_id(0);
    
    c[i] = set_clr(a[i]);
}


__kernel void scat_clr2(__global float4 *c,
                        __global float4 *p,
                        __global float4 *a,
                        __constant float *angular_weight,
                        const float4 angular_weight_desc,
                        const float4 b,
                        const unsigned int n)
{
    unsigned int i = get_global_id(0);
    
    float angle = acos(dot(b.xyz, normalize(p[i].xyz)));
    
    const float2 table_s = (float2)(angular_weight_desc.s0, angular_weight_desc.s0);
    const float2 table_o = (float2)(angular_weight_desc.s1, angular_weight_desc.s1) + (float2)(0.0f, 1.0f);
    const float2 angle_2 = (float2)(angle, angle);
    
    float2 fidx_raw;
    float2 fidx_dec;
    float2 fidx_int;
    uint2  iidx_int;
    
    fidx_raw = clamp(fma(angle_2, table_s, table_o), 0.0f, angular_weight_desc.s2);
    fidx_dec = fract(fidx_raw, &fidx_int);
    iidx_int = convert_uint2(fidx_int);
    
    a[i].s3 = mix(angular_weight[iidx_int.s0], angular_weight[iidx_int.s1], fidx_dec.s0);
    
    //float w = mix(angular_weight[iidx_int.s0], angular_weight[iidx_int.s1], fidx_dec.s0);
    
    c[i] = set_clr(a[i]);
}


//
// out - output
// sig - signal
// att - attributes
// shared - local memory space __local space (64 kB max)
// weight_table - range weighting function, __constant space (64 kB max)
// table_x0 - offset to convert range to table index
// table_xm - last table index
// table_dx - scale to convert range to table index
// range_start - start range of the domain
// range_delta - range spacing (not resolution)
// range_count - number of range gates
// group_count - number of parallel groups
// n - last element (number of scatter bodies)
//
__kernel void make_pulse_pass_1(__global float4 *out,
                                __global const float4 *sig,
                                __global const float4 *att,
                                __local float4 *shared,
                                __constant float *weight_table,
                                const float table_x0,
                                const float table_xm,
                                const float table_dx,
                                const float range_start,
                                const float range_delta,
                                const unsigned int range_count,
                                const unsigned int group_count,
                                const unsigned int n)
{
    const float4 zero = {0.0f, 0.0f, 0.0f, 0.0f};
    const unsigned int group_id = get_group_id(0);
    const unsigned int local_id = get_local_id(0);
    const unsigned int local_size = get_local_size(0);
    const unsigned int group_stride = 2 * local_size;
    const unsigned int local_stride = group_stride * group_count;
    
    const float4 table_dx_4 = (float4)(table_dx, table_dx, table_dx, table_dx);
    const float4 table_x0_4 = (float4)(table_x0, table_x0, table_x0, table_x0) + (float4)(0.0f, 1.0f, 0.0f, 1.0f);
    
    float r;
    float r_a;
    float r_b;
    
    float4 a;
    float4 b;
    float4 w_a;
    float4 w_b;
    
    unsigned int k;
    unsigned int i = group_id * group_stride + local_id;
    
    
    // Initialize the block of local memory to zeros
    for (k=0; k<range_count; k++) {
        shared[local_id + k * local_size] = zero;
    }
    
    //	printf("group_id=%d  local_id=%d  local_size=%d  range_count=%d\n", group_id, local_id, local_size, range_count);
    
    float4 fidx_raw;
    float4 fidx_int;
    float4 fidx_dec;
    uint4  iidx_int;
    
    // Will use:
    // Elements 0 & 1 for scatter body from the left group (a)
    // Elements 2 & 3 for scatter body from the right group (b)
    // Linearly interpolate weights of element 0 & 1 using decimal fraction stored in dec.s0
    // Linearly interpolate weights of element 2 & 3 using decimal fraction stored in dec.s2
    // Why do it like this rather than the plain C code? Keep the CU's SIMD processors busy.
    while (i < n) {
        a = sig[i];
        b = sig[i + local_size];
        r_a = att[i].s0;
        r_b = att[i + local_size].s0;
        r = range_start;
        for (k=0; k<range_count; k++) {
            float4 dr = (float4)(r_a, r_a, r_b, r_b) - (float4)(r, r, r, r);
            
            fidx_raw = clamp(fma(dr, table_dx_4, table_x0_4), 0.0f, table_xm);     // Index [0 ... xm] in float
            fidx_dec = fract(fidx_raw, &fidx_int);                                 // The integer and decimal fraction
            iidx_int = convert_uint4(fidx_int);
            
            float2 w2 = mix((float2)(weight_table[iidx_int.s0], weight_table[iidx_int.s2]),
                            (float2)(weight_table[iidx_int.s1], weight_table[iidx_int.s3]),
                            fidx_dec.s02);
            
            //			if (i < 16) {
            //				printf("k=%2u  r=%5.2f  i=%2u  r_a=%6.3f  dr=% 5.3f  w_r=% 6.3f   % 5.2f -> % 2u/% 2u/% 3.2f  % 5.2f % 5.2f\n",
            //					   k, r, i,            r_a, dr.s0, w2.s0, fidx_raw.s0, iidx_int.s0, iidx_int.s1, fidx_dec.s0, weight_table[iidx_int.s0], weight_table[iidx_int.s1]);
            //				printf("k=%2u  r=%5.2f  i=%2u  r_a=%6.3f  dr=% 5.3f  w_r=% 6.3f   % 5.2f -> % 2u/% 2u/% 3.2f  % 5.2f % 5.2f\n",
            //					   k, r, i+local_size, r_b, dr.s2, w2.s1, fidx_raw.s2, iidx_int.s2, iidx_int.s3, fidx_dec.s2, weight_table[iidx_int.s2], weight_table[iidx_int.s3]);
            //			}
            
            w_a = (float4)(w2.s0, w2.s0, w2.s0, w2.s0);
            w_b = (float4)(w2.s1, w2.s1, w2.s1, w2.s1);
            
            shared[local_id + k * local_size] += (w_a * a + w_b * b);
            // printf("%d shared[%d] = %.2f  %.2f\n", group_id, local_id + k, shared[local_id + k].x, wr);
            
            r += range_delta;
        }
        i += local_stride;
    }
    barrier(CLK_LOCAL_MEM_FENCE);
    
    unsigned int local_numel = range_count * local_size;
    
    // Consolidate the local memory
    if (local_size > 512 && local_id < 512)
    {
        for (k=0; k<local_numel; k+=local_size)
            shared[local_id + k] += shared[local_id + k + 512];
    }
    barrier(CLK_LOCAL_MEM_FENCE);

    if (local_size > 256 && local_id < 256)
    {
        for (k=0; k<local_numel; k+=local_size)
            shared[local_id + k] += shared[local_id + k + 256];
    }
    barrier(CLK_LOCAL_MEM_FENCE);

    if (local_size > 128 && local_id < 128)
    {
        for (k=0; k<local_numel; k+=local_size)
            shared[local_id + k] += shared[local_id + k + 128];
    }
    barrier(CLK_LOCAL_MEM_FENCE);
    
    if (local_size > 64 && local_id < 64)
    {
        for (k=0; k<local_numel; k+=local_size)
            shared[local_id + k] += shared[local_id + k + 64];
    }
    barrier(CLK_LOCAL_MEM_FENCE);
    
    if (local_size > 32 && local_id < 32)
    {
        for (k=0; k<local_numel; k+=local_size)
            shared[local_id + k] += shared[local_id + k + 32];
    }
    barrier(CLK_LOCAL_MEM_FENCE);
    
    if (local_size > 16 && local_id < 16)
    {
        for (k=0; k<local_numel; k+=local_size)
            shared[local_id + k] += shared[local_id + k + 16];
    }
    barrier(CLK_LOCAL_MEM_FENCE);
    
    if (local_size > 8 && local_id < 8)
    {
        for (k=0; k<local_numel; k+=local_size)
            shared[local_id + k] += shared[local_id + k + 8];
    }
    barrier(CLK_LOCAL_MEM_FENCE);
    
    if (local_size > 4 && local_id < 4)
    {
        for (k=0; k<local_numel; k+=local_size)
            shared[local_id + k] += shared[local_id + k + 4];
    }
    barrier(CLK_LOCAL_MEM_FENCE);
    
    if (local_size > 2 && local_id < 2)
    {
        for (k=0; k<local_numel; k+=local_size)
            shared[local_id + k] += shared[local_id + k + 2];
    }
    barrier(CLK_LOCAL_MEM_FENCE);
    
    if (local_size > 1 && local_id < 1)
    {
        for (k=0; k<local_numel; k+=local_size)
            shared[local_id + k] += shared[local_id + k + 1];
    }
    barrier(CLK_LOCAL_MEM_FENCE);
    
    if (local_id == 0)
    {
        __global float4 *o = &out[group_id * range_count];
        for (k=0; k<range_count*local_size; k+=local_size) {
            //printf("groupd_id=%d  out[%d] = shared[%d] = %.2f\n", group_id, (int)(o-out), k, shared[k].x);
            *o++ = shared[k];
        }
    }
    
}


__kernel void make_pulse_pass_2_local(__global float4 *out,
                                      __global float4 *in,
                                      __local float4 *shared,
                                      const unsigned int range_count,
                                      const unsigned int n)
{
    const float4 zero = {0.0f, 0.0f, 0.0f, 0.0f};
    const unsigned int local_id = get_local_id(0);
    const unsigned int groupd_id = get_global_id(0);
    const unsigned int group_stride = 2 * range_count;
    
    shared[local_id] = zero;
    
    unsigned int i = groupd_id;
    
    //	printf("groupd_id=%d  local_id=%d/%d  group_stride=%d  i=%d/%d\n",
    //		   groupd_id, local_id, group_size, group_stride, i, n);
    
    while (i < n) {
        float4 a = in[i];
        float4 b = in[i + range_count];
        shared[local_id] += a + b;
        //		printf("i=%2d  groupd_id=%d  shared[%d] += %.2f(%d) + %.2f(%d) = %.2f\n",
        //			   i,
        //			   groupd_id, local_id,
        //			   a.x, i,
        //			   b.x, i + range_count,
        //			   shared[local_id].x);
        i += group_stride;
    }
    barrier(CLK_LOCAL_MEM_FENCE);
    
    //	printf("out[%d] = %.2f\n", groupd_id, shared[local_id].x);
    out[groupd_id] = shared[local_id];
    
}


__kernel void make_pulse_pass_2_range(__global float4 *out,
                                      __global float4 *in,
                                      __local float4 *shared,
                                      const unsigned int range_count,
                                      const unsigned int n)
{
    unsigned int range_id = get_global_id(0);
    float4 tmp = (float4)(0.0f, 0.0f, 0.0f, 0.0f);
    //	int k = 0;
    for (unsigned int i=range_id; i<n; i+=range_count) {
        //		if (range_id == 1 || range_id == 2) {
        //			printf("k=%2d  range_id=%d  i=%3d  tmp += %.2f\n", k, range_id, i, in[i].x);
        //			k++;
        //		}
        tmp += in[i];
    }
    barrier(CLK_LOCAL_MEM_FENCE);
    out[range_id] = tmp;
}


__kernel void make_pulse_pass_2_group(__global float4 *out,
                                      __global float4 *in,
                                      __local float4 *shared,
                                      const unsigned int range_count,
                                      const unsigned int n)
{
    const unsigned int local_id = get_local_id(0);
    const unsigned int local_size = get_local_size(0);
    const unsigned int group_stride = range_count * local_size;
    
    unsigned int i = local_id * range_count;
    
    for (unsigned int k=0; k<range_count; k++) {
        float4 a = in[i + k];
        float4 b = in[i + k + group_stride];
        shared[local_id] = a + b;
        //		printf("shared[%d] += %.2f(%d) + %.2f(%d) = %.2f\n",
        //			   local_id,
        //			   a.x, i + k,
        //			   b.x, i + k + group_stride,
        //			   shared[local_id].x);
        barrier(CLK_LOCAL_MEM_FENCE);
        
        // Consolidate local memory to range_count
        if (local_size > 512 && local_id < 512) {
            shared[local_id] += shared[local_id + 512];
        }
        barrier(CLK_LOCAL_MEM_FENCE);
        
        if (local_size > 256 && local_id < 256) {
            shared[local_id] += shared[local_id + 256];
        }
        barrier(CLK_LOCAL_MEM_FENCE);

        if (local_size > 128 && local_id < 128) {
            shared[local_id] += shared[local_id + 128];
        }
        barrier(CLK_LOCAL_MEM_FENCE);
        
        if (local_size > 64 && local_id < 64) {
            shared[local_id] += shared[local_id + 64];
        }
        barrier(CLK_LOCAL_MEM_FENCE);
        
        if (local_size > 32 && local_id < 32) {
            shared[local_id] += shared[local_id + 32];
        }
        barrier(CLK_LOCAL_MEM_FENCE);
        
        if (local_size > 16 && local_id < 16) {
            shared[local_id] += shared[local_id + 16];
        }
        barrier(CLK_LOCAL_MEM_FENCE);
        
        if (local_size > 8 && local_id < 8) {
            shared[local_id] += shared[local_id + 8];
        }
        barrier(CLK_LOCAL_MEM_FENCE);
        
        if (local_size > 4 && local_id < 4) {
            shared[local_id] += shared[local_id + 4];
        }
        barrier(CLK_LOCAL_MEM_FENCE);
        
        if (local_size > 2 && local_id < 2) {
            shared[local_id] += shared[local_id + 2];
        }
        barrier(CLK_LOCAL_MEM_FENCE);
        
        if (local_size > 1 && local_id < 1) {
            shared[local_id] += shared[local_id + 1];
        }
        barrier(CLK_LOCAL_MEM_FENCE);
        
        if (local_id == 0) {
            // printf("out[%d] = %.2f\n", k, shared[0].x);
            out[k] = shared[0];
        }
    }
}

// Generate some saw-tooth data
__kernel void pop(__global float4 *sig, __global float4 *att)
{
    unsigned int k = get_global_id(0);
    
    //float v = (float)(k % 8);
    float v = 1.0f;
    sig[k] = (float4)(v, v, v, v);
    att[k] = (float4)((float)k * 0.5f + 10.0f, 0.0f, 0.0f, 0.0f);
}
