#define MIN_HEIGHT        10.0f
#define FLOAT4_ZERO      (float4)(0.0f, 0.0f, 0.0f, 0.0f)
#define QUAT_IDENTITY    (float4)(0.0f, 0.0f, 0.0f, 1.0f)

enum RSTable1DDescrip {
    RSTable1DDescriptionScale        = 0,
    RSTable1DDescriptionOrigin       = 1,
    RSTable1DDescriptionMaximum      = 2,
    RSTable1DDescriptionUserConstant = 3
};

enum RSTableSpacing {
    RSTableSpacingUniform          = 0,
    RSTableSpacingStretchedX       = 1,
    RSTableSpacingStretchedY       = 1 << 1,
    RSTableSpacingStretchedZ       = 1 << 2,
    RSTableSpacingStretchedXYZ     = RSTableSpacingStretchedX | RSTableSpacingStretchedY | RSTableSpacingStretchedZ
};

enum RSSimulationDescription {
    RSSimulationDescriptionBeamUnitX     =  0,
    RSSimulationDescriptionBeamUnitY     =  1,
    RSSimulationDescriptionBeamUnitZ     =  2,
    RSSimulationDescriptionDebrisCount   =  3,
    RSSimulationDescriptionWaveNumber    =  4,
    RSSimulationDescription5             =  5,
    RSSimulationDescription6             =  6,
    RSSimulationDescriptionSimTic        =  7,
    RSSimulationDescriptionBoundOriginX  =  8,
    RSSimulationDescriptionBoundOriginY  =  9,
    RSSimulationDescriptionBoundOriginZ  =  10,
    RSSimulationDescriptionPRT           =  11,
    RSSimulationDescriptionBoundSizeX    =  12, // hi.s4
    RSSimulationDescriptionBoundSizeY    =  13, // hi.s5
    RSSimulationDescriptionBoundSizeZ    =  14, // hi.s6
    RSSimulationDescriptionAgeIncrement  =  15  // PRT / vel_desc.tr
};

enum RSTable3DDescription {
    RSTable3DDescriptionScaleX      =  0,
    RSTable3DDescriptionScaleY      =  1,
    RSTable3DDescriptionScaleZ      =  2,
    RSTable3DDescriptionRefreshTime =  3,
    RSTable3DDescriptionOriginX     =  4,
    RSTable3DDescriptionOriginY     =  5,
    RSTable3DDescriptionOriginZ     =  6,
    RSTable3DDescription7           =  7,
    RSTable3DDescriptionMaximumX    =  8,
    RSTable3DDescriptionMaximumY    =  9,
    RSTable3DDescriptionMaximumZ    = 10,
    RSTable3DDescription11          = 11,
    RSTable3DDescriptionRecipInLnX  = 12,
    RSTable3DDescriptionRecipInLnY  = 13,
    RSTable3DDescriptionRecipInLnZ  = 14,
    RSTable3DDescriptionTachikawa   = 15
};

enum RSTable3DStaggeredDescription {
    RSTable3DStaggeredDescriptionBaseChangeX     =  0,
    RSTable3DStaggeredDescriptionBaseChangeY     =  1,
    RSTable3DStaggeredDescriptionBaseChangeZ     =  2,
    RSTable3DStaggeredDescriptionRefreshTime     =  3,
    RSTable3DStaggeredDescriptionPositionScaleX  =  4,
    RSTable3DStaggeredDescriptionPositionScaleY  =  5,
    RSTable3DStaggeredDescriptionPositionScaleZ  =  6,
    RSTable3DStaggeredDescription7               =  7,
    RSTable3DStaggeredDescriptionOffsetX         =  8,
    RSTable3DStaggeredDescriptionOffsetY         =  9,
    RSTable3DStaggeredDescriptionOffsetZ         = 10,
    RSTable3DStaggeredDescription11              = 11,
    RSTable3DStaggeredDescriptionRecipInLnX      = 12,
    RSTable3DStaggeredDescriptionRecipInLnY      = 13,
    RSTable3DStaggeredDescriptionRecipInLnZ      = 14,
    RSTable3DStaggeredDescriptionTachikawa       = 15
};

float4 rand(uint4 *seed);
float4 set_clr(float4 att);

#pragma mark -

float4 quat_mult(float4 left, float4 right);
float4 quat_conj(float4 quat);
float4 quat_get_x(float4 quat);
float4 quat_get_y(float4 quat);
float4 quat_get_z(float4 quat);
float4 quat_rotate(float4 vector, float4 quat);

#pragma mark -

float4 complex_multiply(const float4 a, const float4 b);
float4 two_way_effects(const float4 sig_in, const float range, const float wav_num);
float4 wind_table_index(const float4 pos, const float16 wind_desc, const float16 sim_desc);
float4 compute_bg_vel(const float4 pos, __read_only image3d_t wind_uvw, const float16 wind_desc, const float16 sim_desc);
float4 compute_dudt_dwdt(float4 *dwdt, const float4 vel, const float4 vel_bg, const float4 ori, __read_only image2d_t adm_cd, __read_only image2d_t adm_cm, const float16 adm_desc);
float4 compute_rcs(float4 ori, __read_only image2d_t rcs_real, __read_only image2d_t rcs_imag, const float16 rcs_desc, const float16 sim_desc);

#pragma mark -

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
float4 set_clr(float4 aux)
{
    float g = clamp(fma(log10(aux.s3), 0.3f, 1.5f), 0.05f, 0.3f);
    
    float4 c;
    
    c.x = clamp(0.4f * aux.s1, 0.0f, 1.0f) + 0.6f * g;
    c.y = 0.9f * g;
    c.z = clamp(1.0f - c.x - 3.5f * g, 0.0f, 1.0f) + 0.2f * (g - 0.1f);
    c.w = 1.0f;
    
    return c;
}

#pragma mark -
#pragma mark Quaternion Fun

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

#pragma mark -
#pragma mark Generic Functions

/////////////////////////////////////////////////////////////////////////////////////////
//
// Complex arithmetics
//
//   - s0123 = (IH, QH, IV, QV)
//
//   - s01 is treated as one number while s23 is another
//   - s01 is only affected by another s01 and so on
//

float4 complex_multiply(const float4 a, const float4 b)
{
//    return (float4)(a.s0 * b.s0 - a.s1 * b.s1,
//                    a.s1 * b.s0 + a.s0 * b.s1,
//                    a.s2 * b.s2 - a.s3 * b.s3,
//                    a.s3 * b.s2 + a.s2 * b.s3);
    float4 iiqq = (float4)(a.s02 * b.s02 - a.s13 * b.s13,
                           a.s13 * b.s02 + a.s02 * b.s13);
    return shuffle(iiqq, (uint4)(0, 2, 1, 3));
}


/////////////////////////////////////////////////////////////////////////////////////////
//
// Two-way effects
//

float4 two_way_effects(const float4 sig_in, const float range, const float wav_num)
{
    // Range attenuation R ^ -4
    float4 atten = pown((float4)(range, range, range, range), (int4)(-4, -4, -4, -4));
//    float rinv = native_recip(range);
//    rinv *= rinv;  // () ^ -2
//    rinv *= rinv;  // () ^ -4
//    float4 atten = (float4)(rinv, rinv, rinv, rinv);

    // Return phase due to two-way path
    float phase = range * wav_num;

    // cosine & sine to represent exp(j phase)
    float c, s = sincos(phase, &c);
    
    return complex_multiply(sig_in, (float4)(c, s, c, s)) * atten;
}


/////////////////////////////////////////////////////////////////////////////////////////
//
// Wind table index
//

float4 wind_table_index(const float4 pos, const float16 wind_desc, const float16 sim_desc)
{
    const float s7 = wind_desc.s7;
    const uint grid_spacing = *(uint *)&s7;

    if (grid_spacing == RSTableSpacingStretchedXYZ) {
        // Relative position from the center of the domain
        float4 pos_rel = pos - (float4)(sim_desc.hi.s01 + 0.5f * sim_desc.hi.s45, 0.0f, 0.0f);
        //
        // Background wind table is staggered for all dimensions
        //
        //    RSTable3DStaggeredDescriptionBaseChangeX     =  0,
        //    RSTable3DStaggeredDescriptionBaseChangeY     =  1,
        //    RSTable3DStaggeredDescriptionBaseChangeZ     =  2,
        //    RSTable3DStaggeredDescriptionRefreshTime     =  3,
        //    RSTable3DStaggeredDescriptionPositionScaleX  =  4,
        //    RSTable3DStaggeredDescriptionPositionScaleY  =  5,
        //    RSTable3DStaggeredDescriptionPositionScaleZ  =  6,
        //    RSTable3DStaggeredDescription7               =  7,
        //    RSTable3DStaggeredDescriptionOffsetX         =  8,
        //    RSTable3DStaggeredDescriptionOffsetY         =  9,
        //    RSTable3DStaggeredDescriptionOffsetZ         = 10,
        //    RSTable3DStaggeredDescription11              = 11,
        //    RSTable3DStaggeredDescriptionRecipInLnX      = 12,
        //    RSTable3DStaggeredDescriptionRecipInLnY      = 13,
        //    RSTable3DStaggeredDescriptionRecipInLnZ      = 14,
        //    RSTable3DStaggeredDescriptionTachikawa       = 15,
        //
        return copysign(wind_desc.s0123, pos_rel) * log1p(wind_desc.s4567 * fabs(pos_rel)) + wind_desc.s89ab;
    } else if (grid_spacing == RSTableSpacingUniform) {
        //
        // Background wind table is uniform for all dimensions
        //
        //    RSTable3DDescriptionScaleX      =  0,
        //    RSTable3DDescriptionScaleY      =  1,
        //    RSTable3DDescriptionScaleZ      =  2,
        //    RSTable3DDescriptionRefreshTime =  3,
        //    RSTable3DDescriptionOriginX     =  4,
        //    RSTable3DDescriptionOriginY     =  5,
        //    RSTable3DDescriptionOriginZ     =  6,
        //    RSTable3DDescription7           =  7,
        //    RSTable3DDescriptionMaximumX    =  8,
        //    RSTable3DDescriptionMaximumY    =  9,
        //    RSTable3DDescriptionMaximumZ    = 10,
        //    RSTable3DDescription11          = 11,
        //    RSTable3DDescriptionRecipInLnX  = 12,
        //    RSTable3DDescriptionRecipInLnY  = 13,
        //    RSTable3DDescriptionRecipInLnZ  = 14,
        //    RSTable3DDescriptionTachikawa   = 15,
        //
        return fma(pos, wind_desc.s0123, wind_desc.s4567);
    }
    return FLOAT4_ZERO;
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Background velocity
//

float4 compute_bg_vel(const float4 pos, __read_only image3d_t wind_uvw, const float16 wind_desc, const float16 sim_desc) {
    const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;

    float4 wind_coord = wind_table_index(pos, wind_desc, sim_desc);
    
    return read_imagef(wind_uvw, sampler, wind_coord);
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Particle acceleration
//

float4 compute_dudt_dwdt(float4 *dwdt, const float4 vel, const float4 vel_bg, const float4 ori, __read_only image2d_t adm_cd, __read_only image2d_t adm_cm, const float16 adm_desc) {
    const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;

    //
    // derive alpha & beta for ADM table lookup ---------------------------------
    //
    float alpha, beta;
    
    float4 ur = vel_bg - vel;
    
    if (length(ur.xyz) > 1.0e-3f) {
        float4 u_hat = normalize(ur);
        
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
    
    // ADM values are stored as cd(x, y, z, _) + cm(x, y, z, _)
    float2 adm_coord = fma((float2)(beta, alpha), adm_desc.s01, adm_desc.s45);
    float4 cd = read_imagef(adm_cd, sampler, adm_coord);
    float4 cm = read_imagef(adm_cm, sampler, adm_coord);
    
    //    if (i == 0) {
    //        printf("adm_coord = %5.2f\n", adm_coord.x);
    //    }
    
    //
    //    RSTable3DDescriptionRecipInLnX  = 12,
    //    RSTable3DDescriptionRecipInLnY  = 13,
    //    RSTable3DDescriptionRecipInLnZ  = 14,
    //    RSTable3DDescriptionTachikawa   = 15,
    //
    const float Ta = adm_desc.sf;
    const float4 inv_inln = (float4)(adm_desc.scde, 0.0f);
    
    cd = quat_rotate(cd, ori);
    
    //    if (i == 0)
    //        printf("ur = %5.2f %5.2f %5.2f %5.2f  cdr = %5.2f %5.2f %5.2f %5.2f\n",
    //               ur.x, ur.y, ur.z, ur.w,
    //               cd.x, cd.y, cd.z, cd.w);
    
    float ur_norm_sq = dot(ur.xyz, ur.xyz);
    
    // Euler method: dudt is just a scaled version of drag coefficient
    float4 dudt = Ta * ur_norm_sq * cd + (float4)(0.0f, 0.0f, -9.8f, 0.0f);
    *dwdt = radians((Ta * ur_norm_sq * inv_inln) * cm);
    
    // Runge-Kutta: dudt is a two-point average
    //    float4 dudt1 = Ta * ur_norm_sq * cd;
    //
    //    // Project to the next lookup
    //    float4 udt1 = vel;
    //    float4 udt2 = udt1 + dt * dudt1;
    //
    //    // New delta
    //    float4 ur2 = vel_bg - udt2;
    //    float ur2_norm_sq = dot(ur2.xyz, ur2.xyz);
    //    float4 dudt2 = Ta * ur2_norm_sq * cd;
    //
    //    float4 dudt = 0.5f * (dudt1 + dudt2) + (float4)(0.0f, 0.0f, -9.8f, 0.0f);
    //    *dwdt = radians((Ta * 0.5f * (ur_norm_sq + ur2_norm_sq) * inv_inln) * cm);

    return dudt;
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Particle RCS
//

float4 compute_rcs(float4 ori, __read_only image2d_t rcs_real, __read_only image2d_t rcs_imag, const float16 rcs_desc, const float16 sim_desc) {
    const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;

    const float el = atan2(sim_desc.s2, length(sim_desc.s01));
    const float az = atan2(sim_desc.s0, sim_desc.s1);
    //
    // derive alpha, beta & gamma of RCS for RCS table lookup --------------------------
    //
    float ce, se = sincos(0.5f * el, &ce);
    float ca, sa = sincos(0.5f * az, &ca);
    
    // I know this part looks like a black box, check reference MATLAB implementation quat2euler.m for the raw version
    float4 F = (float4)(-M_SQRT1_2_F * sa * (ce + se), -M_SQRT1_2_F * ca * (ce + se), M_SQRT1_2_F * ca * (ce - se), -M_SQRT1_2_F * sa * (ce - se));
    float4 quat_rel = quat_mult(quat_mult(F, ori), (float4)(-0.5f, 0.5f, -0.5f, 0.5f));
    
    // 3-2-3 conversion:
    float alpha = atan2(quat_rel.y * quat_rel.z + quat_rel.w * quat_rel.x , quat_rel.w * quat_rel.y - quat_rel.x * quat_rel.z);
    float beta  =  acos(quat_rel.w * quat_rel.w + quat_rel.z * quat_rel.z - quat_rel.y * quat_rel.y - quat_rel.x * quat_rel.x);
    float gamma = atan2(quat_rel.y * quat_rel.z - quat_rel.w * quat_rel.x , quat_rel.x * quat_rel.z + quat_rel.w * quat_rel.y);
    
    //    printf("i = %d   ori = [ %.3f %.3f %.3f %.3f ]   BLC = [ %.4f %.4f %.4f %.4f ]  ==> abg = [ %.4f %.4f %.4f ]\n",
    //           i,
    //           ori.x, ori.y, ori.z, ori.w,
    //           quat_rel.x, quat_rel.y, quat_rel.z, quat_rel.w,
    //           degrees(alpha), degrees(beta), degrees(gamma));
    
    // RCS values are stored as real(hh, vv, hv, __) + imag(hh, vv, hv, __)
    float2 rcs_coord = fma((float2)(alpha, beta), rcs_desc.s01, rcs_desc.s45);
    float4 real = read_imagef(rcs_real, sampler, rcs_coord);
    float4 imag = read_imagef(rcs_imag, sampler, rcs_coord);
    
    // For gamma projection
    float cg, sg = sincos(gamma, &cg);
    
    //    >> Tinv * S * T
    //
    //    ans =
    //
    //    [ cos(gamma)*(hh*cos(gamma) - vh*sin(gamma)) - sin(gamma)*(hv*cos(gamma) - vv*sin(gamma)), cos(gamma)*(hv*cos(gamma) - vv*sin(gamma)) + sin(gamma)*(hh*cos(gamma) - vh*sin(gamma))]
    //    [ cos(gamma)*(vh*cos(gamma) + hh*sin(gamma)) - sin(gamma)*(vv*cos(gamma) + hv*sin(gamma)), cos(gamma)*(vv*cos(gamma) + hv*sin(gamma)) + sin(gamma)*(vh*cos(gamma) + hh*sin(gamma))]
    //
    //    HH = cos(gamma)*(hh*cos(gamma) - vh*sin(gamma)) - sin(gamma)*(hv*cos(gamma) - vv*sin(gamma))
    //    HV = cos(gamma)*(hv*cos(gamma) - vv*sin(gamma)) + sin(gamma)*(hh*cos(gamma) - vh*sin(gamma))
    //    VH = cos(gamma)*(vh*cos(gamma) + hh*sin(gamma)) - sin(gamma)*(vv*cos(gamma) + hv*sin(gamma))
    //    VV = cos(gamma)*(vv*cos(gamma) + hv*sin(gamma)) + sin(gamma)*(vh*cos(gamma) + hh*sin(gamma))
    
    float hh_real = cg * (real.s0 * cg - real.s2 * sg) - sg * (real.s2 * cg - real.s1 * sg);
    float hh_imag = cg * (imag.s0 * cg - imag.s2 * sg) - sg * (imag.s2 * cg - imag.s1 * sg);
    
    //float hv_real = cg * (real.s2 * cg - real.s1 * sg) + sg * (real.s0 * cg - real.s2 * sg);
    //float hv_imag = cg * (imag.s2 * cg - imag.s1 * sg) + sg * (imag.s0 * cg - imag.s2 * sg);
    
    //float vh_real = cg * (real.s2 * cg + real.s0 * sg) - sg * (real.s1 * cg + real.s2 * sg);
    //float vh_imag = cg * (imag.s2 * cg + imag.s0 * sg) - sg * (imag.s1 * cg + imag.s2 * sg);
    
    float vv_real = cg * (real.s1 * cg + real.s2 * sg) + sg * (real.s2 * cg + real.s1 * sg);
    float vv_imag = cg * (imag.s1 * cg + imag.s2 * sg) + sg * (imag.s2 * cg + imag.s0 * sg);
    
    // Assign signal amplitude as Hi, Hq, Vi, Vq
    return (float4)(hh_real, hh_imag, vv_real, vv_imag);
}


#pragma mark -
#pragma mark OpenCL Kernel Functions

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

//
// background attributes
//
__kernel void bg_atts(__global float4 *p,
                      __global float4 *v,
                      __global float4 *a,
                      __global uint4 *y,
                      __read_only image3d_t wind_uvw,
                      const float16 wind_desc,
                      const float16 sim_desc)
{

    const unsigned int i = get_global_id(0);
    
    float4 pos = p[i];
    float4 vel = v[i];
    float4 aux = a[i];
    
    const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;
    
    //    RSSimulationDescriptionBeamUnitX     =  0,
    //    RSSimulationDescriptionBeamUnitY     =  1,
    //    RSSimulationDescriptionBeamUnitZ     =  2,
    //    RSSimulationDescriptionDebrisCount   =  3,
    //    RSSimulationDescriptionWaveNumber    =  4,
    //    RSSimulationDescription5             =  5,
    //    RSSimulationDescription6             =  6,
    //    RSSimulationDescription7             =  7,
    //    RSSimulationDescriptionBoundOriginX  =  8,  // hi.s0
    //    RSSimulationDescriptionBoundOriginY  =  9,  // hi.s1
    //    RSSimulationDescriptionBoundOriginZ  =  10, // hi.s2
    //    RSSimulationDescriptionPRT           =  11,
    //    RSSimulationDescriptionBoundSizeX    =  12, // hi.s4
    //    RSSimulationDescriptionBoundSizeY    =  13, // hi.s5
    //    RSSimulationDescriptionBoundSizeZ    =  14, // hi.s6
    //    RSSimulationDescriptionAgeIncrement  =  15, // PRT / vel_desc.tr
    const float4 dt = (float4)(sim_desc.sb, sim_desc.sb, sim_desc.sb, 0.0f);
    
    // Future position, orientation, etc.
    pos += vel * dt;
    
    int is_outside = any(islessequal(pos.xyz, sim_desc.hi.s012) | isgreaterequal(pos.xyz, sim_desc.hi.s012 + sim_desc.hi.s456));
    
    //if (is_outside | isgreater(aux.s1, 1.0f)) {
    if (is_outside) {
        uint4 seed = y[i];
        float4 r = rand(&seed);
        pos.xyz = r.xyz * sim_desc.hi.s456 + sim_desc.hi.s012;
        //pos.xyz = (float3)(fma(r.xy, sim_desc.hi.s45, sim_desc.hi.s01), MIN_HEIGHT); // This is kind of cool
        vel = FLOAT4_ZERO;
        aux.s0 = length(pos.xyz);
        aux.s1 = 0.0f;

        p[i] = pos;
        v[i] = vel;
        a[i] = aux;
        y[i] = seed;

        return;
    } else {
        aux.s1 += sim_desc.sf;
    }

    //
    float4 wind_coord = wind_table_index(pos, wind_desc, sim_desc);
    
    vel = read_imagef(wind_uvw, sampler, wind_coord);
    
    // Range of the point
    aux.s0 = length(pos.xyz);
    
    p[i] = pos;
    v[i] = vel;
    a[i] = aux;
}

//
// ellipsoid attributes
//
__kernel void el_atts(__global float4 *p,                  // position (x, y, z) and size (radius)
                      __global float4 *v,                  // velocity (u, v, w) and a vacant float
                      __global float4 *a,                  // auxiliary info: range, ange, ____, angular weight
                      __global float4 *x,                  // signal (hh, hv, vh, vv)
                      __global uint4 *y,                   // 128-bit random seed (4 x 32-bit)
                      __read_only image3d_t wind_uvw,
                      const float16 wind_desc,
                      const float16 sim_desc)
{
    
    const unsigned int i = get_global_id(0);
    
    float4 pos = p[i];  // position
    float4 vel = v[i];  // velocity
    float4 aux = a[i];  // auxiliary
    float4 sig = x[i];  // signal

    const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;

    //    RSSimulationDescriptionBeamUnitX     =  0,
    //    RSSimulationDescriptionBeamUnitY     =  1,
    //    RSSimulationDescriptionBeamUnitZ     =  2,
    //    RSSimulationDescriptionDebrisCount   =  3,
    //    RSSimulationDescriptionWaveNumber    =  4,
    //    RSSimulationDescription5             =  5,
    //    RSSimulationDescription6             =  6,
    //    RSSimulationDescription7             =  7,
    //    RSSimulationDescriptionBoundOriginX  =  8,  // hi.s0
    //    RSSimulationDescriptionBoundOriginY  =  9,  // hi.s1
    //    RSSimulationDescriptionBoundOriginZ  =  10, // hi.s2
    //    RSSimulationDescriptionPRT           =  11,
    //    RSSimulationDescriptionBoundSizeX    =  12, // hi.s4
    //    RSSimulationDescriptionBoundSizeY    =  13, // hi.s5
    //    RSSimulationDescriptionBoundSizeZ    =  14, // hi.s6
    //    RSSimulationDescriptionAgeIncrement  =  15, // PRT / vel_desc.tr
    const float4 dt = (float4)(sim_desc.sb, sim_desc.sb, sim_desc.sb, 0.0f);
    
    //pos.w = 0.0003f; // fixed size @ .3 mm
    
    //
    // Update orientation & position ---------------------------------
    //
//    float4 ori_next = quat_mult(ori, tum);
//    if (all(isfinite(ori_next))) {
//        ori = normalize(ori_next);
//    }

    pos += vel * dt;
    
    // Check for bounding constraints
    //    RSSimulationDescriptionBoundOriginX  =  8,  // hi.s0
    //    RSSimulationDescriptionBoundOriginY  =  9,  // hi.s1
    //    RSSimulationDescriptionBoundOriginZ  =  10, // hi.s2
    //    RSSimulationDescriptionPRT           =  11,
    //    RSSimulationDescriptionBoundSizeX    =  12, // hi.s4
    //    RSSimulationDescriptionBoundSizeY    =  13, // hi.s5
    //    RSSimulationDescriptionBoundSizeZ    =  14, // hi.s6
    //    RSSimulationDescriptionAgeIncrement  =  15, // PRT / vel_desc.tr
    int is_outside = any(islessequal(pos.xyz, sim_desc.hi.s012) | isgreaterequal(pos.xyz, sim_desc.hi.s012 + sim_desc.hi.s456) | !all(isfinite(pos.xyz)));
    
    if (is_outside) {

        uint4 seed = y[i];
        float4 r = rand(&seed);
        y[i] = seed;
        pos.xyz = (float3)(fma(r.xy, sim_desc.hi.s45, sim_desc.hi.s01), MIN_HEIGHT);
        vel = FLOAT4_ZERO;
        aux.s0 = length(pos.xyz);
        sig = FLOAT4_ZERO;
        
        p[i] = pos;
        v[i] = vel;
        a[i] = aux;
        x[i] = sig;
        y[i] = seed;

        return;
    }

    float4 wind_coord = wind_table_index(pos, wind_desc, sim_desc);

    float4 bg_vel = read_imagef(wind_uvw, sampler, wind_coord);

    // Particle velocity due to drag
    float4 delta_v = bg_vel - vel;
    float delta_v_abs = length(delta_v.xyz);
    
//        if (i < 10)
//            printf("bg_vel = %.2v4f  vel = %.2v4f  delta_v = %.2v4f  bd = %.2v4f\n", bg_vel, vel, delta_v, bg_vel / dt);
//        else if (i == 10)
//            printf("--------\n");
    
    if (delta_v_abs > 1.0e-3f) {

        // Calculate Reynold's number with air density and viscousity
        const float rho_air = 1.225f;                                // 1.225 kg m^-3
        const float rho_over_mu_air = 6.7308e4f;                     // 1.225 / 1.82e-5 kg m^-1 s^-1 = 6.7308e4 (David)
        const float area_over_mass_particle = 0.003006012f / pos.w;  // 4 * PI * R ^ 2 / ( ( 4 / 3 ) * PI * R ^ 3 * rho ) = 0.0030054 / r (rho = 998)
        
        float re = rho_over_mu_air * (2.0f * pos.w) * delta_v_abs;
        float cd = 24.0f / re + 6.0f / (1.0f + sqrt(re)) + 0.4f;
        float4 dudt = (0.5f * rho_air * cd * area_over_mass_particle * delta_v_abs) * delta_v + (float4)(0.0f, 0.0f, -9.8f, 0.0f);
        //float4 dudt = (float4)(0.0f, 0.0f, -9.8f, 0.0f);

        vel += dudt * dt;

        // Bound the velocity change
//            if (length(vel) > max(1.0f, 3.0f * length(bg_vel))) {
//                //vel = normalize(vel) * length(bg_vel) + (float4)(0.0f, 0.0f, -9.8f, 0.0f) * dt;
//                vel = bg_vel + (float4)(0.0f, 0.0f, -9.8f, 0.0f) * dt;
//            }

    } else {

        vel += (float4)(0.0f, 0.0f, -9.8f, 0.0f) * dt;

    }

    // Range of the point
    aux.s0 = length(pos.xyz);
    //aux.s1 = aux.s1 + sim_desc.sf;

    // Ratio is usually in ( semi-major : semi-minor ) = ( H : V );
    // Use (1.0, 0.0) for H and (v, 0.0) for V
    // v = 1.0048 + 5.7e-4 * D - 2.628e-2 * D ^ 2 + 3.682e-3 * D ^ 3 - 1.667e-4 * D ^ 4
    // Reminder: pos.w = drop radius in m; equation below uses D in mm
    float D = 2000.0f * pos.w;
    float4 DD = pown((float4)(D, D, D, D), (int4)(1, 2, 3, 4));
    float vv = 1.0048f + dot((float4)(5.7e-4f, -2.628e-2f, 3.682e-3f, -1.667e-4f), DD);

    // H is 1.0 while V is the attenuated version as a function of aspect ratio
    sig = (float4)(1.0f, 0.0f, vv, 0.0f);
    

    p[i] = pos;
    v[i] = vel;
    a[i] = aux;
    x[i] = sig;
}

//
// debris attributes
//
__kernel void db_atts(__global float4 *p,
                      __global float4 *o,
                      __global float4 *v,
                      __global float4 *t,
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
                      const float16 sim_desc)
{
    const unsigned int i = get_global_id(0);
    
    float4 pos = p[i];  // position
    float4 ori = o[i];  // orientation
    float4 vel = v[i];  // velocity
    float4 tum = t[i];  // tumbling (orientation change)
    float4 sig = x[i];  // signal

//    if (sim_desc.s7 < 10 && i == (int)sim_desc.s3) {
//        printf("i=%.1f  ori = %5.2v4f  tum =  = %5.2v4f\n", sim_desc.s3, ori, tum);
//    }
    const float4 dt = (float4)(sim_desc.sb, sim_desc.sb, sim_desc.sb, 0.0f);
    
    //
    // Update orientation & position ---------------------------------
    //
    float4 ori_next = quat_mult(ori, tum);
    ori = normalize(ori_next);
    pos += vel * dt;
    
    // Check for bounding constraints
    //    RSSimulationDescriptionBoundOriginX  =  8,  // hi.s0
    //    RSSimulationDescriptionBoundOriginY  =  9,  // hi.s1
    //    RSSimulationDescriptionBoundOriginZ  =  10, // hi.s2
    //    RSSimulationDescriptionPRT           =  11,
    //    RSSimulationDescriptionBoundSizeX    =  12, // hi.s4
    //    RSSimulationDescriptionBoundSizeY    =  13, // hi.s5
    //    RSSimulationDescriptionBoundSizeZ    =  14, // hi.s6
    //    RSSimulationDescriptionAgeIncrement  =  15, // PRT / vel_desc.tr
    int is_outside = any(islessequal(pos.xyz, sim_desc.hi.s012) | isgreaterequal(pos.xyz, sim_desc.hi.s012 + sim_desc.hi.s456));
    
    if (is_outside) {
        uint4 seed = y[i];
        float4 r = rand(&seed);
        pos.xyz = (float3)(fma(r.xy, sim_desc.hi.s45, sim_desc.hi.s01), MIN_HEIGHT);  // This is kind of cool!
        ori = normalize(rand(&seed));
        vel = FLOAT4_ZERO;
        tum = QUAT_IDENTITY;
        sig = FLOAT4_ZERO;

        p[i] = pos;
        o[i] = ori;
        v[i] = vel;
        t[i] = tum;
        x[i] = sig;
        y[i] = seed;
        
        return;
    }

    float4 vel_bg = compute_bg_vel(pos, wind_uvw, wind_desc, sim_desc);

    float4 dwdt;
    float4 dudt = compute_dudt_dwdt(&dwdt, vel, vel_bg, ori, adm_cd, adm_cm, adm_desc);
    
    vel += dudt * dt;

    float4 dw = dwdt * dt;
   
    float4 c, s = sincos(dw, &c);
    tum = (float4)(c.x * s.y * s.z + s.x * c.y * c.z,
                   c.x * s.y * c.z - s.x * c.y * s.z,
                   c.x * c.y * s.z + s.x * s.y * c.z,
                   c.x * c.y * c.z - s.x * s.y * s.z);
    
    tum = normalize(tum);

    // bound the velocity
//    if (length(vel.xy + dudt.xy * dt.xy) > 2.0 * length(vel_bg.xy)) {
//        vel.xy = vel_bg.xy;
//    }
    
    //    if (length(vel) > length(vel_bg)) {
    //        printf("vel = [%5.2f %5.2f %5.2f %5.2f]  vel_bg = [%5.2f %5.2f %5.2f %5.2f]   %5.2f\n",
    //               vel.x, vel.y, vel.z, vel.w,
    //               vel_bg.x, vel_bg.y, vel_bg.z, vel_bg.w,
    //               ur_norm_sq
    //               );
    //    }
    
    sig = compute_rcs(ori, rcs_real, rcs_imag, rcs_desc, sim_desc);
    
    // Copy back to global memory space
    p[i] = pos;
    o[i] = ori;
    v[i] = vel;
    t[i] = tum;
    x[i] = sig;
}


__kernel void scat_sig_dsd(__global float4 *x,
                           __global float4 *p,
                           __global float4 *a)
{
    unsigned int i = get_global_id(0);
    x[i] = (float4)(1.0f, 0.0f, 1.0f, 0.0f);
}


//
// scatterer color
//
__kernel void scat_clr(__global float4 *c,
                       __global float4 *p,
                       __global float4 *a,
                       const uint4 mode)
{
    unsigned int i = get_global_id(0);
    
    if (mode.s0 == 0) {
        c[i].x = clamp(a[i].s2, 0.0f, 1.0f);
    } else {
        c[i].x = clamp(fma(log10(100.0f * a[i].s3), 0.1f, 0.8f), 0.0f, 1.0f);
        //    if (i < 20) {
        //        printf("i=%d  w=%.4f\n", i, c[i].x);
        //        //printf("i=%d  d=%.1fmm  c=%.3f\n", i, p[i].w * 1000.0f, c[i].x);
        //    }
    }
}

//
// weight and attenuate - angular + range effects
//
__kernel void scat_wa(__global float4 *s,
                      __global float4 *a,
                      __global float4 *p,
                      __constant float *angular_weight,
                      const float4 angular_weight_desc,
                      const float16 sim_desc)
{
    unsigned int i = get_global_id(0);

    float4 sig = s[i];
    float4 aux = a[i];
    float4 pos = p[i];
    
    //    RSSimulationDescriptionBeamUnitX     =  0,
    //    RSSimulationDescriptionBeamUnitY     =  1,
    //    RSSimulationDescriptionBeamUnitZ     =  2,
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
    
    //
    // Auxiliary info:
    // - s0 = range of the point
    // - s1 = age
    // - s2 =
    // - s3 = angular weight (make_pulse_pass_1)
    //
    aux.s0 = length(pos.xyz);
    aux.s1 = aux.s1 + sim_desc.sf;
    aux.s3 = mix(angular_weight[iidx_int.s0], angular_weight[iidx_int.s1], fidx_dec.s0);
    
    sig = two_way_effects(sig, aux.s0, sim_desc.s4);
    
    s[i] = sig;
    a[i] = aux;
}

//
// out - output
// sig - signal
// aux - auxiliary attributes
// shared - local memory space __local space (64 kB max)
// range_weight - range weighting function, __constant space (64 kB max)
// range_weight_desc - scale, offset, and max to convert range to table index
// range_start - start range of the domain
// range_delta - range spacing (not resolution)
// range_count - number of range gates
// group_count - number of parallel groups
// n - total number of elements (for this GPU device)
//
__kernel void make_pulse_pass_1(__global float4 *out,
                                __global float4 *sig,
                                __global float4 *aux,
                                __local float4 *shared,
                                __constant float *range_weight,
                                const float4 range_weight_desc,
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
    
    const float4 table_xs_4 = (float4)range_weight_desc.s0;
    const float4 table_x0_4 = (float4)range_weight_desc.s1 + (float4)(0.0f, 1.0f, 0.0f, 1.0f);
    
    float r_a;
    float r_b;
    
    float4 r;
    
    float4 s_a;
    float4 s_b;
    float4 w_a;
    float4 w_b;
    
    unsigned int i = group_id * group_stride + local_id;
    unsigned int j;
    unsigned int k;
    
    // Initialize the block of local memory to zeros
    for (k = 0; k < range_count; k++) {
        shared[local_id + k * local_size] = zero;
    }
    
    //	printf("group_id=%d  local_id=%d  local_size=%d  range_count=%d\n", group_id, local_id, local_size, range_count);
    
    float4 fidx_raw;
    float4 fidx_int;
    float4 fidx_dec;
    uint4  iidx_int;
    
    // Will use:
    // Elements 0 & 1 for scatter body from the left group (a); use i indexing
    // Elements 2 & 3 for scatter body from the right group (b); use j indexing
    // Linearly interpolate weights of element 0 & 1 using decimal fraction stored in dec.s0
    // Linearly interpolate weights of element 2 & 3 using decimal fraction stored in dec.s2
    // Why do it like this rather than the plain C code? Keep the CU's SIMD processors busy.
    
    while (i < n) {
        j = i + local_size;
        
        s_a = sig[i];
        s_b = sig[j];
        r_a = aux[i].s0;
        r_b = aux[j].s0;
        r = (float4)range_start;

        // Angular weight
        s_a *= aux[i].s3;
        s_b *= aux[j].s3;

        for (k = 0; k < range_count; k++) {
            float4 dr_from_center = (float4)(r_a, r_a, r_b, r_b) - r;
            
            // This part can probably be replaced by read_imagef()
            fidx_raw = clamp(fma(dr_from_center, table_xs_4, table_x0_4), 0.0f, range_weight_desc.s2);     // Index [0 ... xm] in float
            fidx_dec = fract(fidx_raw, &fidx_int);                                                         // The integer and decimal fraction
            iidx_int = convert_uint4(fidx_int);
            
            // Range weight
            float2 w2 = mix((float2)(range_weight[iidx_int.s0], range_weight[iidx_int.s2]),
                            (float2)(range_weight[iidx_int.s1], range_weight[iidx_int.s3]),
                            fidx_dec.s02);
            
            // Vectorized range * angular weights
            w_a = (float4)w2.s0;
            w_b = (float4)w2.s1;
            
            shared[local_id + k * local_size] += (w_a * s_a + w_b * s_b);

            r += range_delta;
        }
        i += local_stride;
    }
    barrier(CLK_LOCAL_MEM_FENCE);
    
    unsigned int local_numel = range_count * local_size;
    
    // Consolidate the local memory
    if (local_size > 512 && local_id < 512)
    {
        for (k = 0; k < local_numel; k += local_size)
            shared[local_id + k] += shared[local_id + k + 512];
    }
    barrier(CLK_LOCAL_MEM_FENCE);

    if (local_size > 256 && local_id < 256)
    {
        for (k = 0; k < local_numel; k += local_size)
            shared[local_id + k] += shared[local_id + k + 256];
    }
    barrier(CLK_LOCAL_MEM_FENCE);

    if (local_size > 128 && local_id < 128)
    {
        for (k = 0; k < local_numel; k += local_size)
            shared[local_id + k] += shared[local_id + k + 128];
    }
    barrier(CLK_LOCAL_MEM_FENCE);
    
    if (local_size > 64 && local_id < 64)
    {
        for (k = 0; k < local_numel; k += local_size)
            shared[local_id + k] += shared[local_id + k + 64];
    }
    barrier(CLK_LOCAL_MEM_FENCE);
    
    if (local_size > 32 && local_id < 32)
    {
        for (k = 0; k < local_numel; k += local_size)
            shared[local_id + k] += shared[local_id + k + 32];
    }
    barrier(CLK_LOCAL_MEM_FENCE);
    
    if (local_size > 16 && local_id < 16)
    {
        for (k = 0; k < local_numel; k += local_size)
            shared[local_id + k] += shared[local_id + k + 16];
    }
    barrier(CLK_LOCAL_MEM_FENCE);
    
    if (local_size > 8 && local_id < 8)
    {
        for (k = 0; k < local_numel; k += local_size)
            shared[local_id + k] += shared[local_id + k + 8];
    }
    barrier(CLK_LOCAL_MEM_FENCE);
    
    if (local_size > 4 && local_id < 4)
    {
        for (k = 0; k < local_numel; k += local_size)
            shared[local_id + k] += shared[local_id + k + 4];
    }
    barrier(CLK_LOCAL_MEM_FENCE);
    
    if (local_size > 2 && local_id < 2)
    {
        for (k = 0; k < local_numel; k += local_size)
            shared[local_id + k] += shared[local_id + k + 2];
    }
    barrier(CLK_LOCAL_MEM_FENCE);
    
    if (local_size > 1 && local_id < 1)
    {
        for (k = 0; k < local_numel; k += local_size)
            shared[local_id + k] += shared[local_id + k + 1];
    }
    barrier(CLK_LOCAL_MEM_FENCE);
    
    if (local_id == 0)
    {
        __global float4 *o = &out[group_id * range_count];
        for (k = 0; k < range_count * local_size; k += local_size) {
            //printf("groupd_id=%d  out[%d] = shared[%d] = %.2f\n", group_id, (int)(o - out), k, shared[k].x);
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

// Generate some random data
__kernel void pop(__global float4 *sig, __global float4 *aux, __global float4 *pos, const float16 sim_desc)
{
    unsigned int k = get_global_id(0);
    
    float4 p = (float4)((float)(k % 9) - 4.0f, (float)k / 90000.0f + 1.0f, 0.1f, 1.0f);

    sig[k] = (float4)(1.0f, 0.5f, 1.0f, 0.5f);
    aux[k] = (float4)(length(p.xyz), 1.0f, acos(dot(sim_desc.s012, normalize(p.xyz))), 1.0f);
    pos[k] = p;
}
