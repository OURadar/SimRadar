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

// These enums are for uniform grid
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
    RSStaggeredTableDescriptionBaseChangeX     =  0,
    RSStaggeredTableDescriptionBaseChangeY     =  1,
    RSStaggeredTableDescriptionBaseChangeZ     =  2,
    RSStaggeredTableDescriptionRefreshTime     =  3,
    RSStaggeredTableDescriptionPositionScaleX  =  4,
    RSStaggeredTableDescriptionPositionScaleY  =  5,
    RSStaggeredTableDescriptionPositionScaleZ  =  6,
    RSStaggeredTableDescription7               =  7,
    RSStaggeredTableDescriptionOffsetX         =  8,
    RSStaggeredTableDescriptionOffsetY         =  9,
    RSStaggeredTableDescriptionOffsetZ         = 10,
    RSStaggeredTableDescription11              = 11,
    RSStaggeredTableDescriptionRecipInLnX      = 12,
    RSStaggeredTableDescriptionRecipInLnY      = 13,
    RSStaggeredTableDescriptionRecipInLnZ      = 14,
    RSStaggeredTableDescriptionTachikawa       = 15,
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
float4 complex_multiply(const float4 a, const float4 b);
float4 two_way_effects(const float4 sig_in, const float range, const float wav_num);
float4 wind_table_index(const float4 pos, const float16 wind_desc);

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
    float g = clamp(fma(log10(att.s3), 0.3f, 1.5f), 0.05f, 0.3f);
    
    float4 c;
    
    c.x = clamp(0.4f * att.s1, 0.0f, 1.0f) + 0.6f * g;
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

#define quat_identity  (float4)(0.0f, 0.0f, 0.0f, 1.0f)

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
    float c, s;
    s = sincos(phase, &c);
    
    return complex_multiply(sig_in, (float4)(c, s, c, s)) * atten;
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
// Wind table index
//

float4 wind_table_index(const float4 pos_rel, const float16 wind_desc) {
    // Background wind
    //float4 wind_coord = fma(pos, wind_desc.s0123, wind_desc.s4567);
    
    // Get the "m" & "n" parameters for the reverse lookup z[i] = m * log1p( n * z ); where ScaleZ = m, OriginZ = n
    //    RSTableDescriptionScaleX      =  0,
    //    RSTableDescriptionScaleY      =  1,
    //    RSTableDescriptionScaleZ      =  2,
    //    RSTableDescriptionRefreshTime =  3,
    //    RSTableDescriptionOriginX     =  4,
    //    RSTableDescriptionOriginY     =  5,
    //    RSTableDescriptionOriginZ     =  6,
    //    RSTableDescription7           =  7,
    // wind_coord.z = wind_desc.s2 * log1p(wind_desc.s6 * pos.z);
    
    //    RSStaggeredTableDescriptionBaseChangeX     =  0,
    //    RSStaggeredTableDescriptionBaseChangeY     =  1,
    //    RSStaggeredTableDescriptionBaseChangeZ     =  2,
    //    RSStaggeredTableDescriptionRefreshTime     =  3,
    //    RSStaggeredTableDescriptionPositionScaleX  =  4,
    //    RSStaggeredTableDescriptionPositionScaleY  =  5,
    //    RSStaggeredTableDescriptionPositionScaleZ  =  6,
    //    RSStaggeredTableDescription7               =  7,
    //    RSStaggeredTableDescriptionOffsetX         =  8,
    //    RSStaggeredTableDescriptionOffsetY         =  9,
    //    RSStaggeredTableDescriptionOffsetZ         = 10,
    //return (float4)(copysign(wind_desc.s012, pos.xyz) * log1p(wind_desc.s456 * fabs(pos.xyz)) + wind_desc.s89a, 0.0f);
    return copysign(wind_desc.s0123, pos_rel) * log1p(wind_desc.s4567 * fabs(pos_rel)) + wind_desc.s89ab;
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


// background
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
    int is_outside = any(islessequal(pos.xyz, sim_desc.hi.s012) | isgreaterequal(pos.xyz, sim_desc.hi.s012 + sim_desc.hi.s456));
    
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
    
    // Background wind
    float4 wind_coord = fma(pos, wind_desc.s0123, wind_desc.s4567);
    
    vel = read_imagef(wind_uvw, sampler, wind_coord);
    
    // Range of the point
    aux.s0 = length(pos.xyz);

    aux.s3 = compute_angular_weight(pos, angular_weight, angular_weight_desc, sim_desc);
    
    p[i] = pos;
    v[i] = vel;
    a[i] = aux;
}


// ellipsoid
__kernel void el_atts(__global float4 *p,                  // position (x, y, z) and size (radius)
                      __global float4 *v,                  // velocity (u, v, w) and a vacant float
                      __global float4 *a,                  // auxiliary info: range, ange, ____, angular weight
                      __global float4 *x,                  // signal (hh, hv, vh, vv)
                      __global uint4 *y,                   // 128-bit random seed (4 x 32-bit)
                      __read_only image3d_t wind_uvw,
                      const float16 wind_desc,
                      __constant float *angular_weight,
                      const float4 angular_weight_desc,
                      const float16 sim_desc)
{
    
    const unsigned int i = get_global_id(0);
    
    float4 pos = p[i];  // position
    float4 vel = v[i];  // velocity
    float4 aux = a[i];  // auxiliary
    float4 sig = x[i];  // signal

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
    //    RSSimulationParameterBoundOriginX  =  8,  // hi.s0
    //    RSSimulationParameterBoundOriginY  =  9,  // hi.s1
    //    RSSimulationParameterBoundOriginZ  =  10, // hi.s2
    //    RSSimulationParameterPRT           =  11,
    //    RSSimulationParameterBoundSizeX    =  12, // hi.s4
    //    RSSimulationParameterBoundSizeY    =  13, // hi.s5
    //    RSSimulationParameterBoundSizeZ    =  14, // hi.s6
    //    RSSimulationParameterAgeIncrement  =  15, // PRT / vel_desc.tr
    int is_outside = any(islessequal(pos.xyz, sim_desc.hi.s012) | isgreaterequal(pos.xyz, sim_desc.hi.s012 + sim_desc.hi.s456) | !all(isfinite(pos.xyz)));
    
    if (is_outside) {

        uint4 seed = y[i];
        float4 r = rand(&seed);
        y[i] = seed;
        pos.xyz = (fma(r, sim_desc.hi.s4567, sim_desc.hi.s0123)).xyz;
        vel = (float4)(0.0f, 0.0f, 0.0f, 0.0f);
        //ori = (float4)(0.0f, 0.0f, 0.0f, 1.0f);
        //tum = (float4)(0.0f, 0.0f, 0.0f, 1.0f);

    } else {
    
        float4 pos_rel = pos - (float4)(sim_desc.hi.s01 + 0.5f * sim_desc.hi.s45, 0.0f, 0.0f);
        //float4 wind_coord = copysign(wind_desc.s0123, pos_rel) * log1p(wind_desc.s4567 * fabs(pos_rel)) + wind_desc.s89ab;

        float4 wind_coord = wind_table_index(pos_rel, wind_desc);

        float4 bg_vel = read_imagef(wind_uvw, sampler, wind_coord);

//        if (i == 0) {
//            printf("params = [%.2v4f  ;  %.4v4f  ;  %.2v4f]\n", wind_desc.s0123, wind_desc.s4567, wind_desc.s89ab);
//        }
//        if (i < 10) {
//            printf("pos_rel = [ %8.2v4f ]   coord = [ %8.2v4f ]   bg_vel = [ %8.2v4f ]\n", pos_rel, wind_coord, bg_vel);
//        }
        
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
            if (length(vel) > max(1.0f, 3.0f * length(bg_vel))) {
                //vel = normalize(vel) * length(bg_vel) + (float4)(0.0f, 0.0f, -9.8f, 0.0f) * dt;
                vel = bg_vel + (float4)(0.0f, 0.0f, -9.8f, 0.0f) * dt;
            }

        } else {

            vel += (float4)(0.0f, 0.0f, -9.8f, 0.0f) * dt;

        }

    }
    
    // Range of the point
    aux.s0 = length(pos.xyz);
    //aux.s1 = aux.s1 + sim_desc.sf;
    aux.s3 = compute_angular_weight(pos, angular_weight, angular_weight_desc, sim_desc);
    
    const float wav_num = M_PI_F * 4.0f * native_recip(0.03f);  // 4 * PI / lambda

    // Ratio is usually in ( semi-major : semi-minor ) = ( H : V );
    // Use (1.0, 0.0) for H and (v, 0.0) for V
    // v = 1.0048 + 5.7e-4 * D - 2.628e-2 * D ^ 2 + 3.682e-3 * D ^ 3 - 1.667e-4 * D ^ 4
    // Reminder: pos.w = drop radius in m; equation below uses D in mm
    float D = 2000.0f * pos.w;
    float4 DD = pown((float4)(D, D, D, D), (int4)(1, 2, 3, 4));
    float vv = 1.0048f + dot((float4)(5.7e-4f, -2.628e-2f, 3.682e-3f, -1.667e-4f), DD);

    // Parameterize sig_in as a function of drop size
    sig = two_way_effects((float4)(1.0f, 0.0f, vv, 0.0f), aux.s0, wav_num);

    p[i] = pos;
    v[i] = vel;
    a[i] = aux;
    x[i] = sig;
}


// debris
__kernel void db_atts(__global float4 *p,
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
    
    float4 pos = p[i];  // position
    float4 ori = o[i];  // orientation
    float4 vel = v[i];  // velocity
    float4 tum = t[i];  // tumbling (orientation change)
    float4 aux = a[i];  // auxiliary
    float4 sig = x[i];  // signal
    
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
    //    RSTableDescriptionScaleX      =  0,
    //    RSTableDescriptionScaleY      =  1,
    //    RSTableDescriptionScaleZ      =  2,
    //    RSTableDescriptionRefreshTime =  3,
    //    RSTableDescriptionOriginX     =  4,
    //    RSTableDescriptionOriginY     =  5,
    //    RSTableDescriptionOriginZ     =  6,
    //    RSTableDescription7           =  7,
    //    RSTableDescriptionMaximumX    =  8,
    //    RSTableDescriptionMaximumY    =  9,
    //    RSTableDescriptionMaximumZ    = 10,
    //    RSTableDescription11          = 11,
    //    RSTableDescriptionRecipInLnX  = 12,
    //    RSTableDescriptionRecipInLnY  = 13,
    //    RSTableDescriptionRecipInLnZ  = 14,
    //    RSTableDescriptionTachikawa   = 15,
    //float4 wind_coord = fma(pos, wind_desc.s0123, wind_desc.s4567);
    
    //    RSStaggeredTableDescriptionBaseChangeX     =  0,
    //    RSStaggeredTableDescriptionBaseChangeY     =  1,
    //    RSStaggeredTableDescriptionBaseChangeZ     =  2,
    //    RSStaggeredTableDescriptionRefreshTime     =  3,
    //    RSStaggeredTableDescriptionPositionScaleX  =  4,
    //    RSStaggeredTableDescriptionPositionScaleY  =  5,
    //    RSStaggeredTableDescriptionPositionScaleZ  =  6,
    //    RSStaggeredTableDescription7               =  7,
    //    RSStaggeredTableDescriptionOffsetX         =  8,
    //    RSStaggeredTableDescriptionOffsetY         =  9,
    //    RSStaggeredTableDescriptionOffsetZ         = 10,
    //    RSStaggeredTableDescription11              = 11,
    //    RSStaggeredTableDescriptionRecipInLnX      = 12,
    //    RSStaggeredTableDescriptionRecipInLnY      = 13,
    //    RSStaggeredTableDescriptionRecipInLnZ      = 14,
    //    RSStaggeredTableDescriptionTachikawa       = 15,
   // float4 wind_coord = wind_table_index();
    
    float4 pos_rel = pos - (float4)(sim_desc.hi.s01 + 0.5f * sim_desc.hi.s45, 0.0f, 0.0f);
    
    float4 wind_coord = wind_table_index(pos_rel, wind_desc);
    
    float4 vel_bg = read_imagef(wind_uvw, sampler, wind_coord);
    
    //
    // Update orientation & position ---------------------------------
    //
    float4 ori_next = quat_mult(ori, tum);
    if (all(isfinite(ori_next))) {
        ori = normalize(ori_next);
    }
    
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
    int is_outside = any(islessequal(pos.xyz, sim_desc.hi.s012) | isgreaterequal(pos.xyz, sim_desc.hi.s012 + sim_desc.hi.s456));
    
    if (is_outside) {
        uint4 seed = y[i];
        float4 r = rand(&seed);
        y[i] = seed;
        
        pos.xyz = r.xyz * sim_desc.hi.s456 + sim_desc.hi.s012;
        pos.z = 10.0f;
        
        vel = (float4)(0.0f, 0.0f, 0.0f, 0.0f);
        tum = (float4)(0.0f, 0.0f, 0.0f, 1.0f);
    }

    //
    // derive alpha & beta of ADM for ADM table lookup ---------------------------------
    //
    float alpha, beta, gamma;
    
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
    
    float ur_norm_sq = dot(ur.xyz, ur.xyz);
    
    // Euler method: dudt is just a scaled version of drag coefficient
    float4 dudt = Ta * ur_norm_sq * cd + (float4)(0.0f, 0.0f, -9.8f, 0.0f);
    float4 dw = radians((dt * Ta * ur_norm_sq * inv_inln) * cm);
    
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
    
    // bound the velocity
    if (length(vel.xy + dudt.xy * dt.xy) > length(vel_bg.xy)) {
        vel.xy = vel_bg.xy;
    } else {
        vel += dudt * dt;
    }

    //vel += dudt * dt;
    
//    if (length(vel) > length(vel_bg)) {
//        printf("vel = [%5.2f %5.2f %5.2f %5.2f]  vel_bg = [%5.2f %5.2f %5.2f %5.2f]   %5.2f\n",
//               vel.x, vel.y, vel.z, vel.w,
//               vel_bg.x, vel_bg.y, vel_bg.z, vel_bg.w,
//               ur_norm_sq
//               );
//    }

    //float4 dw = radians((dt * Ta * 0.5f * (ur_norm_sq + ur2_norm_sq) * inv_inln) * cm);
    
    float4 c = cos(dw);
    float4 s = sin(dw);
    tum = (float4)(c.x * s.y * s.z + s.x * c.y * c.z,
                   c.x * s.y * c.z - s.x * c.y * s.z,
                   c.x * c.y * s.z + s.x * s.y * c.z,
                   c.x * c.y * c.z - s.x * s.y * s.z);

    tum = normalize(tum);
    // printf("i=%d  tum = (%.2f %.2f %.2f %.2f)\n", i, tum.x, tum.y, tum.z, tum.w);
    
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
    
    // 3-1-3 conversion:
    alpha = atan2(quat_rel.y * quat_rel.z + quat_rel.w * quat_rel.x , quat_rel.w * quat_rel.y - quat_rel.x * quat_rel.z);
    beta  =  acos(quat_rel.w * quat_rel.w + quat_rel.z * quat_rel.z - quat_rel.y * quat_rel.y - quat_rel.x * quat_rel.x);
    gamma = atan2(quat_rel.y * quat_rel.z - quat_rel.w * quat_rel.x , quat_rel.x * quat_rel.z + quat_rel.w * quat_rel.y);
    
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
    float cg = cos(gamma);
    float sg = sin(gamma);
    
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
    sig.s0 = hh_real;
    sig.s1 = hh_imag;
    sig.s2 = vv_real;
    sig.s3 = vv_imag;
    
    // Auxiliary info:
    // - s0 = range of the point
    // - s1 = age
    // - s2 =
    // - s3 = angular weight
    aux.s0 = length(pos.xyz);
    aux.s1 = aux.s1 + sim_desc.sf;
    aux.s3 = compute_angular_weight(pos, angular_weight, angular_weight_desc, sim_desc);

    const float wav_num = M_PI_F * 4.0f * native_recip(0.03f);  // 4 * PI / lambda

    // Range attenuation and phase adjustment
    sig = two_way_effects(sig, aux.s0, wav_num);
    
    // Copy back to global memory space
    p[i] = pos;
    o[i] = ori;
    v[i] = vel;
    t[i] = tum;
    a[i] = aux;
    x[i] = sig;
}

// generic scatter
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
    
    //c[i] = set_clr(a[i]);
}


__kernel void scat_sig_dsd(__global float4 *x,
                           __global float4 *p,
                           __global float4 *a)
{
    unsigned int i = get_global_id(0);
    x[i] = (float4)(1.0f, 0.0f, 1.0f, 0.0f);
}


__kernel void scat_clr_dsd(__global float4 *c,
                           __global float4 *p,
                           __global float4 *a)
{
    unsigned int i = get_global_id(0);
    
    //c[i].x = clamp(4.8f + log10(0.3f * p[i].w), 0.0f, 1.0f);   // radius to bin index
    c[i].x = clamp(a[i].s2, 0.0f, 1.0f);
    //    if (i < 10)
    //        printf("i=%d  d=%.1fmm  c=%.3f\n", i, p[i].w * 1000.0f, c[i].x);
}


//
// out - output
// sig - signal
// att - attributes
// shared - local memory space __local space (64 kB max)
// weight_table - range weighting function, __constant space (64 kB max)
// table_xs - scale to convert range to table index
// table_x0 - offset to convert range to table index
// table_xm - last table index
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
                                const float table_xs,
                                const float table_x0,
                                const float table_xm,
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
    
    const float4 table_xs_4 = (float4)(table_xs, table_xs, table_xs, table_xs);
    const float4 table_x0_4 = (float4)(table_x0, table_x0, table_x0, table_x0) + (float4)(0.0f, 1.0f, 0.0f, 1.0f);
    const float4 dr = (float4)(range_delta, range_delta, range_delta, range_delta);
    
    float r_a;
    float r_b;
    
    float4 r;
    
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
    
    // att.s0 - range
    
    while (i < n) {
        a = sig[i];
        b = sig[i + local_size];
        r_a = att[i].s0;
        r_b = att[i + local_size].s0;
        r = (float4)(range_start, range_start, range_start, range_start);
        for (k=0; k<range_count; k++) {
            float4 dr_from_center = (float4)(r_a, r_a, r_b, r_b) - r;
            
            fidx_raw = clamp(fma(dr_from_center, table_xs_4, table_x0_4), 0.0f, table_xm);     // Index [0 ... xm] in float
            fidx_dec = fract(fidx_raw, &fidx_int);                                             // The integer and decimal fraction
            iidx_int = convert_uint4(fidx_int);
            
            float2 w2 = mix((float2)(weight_table[iidx_int.s0], weight_table[iidx_int.s2]),
                            (float2)(weight_table[iidx_int.s1], weight_table[iidx_int.s3]),
                            fidx_dec.s02);
            
//            // Range attenuation
//            float2 atten = native_recip((float2)(r_a, r_b));
//            atten *= atten;  // ()^-2
//            atten *= atten;  // ()^-4
//
//            w2 *= atten;
//            
//            // Return phase due to two-way path
//            float2 phase = (float2)(r_a, r_b) * wave_num;
//            float2 cos_phase = cos(phase);
//            float2 sin_phase = sin(phase);
//            
//            a = complex_multiply(a, (float4)(cos_phase.s0, sin_phase.s0, cos_phase.s0, sin_phase.s0));
//            b = complex_multiply(b, (float4)(cos_phase.s1, sin_phase.s1, cos_phase.s1, sin_phase.s1));
            
            w_a = (float4)(w2.s0, w2.s0, w2.s0, w2.s0);
            w_b = (float4)(w2.s1, w2.s1, w2.s1, w2.s1);
            
            shared[local_id + k * local_size] += (w_a * a + w_b * b);
            // printf("%d shared[%d] = %.2f  %.2f\n", group_id, local_id + k, shared[local_id + k].x, wr);
            
            r += dr;
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
