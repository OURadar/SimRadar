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

enum RSSimulationConcept {
    RSSimulationConceptNull                    = 0,
    RSSimulationConceptDraggedBackground       = 1,
    RSSimulationConceptBoundedParticleVelocity = 1 << 1
};

enum RSSimulationDescription {
    RSSimulationDescriptionBeamUnitX          =  0,
    RSSimulationDescriptionBeamUnitY          =  1,
    RSSimulationDescriptionBeamUnitZ          =  2,
    RSSimulationDescriptionTotalParticles     =  3,
    RSSimulationDescriptionWaveNumber         =  4,
    RSSimulationDescriptionConcept            =  5,
    RSSimulationDescription6                  =  6,
    RSSimulationDescriptionSimTic             =  7,
    RSSimulationDescriptionBoundOriginX       =  8,  // hi.s0
    RSSimulationDescriptionBoundOriginY       =  9,  // hi.s1
    RSSimulationDescriptionBoundOriginZ       =  10, // hi.s2
    RSSimulationDescriptionTimeIncrement      =  11,
    RSSimulationDescriptionBoundSizeX         =  12, // hi.s4
    RSSimulationDescriptionBoundSizeY         =  13, // hi.s5
    RSSimulationDescriptionBoundSizeZ         =  14, // hi.s6
    RSSimulationDescription15                 =  15  //
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

#pragma mark -

const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;

#pragma mark -

float4 rand(uint4 *seed);

#pragma mark -

float4 quat_mult(float4 left, float4 right);
float4 quat_conj(float4 quat);
float4 quat_get_x(float4 quat);
float4 quat_get_y(float4 quat);
float4 quat_get_z(float4 quat);
float4 quat_rotate(float4 vector, float4 quat);

#pragma mark -

float4 cl_complex_multiply(const float4 a, const float4 b);
float4 cl_complex_divide(const float4 a, const float4 b);
float4 wind_table_index(const float4 pos, const float16 wind_desc, const float16 sim_desc);
float4 compute_bg_vel(const float4 pos, __read_only image3d_t wind_uvw, const float16 wind_desc, const float16 sim_desc);
float4 compute_dudt_dwdt(float4 *dwdt, const float4 vel, const float4 vel_bg, const float4 ori, __read_only image2d_t adm_cd, __read_only image2d_t adm_cm, const float16 adm_desc);
//float4 compute_ellipsoid_rcs(const float4 pos, __read_only image1d_t rcs, const float4 rcs_desc);
float4 compute_ellipsoid_rcs(const float4 pos, __constant float4 *table, const float4 table_desc);
float4 compute_debris_rcs(const float4 pos, const float4 ori, __read_only image2d_t rcs_real, __read_only image2d_t rcs_imag, const float16 rcs_desc, const float16 sim_desc);

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
//   - s01 is only affected by another s01
//   - s23 is only affected by another s23
//

float4 cl_complex_multiply(const float4 a, const float4 b)
{
//    return (float4)(a.s0 * b.s0 - a.s1 * b.s1,
//                    a.s1 * b.s0 + a.s0 * b.s1,
//                    a.s2 * b.s2 - a.s3 * b.s3,
//                    a.s3 * b.s2 + a.s2 * b.s3);
    float4 iiqq = (float4)(a.s02 * b.s02 - a.s13 * b.s13,
                           a.s13 * b.s02 + a.s02 * b.s13);
    return shuffle(iiqq, (uint4)(0, 2, 1, 3));
}

float4 cl_complex_divide(const float4 a, const float4 b)
{
    float bm01 = dot(b.s01, b.s01);
    float bm23 = dot(b.s23, b.s23);
    float4 iiqq = (float4)(a.s02 * b.s02 + a.s13 * b.s13,
                           a.s13 * b.s02 - a.s02 * b.s13)
                / (float4)(bm01, bm23, bm01, bm23);
    return shuffle(iiqq, (uint4)(0, 2, 1, 3));
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

    float4 wind_coord = wind_table_index(pos, wind_desc, sim_desc);
    
    return read_imagef(wind_uvw, sampler, wind_coord);
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Particle acceleration
//

float4 compute_dudt_dwdt(float4 *dwdt,
                         const float4 vel,
                         const float4 vel_bg,
                         const float4 ori,
                         __read_only image2d_t adm_cd,
                         __read_only image2d_t adm_cm,
                         const float16 adm_desc) {
    //
    // derive alpha & beta for ADM table lookup ---------------------------------
    //
    float alpha, beta;
    
    float4 ur = vel_bg - vel;
    float4 u_hat = quat_rotate(normalize(ur), quat_conj(ori));
    
    beta = acos(u_hat.x);
    alpha = atan2(u_hat.z, u_hat.y);
    if (alpha < 0.0f) {
        alpha = M_PI_F + alpha;
        beta = -beta;
    }

    // ADM values are stored as cd(x, y, z, _) + cm(x, y, z, _)
    float2 adm_coord = fma((float2)(beta, alpha), adm_desc.s01, adm_desc.s45);
    float4 cd = read_imagef(adm_cd, sampler, adm_coord);
    float4 cm = read_imagef(adm_cm, sampler, adm_coord);
    
//    if (get_global_id(0) == 0) {
//        printf("ori = %10.7v4f   u_hat = %+10.7v4f   ba%+10.7f%+10.7f   coord = %5.2v2f - (%+10.7v4f ; %+10.7v4f)\n", ori, u_hat, beta, alpha, adm_coord, cd, cm);
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
    // NOTE: cm is concatenate on the right, which means rotation on local coordinate, there is no need for coordinate transformation at this point.
    
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

float4 compute_ellipsoid_rcs(const float4 pos, __constant float4 *table, const float4 table_desc) {
    // Clamp to the edge, pick the nearest coefficient
    float fidx = clamp(fma(pos.w, table_desc.s0, table_desc.s1), 0.0f, table_desc.s2);
    uint idx = (uint)fidx;

    // Actual weight in the table
    float4 xz = table[idx];
    
    const float beta = atan2(pos.s2, length(pos.s01));
    float cb = cos(beta);

    return (float4)(xz.s01, xz.s01 + (xz.s23 - xz.s01) * cb * cb);
}

float4 compute_debris_rcs(const float4 pos, const float4 ori, __read_only image2d_t rcs_real, __read_only image2d_t rcs_imag, const float16 rcs_desc, const float16 sim_desc) {

    const float el = atan2(pos.s2, length(pos.s01));
    const float az = atan2(pos.s0, pos.s1);
    
//    const float el_beam = atan2(sim_desc.s2, length(sim_desc.s01));
//    const float az_beam = atan2(sim_desc.s0, sim_desc.s1);
    
    //
    // derive alpha, beta & gamma of RCS for RCS table lookup --------------------------
    //
    // I know this part looks like a black box, check reference MATLAB implementation quat_ref_change.m for the derivation
    //
//    float ce, se = sincos(0.5f * (el - el_beam + M_PI_2_F), &ce);
//    float ca, sa = sincos(0.5f * (az - az_beam), &ca);
    float ce, se = sincos(0.5f * (el + M_PI_2_F), &ce);
    float ca, sa = sincos(0.5f * (az), &ca);
    
    // O_conj.' =
    //
    //  - (2^(1/2)*cos(a/2)*sin(e/2 + pi/4))/2 + (2^(1/2)*sin(a/2)*cos(e/2 + pi/4))/2
    //    (2^(1/2)*cos(a/2)*cos(e/2 + pi/4))/2 + (2^(1/2)*sin(a/2)*sin(e/2 + pi/4))/2
    //    (2^(1/2)*cos(a/2)*sin(e/2 + pi/4))/2 + (2^(1/2)*sin(a/2)*cos(e/2 + pi/4))/2
    //    (2^(1/2)*cos(a/2)*cos(e/2 + pi/4))/2 - (2^(1/2)*sin(a/2)*sin(e/2 + pi/4))/2
    float4 o_conj = ((float4)(-se, ce, se, ce) * ca + (float4)(ce, se, ce, -se) * sa) * M_SQRT1_2_F;
    
    // Relative rotation from the identity
    float4 R = quat_mult(ori, o_conj);
    
    // Axis shuffle for reference frame permutation (ADM -> RCS)
    float4 quat_rel = (float4)(R.x, R.z, -R.y, R.w);
    
    float alpha;
    float beta;
    float gamma;
    
    // Special treatment for beta angles close to 0 & 180 (beta_arg close to +1 or -1)
    float beta_arg = quat_rel.w * quat_rel.w + quat_rel.z * quat_rel.z - quat_rel.y * quat_rel.y - quat_rel.x * quat_rel.x;
    // Lump everything to gamma when beta ~ 0.0f deg or 180.0 deg (< 1.0 deg or > 179.0 deg);
    if (beta_arg > 0.999847f || beta_arg < -0.999847f) {
        alpha = 0.0f;
        beta = 0.0f;
        gamma = sign(quat_rel.z) * acos(quat_rel.w) * 2.0f;
    } else {
        alpha = atan2(quat_rel.y * quat_rel.z - quat_rel.w * quat_rel.x , quat_rel.x * quat_rel.z + quat_rel.w * quat_rel.y);
        beta  =  acos(quat_rel.w * quat_rel.w + quat_rel.z * quat_rel.z - quat_rel.y * quat_rel.y - quat_rel.x * quat_rel.x);
        gamma = atan2(quat_rel.y * quat_rel.z + quat_rel.w * quat_rel.x , quat_rel.w * quat_rel.y - quat_rel.x * quat_rel.z);
    }

    // RCS values are stored as real(hh, vv, hv, __) + imag(hh, vv, hv, __)
    float2 rcs_coord = fma((float2)(alpha, beta), rcs_desc.s01, rcs_desc.s45);
    float4 real = read_imagef(rcs_real, sampler, rcs_coord);
    float4 imag = read_imagef(rcs_imag, sampler, rcs_coord);
    
    // For gamma projection
    float cg, sg = sincos(gamma, &cg);
    
    // Check smat.m for derivation
    float hh_real = cg * (cg * real.s0 - real.s2 * sg) - sg * (cg * real.s2 - real.s1 * sg);
    float hh_imag = cg * (cg * imag.s0 - imag.s2 * sg) - sg * (cg * imag.s2 - imag.s1 * sg);
//    float hv_real = cg * (cg * real.s2 + real.s0 * sg) - sg * (cg * real.s1 + real.s2 * sg);
//    float hv_imag = cg * (cg * imag.s2 + imag.s0 * sg) - sg * (cg * imag.s1 + imag.s2 * sg);
//    float vh_real = cg * (cg * real.s2 - real.s1 * sg) + sg * (cg * real.s0 - real.s2 * sg);
//    float vh_imag = cg * (cg * imag.s2 - imag.s1 * sg) + sg * (cg * imag.s0 - imag.s2 * sg);
    float vv_real = cg * (cg * real.s1 + real.s2 * sg) + sg * (cg * real.s2 + real.s0 * sg);
    float vv_imag = cg * (cg * imag.s1 + imag.s2 * sg) + sg * (cg * imag.s2 + imag.s0 * sg);
    
    // Assign signal amplitude as Hi, Hq, Vi, Vq
    return (float4)(hh_real, hh_imag, vv_real, vv_imag);
    //return (float4)(hh_real + vh_real, hh_imag + vh_imag, vv_real + hv_real, vv_imag + hv_imag);
    //return (float4)(hh_real + hv_real, hh_imag + hv_imag, vv_real + vh_real, vv_imag + vh_imag);
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

__kernel void dummy(__read_only __global float4 *p,
                    __global float4 *o,
                    __global float4 *x,
                    __read_only image2d_t rcs_real,
                    __read_only image2d_t rcs_imag,
                    const float16 rcs_desc,
                    const float16 sim_desc)
{
    unsigned int i = get_global_id(0);
    
    float4 pos = p[i];
    float4 ori = o[i];
    
//    float t = sim_desc.s7 * 0.01f;

//    float4 t4 = clamp(-(float4)(0.0f, 2.0f, 4.0f, 6.0f) + t, 0.0f, 1.0f);
//    float4 angles = t4 * M_PI_F;
    
    //float4 angles = M_PI_F * sin((float4)(0.0f, 0.2f, 0.4f, 6.0f) + t);
    
//    if (i == 0) {
//        printf("t = %.2f, angles = %.2v4f\n", t, angles * 180.0f / M_PI_2_F);
//    }
    
    const float el = atan2(pos.s2, length(pos.s01));
    const float az = atan2(pos.s0, pos.s1);
    
    const float el_beam = atan2(sim_desc.s2, length(sim_desc.s01));
    const float az_beam = atan2(sim_desc.s0, sim_desc.s1);

    //
    // derive alpha, beta & gamma of RCS for RCS table lookup --------------------------
    //
    // I know this part looks like a black box, check reference MATLAB implementation quat_ref_change.m for the derivation
    //
    float ce, se = sincos(0.5f * (el - el_beam + M_PI_2_F), &ce);
    float ca, sa = sincos(0.5f * (az - az_beam), &ca);

    // O_conj.' =
    //
    //  - (2^(1/2)*cos(a/2)*sin(e/2 + pi/4))/2 + (2^(1/2)*sin(a/2)*cos(e/2 + pi/4))/2
    //    (2^(1/2)*cos(a/2)*cos(e/2 + pi/4))/2 + (2^(1/2)*sin(a/2)*sin(e/2 + pi/4))/2
    //    (2^(1/2)*cos(a/2)*sin(e/2 + pi/4))/2 + (2^(1/2)*sin(a/2)*cos(e/2 + pi/4))/2
    //    (2^(1/2)*cos(a/2)*cos(e/2 + pi/4))/2 - (2^(1/2)*sin(a/2)*sin(e/2 + pi/4))/2
    float4 o_conj = ((float4)(-se, ce, se, ce) * ca + (float4)(ce, se, ce, -se) * sa) * M_SQRT1_2_F;

//    ori = quat_conj(o_conj);


//    float4 u = (float4)( 0.5f, -0.5f , -0.5f,  0.5f );
//    float4 rr = (float4)( 0.0f, 0.0f, sin(0.5f * angles.s0),  cos(0.5f * angles.s0));
    
//    float4 ra = (float4)( 0.0f, -sin(0.5f * angles.s0), 0.0f, cos(0.5f * angles.s0));
//    float4 rb = (float4)( 0.0f, 0.0f, sin(0.5f * angles.s1),  cos(0.5f * angles.s1));
//    float4 rc = (float4)( 0.0f, -sin(0.5f * angles.s2), 0.0f, cos(0.5f * angles.s2));
    
    // Change the orientation
//    ori = quat_mult(quat_mult(quat_mult(ra, rb), rc), u);
//    ori = quat_mult(quat_mult(quat_mult(ra, rb), rc), ori);
//    ori = quat_mult(rr, u);

    //x[i] = compute_debris_rcs(pos, ori, rcs_real, rcs_imag, rcs_desc, sim_desc);
//    const float el = atan2(pos.s2, length(pos.s01));
//    const float az = atan2(pos.s0, pos.s1);
    
    //    const float el = 0.0f;
    //    const float az = 0.0f;
    
    //
    // derive alpha, beta & gamma of RCS for RCS table lookup --------------------------
    //
    // I know this part looks like a black box, check reference MATLAB implementation quat_ref_change.m for the derivation
    //
//    float ce, se = sincos(0.5f * el + M_PI_4_F, &ce);
//    float ca, sa = sincos(0.5f * az, &ca);
    
    // O_conj.' =
    //
    //  - (2^(1/2)*cos(a/2)*sin(e/2 + pi/4))/2 + (2^(1/2)*sin(a/2)*cos(e/2 + pi/4))/2
    //    (2^(1/2)*cos(a/2)*cos(e/2 + pi/4))/2 + (2^(1/2)*sin(a/2)*sin(e/2 + pi/4))/2
    //    (2^(1/2)*cos(a/2)*sin(e/2 + pi/4))/2 + (2^(1/2)*sin(a/2)*cos(e/2 + pi/4))/2
    //    (2^(1/2)*cos(a/2)*cos(e/2 + pi/4))/2 - (2^(1/2)*sin(a/2)*sin(e/2 + pi/4))/2
//    float4 o_conj = ((float4)(-se, ce, se, ce) * ca + (float4)(ce, se, ce, -se) * sa) * M_SQRT1_2_F;
    
    // Relative rotation from the identity
    float4 R = quat_mult(ori, o_conj);
    
    // Axis shuffle for reference frame permutation (ADM -> RCS)
    float4 quat_rel = (float4)(R.x, R.z, -R.y, R.w);
    
    // 3-2-3 conversion:
    float alpha;
    float beta;
    float gamma;
    
    // Special treatment for beta angles close to 0 & 180 (beta_arg close to +1 or -1)
    float beta_arg = quat_rel.w * quat_rel.w + quat_rel.z * quat_rel.z - quat_rel.y * quat_rel.y - quat_rel.x * quat_rel.x;
    // Lump everything to gamma when beta ~ 0.0f deg or 180.0 deg (< 1.0 deg or > 179.0 deg);
    if (beta_arg > 0.999847f || beta_arg < -0.999847f) {
        alpha = 0.0f;
        beta = 0.0f;
        gamma = sign(quat_rel.z) * acos(quat_rel.w) * 2.0f;
    } else {
        alpha = atan2(quat_rel.y * quat_rel.z - quat_rel.w * quat_rel.x , quat_rel.x * quat_rel.z + quat_rel.w * quat_rel.y);
        beta  =  acos(quat_rel.w * quat_rel.w + quat_rel.z * quat_rel.z - quat_rel.y * quat_rel.y - quat_rel.x * quat_rel.x);
        gamma = atan2(quat_rel.y * quat_rel.z + quat_rel.w * quat_rel.x , quat_rel.w * quat_rel.y - quat_rel.x * quat_rel.z);
    }

//    if (i == 0) {
//        printf("beam @ %.1f %.1f  q = [%6.3v4f]  abg = [%6.3f %6.3f %6.3f]\n", degrees(el_beam), degrees(az_beam), quat_rel, alpha, beta, gamma);
//    }
    
    // RCS values are stored as real(hh, vv, hv, __) + imag(hh, vv, hv, __)
    float2 rcs_coord = fma((float2)(alpha, beta), rcs_desc.s01, rcs_desc.s45);
    float4 real = read_imagef(rcs_real, sampler, rcs_coord);
    float4 imag = read_imagef(rcs_imag, sampler, rcs_coord);

    // For gamma projection
    float cg, sg = sincos(gamma, &cg);
    
    // Check smat.m for derivation
    float hh_real = cg * (cg * real.s0 - real.s2 * sg) - sg * (cg * real.s2 - real.s1 * sg);
    float hh_imag = cg * (cg * imag.s0 - imag.s2 * sg) - sg * (cg * imag.s2 - imag.s1 * sg);
//    float hv_real = cg * (cg * real.s2 + real.s0 * sg) - sg * (cg * real.s1 + real.s2 * sg);
//    float hv_imag = cg * (cg * imag.s2 + imag.s0 * sg) - sg * (cg * imag.s1 + imag.s2 * sg);
//    float vh_real = cg * (cg * real.s2 - real.s1 * sg) + sg * (cg * real.s0 - real.s2 * sg);
//    float vh_imag = cg * (cg * imag.s2 - imag.s1 * sg) + sg * (cg * imag.s0 - imag.s2 * sg);
    float vv_real = cg * (cg * real.s1 + real.s2 * sg) + sg * (cg * real.s2 + real.s0 * sg);
    float vv_imag = cg * (cg * imag.s1 + imag.s2 * sg) + sg * (cg * imag.s2 + imag.s0 * sg);
    
    
    
    
    // Assign signal amplitude as Hi, Hq, Vi, Vq
//    float4 ss = (float4)(hh_real + vh_real, hh_imag + vh_imag, vv_real + hv_real, vv_imag + hv_imag);
    float4 ss = (float4)(hh_real, hh_imag, vv_real, vv_imag);

//    if (i == 0) {
//        float hh = dot(ss.s01, ss.s01);
//        float vv = dot(ss.s23, ss.s23);
//        printf("abc = [%7.2v3f]  abg' = [%7.2f %7.2f %7.2f]  cg = %.3f  %.3e / %.3e -> %.2f dB\n",
//               degrees(angles.s012), degrees(alpha), degrees(beta), degrees(gamma), cg, hh, vv, 10.0f * log10(hh / vv));
//    }
    
//    o[i] = ori;
    x[i] = ss;
}

//
// background attributes
//
__kernel void bg_atts(__global float4 *p,
                      __global float4 *v,
                      __global float4 *x,
                      __global uint4 *y,
                      __read_only image3d_t wind_uvw,
                      const float16 wind_desc,
                      __constant float4 *drop_rcs,
                      const float4 drop_rcs_desc,
                      const float16 sim_desc)
{

    const unsigned int i = get_global_id(0);
    const float4 dt = (float4)(sim_desc.sb, sim_desc.sb, sim_desc.sb, 0.0f);

    float4 pos = p[i];
    float4 vel = v[i];
    
    pos += vel * dt;
    
    int is_outside = any(islessequal(pos.xyz, sim_desc.hi.s012) | isgreaterequal(pos.xyz, sim_desc.hi.s012 + sim_desc.hi.s456));
    
    if (is_outside) {
        uint4 seed = y[i];
        float4 r = rand(&seed);
        pos.xyz = r.xyz * sim_desc.hi.s456 + sim_desc.hi.s012;
        //pos.xyz = (float3)(fma(r.xy, sim_desc.hi.s45, sim_desc.hi.s01), MIN_HEIGHT);   // Feed from the bottom
        vel = FLOAT4_ZERO;

        p[i] = pos;
        v[i] = vel;
        y[i] = seed;

        return;
    }

    // Derive the lookup index
    float4 wind_coord = wind_table_index(pos, wind_desc, sim_desc);
    
    // Look up the background velocity from the table
    vel = read_imagef(wind_uvw, sampler, wind_coord);
    
    float4 rcs = compute_ellipsoid_rcs(pos, drop_rcs, drop_rcs_desc);
    
    p[i] = pos;
    v[i] = vel;
    x[i] = rcs;
}

//
// ellipsoid attributes
//
__kernel void el_atts(__global float4 *p,                  // position (x, y, z) and size (radius)
                      __global float4 *v,                  // velocity (u, v, w) and a vacant float
                      __global float4 *x,                  // rcs (hi, hq, vi, vq) of the particle
                      __global uint4 *y,                   // 128-bit random seed (4 x 32-bit)
                      __read_only image3d_t wind_uvw,
                      const float16 wind_desc,
                      __constant float4 *drop_rcs,
                      const float4 drop_rcs_desc,
                      const float16 sim_desc)
{
    
    const unsigned int i = get_global_id(0);
    const float4 dt = (float4)(sim_desc.sb, sim_desc.sb, sim_desc.sb, 0.0f);
    
    float4 pos = p[i];  // position
    float4 vel = v[i];  // velocity

    const float s5 = sim_desc.s5;
    const uint concept = *(uint *)&s5;

    pos += vel * dt;
    
    int is_outside = any(islessequal(pos.xyz, sim_desc.hi.s012) | isgreaterequal(pos.xyz, sim_desc.hi.s012 + sim_desc.hi.s456));
    
    if (is_outside) {
        uint4 seed = y[i];
        float4 r = rand(&seed);
        y[i] = seed;
        //pos.xyz = (float3)(fma(r.xy, sim_desc.hi.s45, sim_desc.hi.s01), MIN_HEIGHT);   // Feed from the bottom
        pos.xyz = fma(r.xyz, sim_desc.hi.s456, sim_desc.hi.s012);
        vel = FLOAT4_ZERO;
        
        p[i] = pos;
        v[i] = vel;
        y[i] = seed;

        return;
    }

    // Derive the lookup index
    float4 wind_coord = wind_table_index(pos, wind_desc, sim_desc);

    // Look up the background velocity from the table
    float4 bg_vel = read_imagef(wind_uvw, sampler, wind_coord);

    // Particle velocity due to drag
    float4 delta_v = bg_vel - vel;
    float delta_v_abs = length(delta_v.xyz);
    
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
        if (concept & RSSimulationConceptBoundedParticleVelocity && length(vel) > max(1.0f, 3.0f * length(bg_vel))) {
            //vel = normalize(vel) * length(bg_vel) + (float4)(0.0f, 0.0f, -9.8f, 0.0f) * dt;
            vel = bg_vel + (float4)(0.0f, 0.0f, -9.8f, 0.0f) * dt;
        }

    } else {

        vel += (float4)(0.0f, 0.0f, -9.8f, 0.0f) * dt;

    }
    
    float4 rcs = compute_ellipsoid_rcs(pos, drop_rcs, drop_rcs_desc);
    
//    if (get_global_id(0) < 3) {
//        float a = length(rcs.s01);
//        float b = length(rcs.s23);
//        float r = a / b;
//        printf("D %.1fmm   rcs=%.3v4e  a=%.3e  b=%.3e  h/v=%.2f dB\n", pos.w * 2000.0f, rcs, a, b, 20 * log10(r));
//    }

    p[i] = pos;
    v[i] = vel;
    x[i] = rcs;
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

    float4 rcs;  // radar cross section

    const float s5 = sim_desc.s5;
    const uint concept = *(uint *)&s5;

    const float4 dt = (float4)(sim_desc.sb, sim_desc.sb, sim_desc.sb, 0.0f);
    
    //
    // Update orientation & position ---------------------------------
    //
    float4 ori_next = quat_mult(ori, tum);
    ori = normalize(ori_next);
    pos += vel * dt;
    
    int is_outside = any(islessequal(pos.xyz, sim_desc.hi.s012) | isgreaterequal(pos.xyz, sim_desc.hi.s012 + sim_desc.hi.s456));
    
    if (is_outside) {
        uint4 seed = y[i];
        float4 r = rand(&seed);
        pos.xyz = (float3)(fma(r.xy, sim_desc.hi.s45, sim_desc.hi.s01), MIN_HEIGHT);  // This is kind of cool!
        ori = normalize(rand(&seed));
        vel = FLOAT4_ZERO;
        tum = QUAT_IDENTITY;
        rcs = FLOAT4_ZERO;

        p[i] = pos;
        o[i] = ori;
        v[i] = vel;
        t[i] = tum;
        x[i] = rcs;
        y[i] = seed;
        
        return;
    }

    float4 vel_bg = compute_bg_vel(pos, wind_uvw, wind_desc, sim_desc);

    float4 dwdt, dudt = compute_dudt_dwdt(&dwdt, vel, vel_bg, ori, adm_cd, adm_cm, adm_desc);
    
    // bound the velocity
    if (concept & RSSimulationConceptBoundedParticleVelocity && length(vel.xy + dudt.xy * dt.xy) > 3.0f * length(vel_bg.xy)) {
        //printf("vel = [%5.2v4f]  vel_bg = [%5.2v4f]\n", vel, vel_bg);
        vel.xy = vel_bg.xy;
        vel.z += dudt.z * dt.z;
    } else {
        vel += dudt * dt;
    }

    float4 dw = dwdt * dt;
   
    float4 c, s = sincos(dw, &c);
    tum = (float4)(c.x * s.y * s.z + s.x * c.y * c.z,
                   c.x * s.y * c.z - s.x * c.y * s.z,
                   c.x * c.y * s.z + s.x * s.y * c.z,
                   c.x * c.y * c.z - s.x * s.y * s.z);
    
    tum = normalize(tum);

    rcs = compute_debris_rcs(pos, ori, rcs_real, rcs_imag, rcs_desc, sim_desc);
    
    // Copy back to global memory space
    p[i] = pos;
    o[i] = ori;
    v[i] = vel;
    t[i] = tum;
    x[i] = rcs;
}

__kernel void db_rcs(__global float4 *p,
                     __global float4 *o,
                     __global float4 *x,
                     __read_only image2d_t rcs_real,
                     __read_only image2d_t rcs_imag,
                     const float16 rcs_desc,
                     const float16 sim_desc)
{
    const unsigned int i = get_global_id(0);
    x[i] = compute_debris_rcs(p[i], o[i], rcs_real, rcs_imag, rcs_desc, sim_desc);
}


// Deprecating
//
// scatterer rcs based on drop radius in pos.w in meters
//
__kernel void scat_rcs(__global float4 *x,
                       __global float4 *p,
                       __global float4 *a,
                       const float16 sim_desc)
{
    unsigned int i = get_global_id(0);
    //x[i] = (float4)(1.0f, 0.0f, 1.0f, 0.0f);

    float4 pos = p[i];
    
    const float k_0 = sim_desc.s4 * 0.5f;
    const float epsilon_0 = 8.85418782e-12f;
    const float4 epsilon_r_minus_one = (float4)(78.669f, 18.2257f, 78.669f, 18.2257f);
    //
    // Ratio is usually in ( semi-major : semi-minor ) = ( H : V );
    // Use (1.0, 0.0) for H and (v, 0.0) for V
    // v = 1.0048 + 5.7e-4 * D - 2.628e-2 * D ^ 2 + 3.682e-3 * D ^ 3 - 1.667e-4 * D ^ 4
    // Reminder: pos.w = drop radius in m; equation below uses D in mm
    //
    float D = 2000.0f * pos.w;
    float4 DD = pown((float4)D, (int4)(1, 2, 3, 4));
    
    float vv = 1.0048f + dot((float4)(0.0057e-1f, -2.628e-2f, 3.682e-3f, -1.677e-4f), DD);
    
    float rab = 1.0f / vv;
    float fsq = rab * rab - 1.0f;
    float f = sqrt(fsq);
    float lz = (1.0f + fsq) / fsq * (1.0f - atan(f) / f);
    float lx = (1.0f - lz) * 0.5f;
    float vol = M_PI_F * pown(D, 3) / 6.0f;
    //
    // alx = vol * epsilon_0 * (epsilon_r - 1.0f) * (1.0f / (1.0f + lx * (epsilon_r - 1.0f)));
    // alz = vol * epsilon_0 * (epsilon_r - 1.0f) * (1.0f / (1.0f + lz * (epsilon_r - 1.0f)));
    //
    float4 numer = vol * epsilon_0 * epsilon_r_minus_one;
    float4 denom = (float4)(1.0f, 0.0f, 1.0f, 0.0f) + (float4)(lx, lx, lz, lz) * epsilon_r_minus_one;
    float4 alxz = cl_complex_divide(numer, denom);
    //
    // Sc = k_0 ^ 2 / (4 * pi * epsilon_0)
    // Coefficient 1.0e-9 for scaling the volume to unit of m^3
    // Drop concentration scale derived based on ~2,500 drops / m^3
    //
    float sc = 1.0e-9f * sim_desc.s6 * k_0 * k_0 / (4.0f * M_PI_F * epsilon_0);

    x[i] = sc * alxz;
}


//
// scatterer color
//
__kernel void scat_clr(__global float4 *c,
                       __global __read_only float4 *p,
                       __global __read_only float4 *a,
                       __global __read_only float4 *x,
                       const uint4 mode)
{
    unsigned int i = get_global_id(0);
    
    const uint draw_mode = mode.s0;
    
    float m = 0.0f;
    float w = 1.0f;
    
    float4 aux = a[i];
    float4 rcs = x[i];
    
    if (draw_mode == 'S') {
        // DSD bin index
        m = clamp(aux.s2, 0.0f, 1.0f);
    } else if (draw_mode == 'A') {
        // Angular weight (antenna pattern)
        m = aux.s3;
    } else if (draw_mode == 'B') {
        // Angular weight in log scale
        m = clamp(fma(native_log10(100.0f * aux.s3), 0.1f, 0.8f), 0.0f, 1.0f);
    } else if (draw_mode == 'R') {
        // Range weight
        m = clamp((aux.s0 - 2000.0f) * 0.0005f, 0.0f, 1.0f);
        
        float dr = 60.0f;
        float4 range_weight_desc = (float4)(1.0f / dr, 1.0f, 2.0f, 0.0f);
        float range_weight[3] = {0.0f, 1.0f, 0.0f};
        
        float2 dr_from_center = (float2)(aux.s0 - (float)mode.s1);
        const float2 s = (float2)range_weight_desc.s0;
        const float2 o = (float2)range_weight_desc.s1 + (float2)(0.0f, 1.0f);
        
        float2 fidx_raw = clamp(fma(dr_from_center, s, o), 0.0f, range_weight_desc.s2);     // Index [0 ... xm] in float
        float2 fidx_int, fidx_dec = fract(fidx_raw, &fidx_int);                             // The integer and decimal fraction
        uint2 iidx_int = convert_uint2(fidx_int);
        
        // Actual range weight
        m = mix(range_weight[iidx_int.s0], range_weight[iidx_int.s1], fidx_dec.s0);
    } else if (draw_mode == 'H') {
        // Magnitude of HH
        m = clamp(length(rcs.s01) * 20.0f, 0.0f, 1.0f);
    } else if (draw_mode == 'V') {
        // Magnitude of VV
        m = clamp(length(rcs.s23) * 20.0f, 0.0f, 1.0f);
    } else if (draw_mode == 'D') {
        m = clamp(10.0f * native_log10(dot(rcs.s01, rcs.s01) / dot(rcs.s23, rcs.s23)), -3.0f, 3.0f) / 6.0f + 0.5f;
        w = clamp(length(rcs) * 25.0f, 0.0f, 1.0f);
    } else {
        m = 0.5f;
    }
    
    c[i].x = m;
    c[i].w = w;
}

//
// weight and attenuate - angular + range effects
//
__kernel void scat_sig_aux(__global float4 *s,
                           __global float4 *a,
                           __global __read_only float4 *p,
                           __global __read_only float4 *r,
                           __constant float *angular_weight,
                           const float4 angular_weight_desc,
                           const float16 sim_desc)
{
    const unsigned int i = get_global_id(0);

    float4 sig = s[i];
    float4 aux = a[i];
    
    //    RSSimulationDescriptionBeamUnitX     =  0,
    //    RSSimulationDescriptionBeamUnitY     =  1,
    //    RSSimulationDescriptionBeamUnitZ     =  2,
    float angle = acos(dot(sim_desc.s012, normalize(p[i].xyz)));
    
    float2 table_s = (float2)(angular_weight_desc.s0, angular_weight_desc.s0);
    float2 table_o = (float2)(angular_weight_desc.s1, angular_weight_desc.s1) + (float2)(0.0f, 1.0f);
    float2 angle_2 = (float2)(angle, angle);
    
    // scale, offset, clamp to edge
    uint2  iidx_int;
    float2 fidx_int;
    float2 fidx_raw = clamp(fma(angle_2, table_s, table_o), 0.0f, angular_weight_desc.s2);
    float2 fidx_dec = fract(fidx_raw, &fidx_int);
    
    iidx_int = convert_uint2(fidx_int);
    
//    if (i < 32) {
//        float w = angular_weight[i];
//        printf("w[%d] = %.6f = %.2f\n", i, w, 10.0f * log10(w));
//    }
    //
    // Auxiliary info:
    // - s0 = range of the point
    // - s1 = age
    // - s2 = dsd bin index
    // - s3 = angular weight (make_pulse_pass_1)
    //
    aux.s0 = length(p[i].xyz);
    aux.s1 = aux.s1 + sim_desc.sf;
    aux.s3 = mix(angular_weight[iidx_int.s0], angular_weight[iidx_int.s1], fidx_dec.s0);
    
    // Two-way power attenuation = 1.0 / R ^ 4 ==> amplitude attenuation = 1.0 / R ^ 2
    float atten = pown(aux.s0, -2);
    float phase = aux.s0 * sim_desc.s4;
    
    // cosine & sine to represent exp(j phase)
    float cc, ss = sincos(phase, &cc);

    sig = cl_complex_multiply(r[i], (float4)(cc, ss, cc, ss)) * atten;
    
//    if (i == 0) {
//        printf("atten = %.4e  %.4v4e\n", atten, sig);
//    }
    
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
                                __global __read_only float4 *sig,
                                __global __read_only float4 *aux,
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
    
//    float2 wa_ab;
    
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
                                      __global __read_only float4 *in,
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
                                      __global __read_only float4 *in,
                                      __local float4 *shared,
                                      const unsigned int range_count,
                                      const unsigned int n)
{
    unsigned int range_id = get_global_id(0);
    float4 tmp = (float4)(0.0f, 0.0f, 0.0f, 0.0f);
    //	int k = 0;
    for (unsigned int i = range_id; i < n; i += range_count) {
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
                                      __global __read_only float4 *in,
                                      __local float4 *shared,
                                      const unsigned int range_count,
                                      const unsigned int n)
{
    const unsigned int local_id = get_local_id(0);
    const unsigned int local_size = get_local_size(0);
    const unsigned int group_stride = range_count * local_size;
    
    unsigned int i = local_id * range_count;
    
    for (unsigned int k = 0; k < range_count; k++) {
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
__kernel void pop(__global float4 *rcs, __global float4 *aux, __global float4 *pos, const float16 sim_desc)
{
    unsigned int k = get_global_id(0);
    
    float4 p = (float4)((float)(k % 9) - 4.0f, (float)k / 90000.0f + 1.0f, 0.1f, 1.0f);

    rcs[k] = (float4)(1.0f, 0.5f, 1.0f, 0.5f);
    aux[k] = (float4)(length(p.xyz), 1.0f, acos(dot(sim_desc.s012, normalize(p.xyz))), 1.0f);
    pos[k] = p;
}
