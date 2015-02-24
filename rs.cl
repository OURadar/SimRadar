float4 rand(uint4 *seed);
float4 quat_mult(float4 left,
                 float4 right);
float4 quat_sq(float4 quat);

float4 set_clr(float4 att);

///////////////////////////////////////////////////////////////////////////////////////////
//
// Rudimentary functions
//

float4 rand(uint4 *seed)
{
    const uint4 a = {16807, 16807, 16807, 16807};
    const uint4 m = {0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF};
    const float4 n = {1.0f / 2147483647.0f, 1.0f / 2147483647.0f, 1.0f / 2147483647.0f, 1.0f / 2147483647.0f};
    
    *seed = (*seed * a) & m;
    
    return convert_float4(*seed) * n;
}

///////////////////////////////////////////////////////////////////////////////////////////
//
// Quaternion arithmetics
//

float4 quat_mult(float4 left,
                 float4 right)
{
    return (float4) (left.w * right.x - left.z * right.y + left.y * right.z + left.w * right.w,
                     left.w * right.y + left.z * right.x + left.y * right.w - left.w * right.z,
                     left.w * right.z + left.z * right.w - left.y * right.x + left.y * right.y,
                     left.w * right.w - left.z * right.z - left.y * right.y - left.z * right.x);
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

///////////////////////////////////////////////////////////////////////////////////////////
//
// Functions for convenience
//

// Set colors
float4 set_clr(float4 att)
{
    float g = clamp(fma(log10(att.s3), 0.3f, 1.5f), 0.05f, 0.3f);
    
    float4 c;
    
    c.x = clamp(0.4f * att.s1, 0.0f, 1.0f) + 0.6f * g;
    c.y = 0.9f * g;
    c.z = clamp(1.0f - c.x - 3.5f * g, 0.0f, 1.0f) + 0.2f * (g - 0.1f);
    c.w = 0.3f;
    
    return c;
}

///////////////////////////////////////////////////////////////////////////////////////////

//
// table description:
//
// float4 as:
//   s0 = s - scale
//   s1 = o - offset
//   s2 = m - max index
//   s3 = ? - ignore
//
// Notice SOM? Coincident...
//

///////////////////////////////////////////////////////////////////////////////////////////
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

// Scatterer attributes - assign VEL (from LES or any physical models), ADM and RCS attributes
//
// p - position
// o - orientation
// v - velocity
// a - amplitude (RCS)
//
__kernel void scat_atts(__global float4 *p,
                        __global float4 *o,
                        __global float4 *v,
                        __global float4 *a,
                        __read_only image3d_t physics,
                        const float16 physics_desc,
                        __read_only image2d_t adm_cd,
                        __read_only image2d_t adm_cm,
                        const float16 adm_desc,
                        __read_only image2d_t rcs,
                        const float16 rcs_desc)
{
    unsigned int i = get_global_id(0);

    float4 pos = p[i];
    float4 ori = o[i];
    
    const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;
    float4 coord = fma(pos, physics_desc.s0123, physics_desc.s4567);
    v[i] = read_imagef(physics, sampler, coord);

    // For DEBUG: Override 1-st particle's velocity so it does not move.
    if (i == 0) {
        v[i] = (float4)(10.0f, 0.0f, 0.0f, 0.0f);
    }

    // derive alpha & beta of ADM for ADM table lookup
    float4 v_hat = v[i];
    v_hat = normalize(v_hat);
    
    // xp, yp, zp - x, y, z axis of the particle
    float4 xp = quat_get_x(ori);
    float4 yp = quat_get_y(ori);
    float4 zp = quat_get_z(ori);
    
//    if (i == 0) {
//        printf("v = %.2f %.2f %.2f   xp = %.2f %.2f %.2f   yp = %.2f %.2f %.2f   zp = %.2f %.2f %.2f\n",
//               v_hat.x, v_hat.y, v_hat.z,
//               xp.x, xp.y, xp.z,
//               yp.x, yp.y, yp.z,
//               zp.x, zp.y, zp.z);
//    }
    // derive alpha, beta & gamma of RCS for RCS table lookup
    

}

// Scatterer physics - assign physical parameters based on position
//
// p - position
// v - velocity
//
__kernel void scat_physics(__global float4 *p,
						   __global float4 *v,
						   __read_only image3d_t physics,
						   const float16 physics_desc)
{
	unsigned int i = get_global_id(0);
	
	float4 pos = p[i];
	
	const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;
//	const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;
	float4 coord = fma(pos, physics_desc.s0123, physics_desc.s4567);
	v[i] = read_imagef(physics, sampler, coord);

    // For DEBUG: Override 1-st particle's velocity so it does not move.
    if (i == 0) {
        v[i] = (float4)(0.0f, 0.0f, 0.0f, 0.0f);
    }

//	if (i == 0) {
//		printf("(%9.2f, %9.2f, %9.2f) / [%.2f, %.2f, %.2f] + [%.2f, %.2f, %.2f] = (%.2f, %.2f, %.2f)  (%6.2f, %6.2f, %6.2f)\n",
//			   pos.x, pos.y, pos.z,
//			   1.0f / physics_desc.s0, 1.0f / physics_desc.s1, 1.0f / physics_desc.s2,
//			   physics_desc.s4, physics_desc.s5, physics_desc.s6,
//			   coord.x, coord.y, coord.z,
//			   v[i].x, v[i].y, v[i].z);
//	}
}

//
// float8
//   s0 - scale-x
//   s1 - scale-y
//   s2 - scale-z
//   s3 -
//   s4 - offset-x
//   s5 - offset-y
//   s6 - offset-z
//   s7
//

// Scatterer move
//
// p - position
// v - velocity
// o - orientation
// a - attributes
// angular_weight      - beam weighting function
// angular_weight_desc - description of the indexing of angular_weight
// b - beam pointing vector (normalized)
// t - time constantss (prt, life delta, ___, ___)
//
__kernel void scat_mov(__global float4 *p,
					   __global float4 *v,
					   __global float4 *o,
					   __global float4 *a,
					   __constant float *angular_weight,
					   const float4 angular_weight_desc,
					   const float4 b,
					   const float4 t)
{
	unsigned int i = get_global_id(0);

	// Use registers since these will be used more than once
	const float4 dt = (float4)(t.s0, t.s0, t.s0, 0.0f);
	float4 pos = p[i];

    float dprod = dot(b.xyz, normalize(pos.xyz));
	float angle = acos(dprod);
	
	a[i].s0 = length(pos);                                 // Range of the point
//	if (i < 10)
//		printf("s1=%9.4f  (t=%9.4f  i=%d)\n", a[i].s1, t, i);
	a[i].s1 += t.s1;

	const float2 table_s = (float2)(angular_weight_desc.s0, angular_weight_desc.s0);
	const float2 table_o = (float2)(angular_weight_desc.s1, angular_weight_desc.s1) + (float2)(0.0f, 1.0f);
	const float2 angle_2 = (float2)(angle, angle);

	float2 fidx_raw;
	float2 fidx_dec;
	float2 fidx_int;
	uint2  iidx_int;
	
	fidx_raw = clamp(fma(angle_2, table_s, table_o), 0.0f, angular_weight_desc.s2);  // clamp to edge
	fidx_dec = fract(fidx_raw, &fidx_int);
	iidx_int = convert_uint2(fidx_int);
	a[i].s3 = mix(angular_weight[iidx_int.s0], angular_weight[iidx_int.s1], fidx_dec.s0);

//	const float4 ages = (float4)(a[i].s1, a[i].s1, a[i].s1, 0.0f);
//	const float4 offsets = (float4)(0.125f, 0.375f, 0.625f, 0.0f);
//	const float4 a_max = (float4)(M_PI_2_F, M_PI_2_F, 1.4f * M_PI_2_F, 0.0f) * 8.0f;

//	float4 lo = o[i];
//	
//	lo = clamp(ages - offsets, 0.0f, 0.125f);
////	if (i == 9) {
////		printf("i=%3d   %6.4f  o = [ %6.3f, %6.3f, %6.3f ]\n",
////			   i, a[i].s1, lo.x, lo.y, lo.z);
////	}
//	lo *= a_max;
//
//	o[i] = lo;

	
    // Future position
    pos += v[i] * dt;
    p[i] = pos;
    
//	if (i < 3) {
//		printf("i=%3d  angle=%6.3f --> %6.3f, %6.3f, %6.3f --> w=%6.3f\n",
//			   i, angle, fidx_int.s0, fidx_int.s1, fidx_dec.s0, a[i].s3);
//	}

}


//
// p - position
// a - attributes
// s - seed for random number generator
// box - enclosing box - xmin, ymin, zmin, ____, xlen, ylen, zlen, ____
//
__kernel void scat_chk(__global float4 *p,
					   __global float4 *a,
					   __global uint4 *s,
					   const float8 box
					   )
{
	unsigned int i = get_global_id(0);
    
	float4 pos = p[i];

	// Check for bounding constraints
	//if (any(isless(pos, box.s0123) | isgreater(pos, box.s0123 + box.s4567))) {
	//if (any(isless(pos.xyz, box.s012) | isgreater(pos.xyz, box.s012 + box.s456))) {
	if (any(isless(pos.xyz, box.s012) | isgreater(pos.xyz, box.s012 + box.s456)) | isgreater(a[i].s1, 1.0f)) {
	//if (isgreater(a[i].s1, 1.0f)) {
        if (i > 0) {
            uint4 seed = s[i];
            float4 r = rand(&seed);
            s[i] = seed;

            p[i].xyz = r.xyz * box.s456 + box.s012;
        }
        a[i].s1 = 0.0f;
	}
}


//
// c - color
// p - position
// v - velocity
// o - orientation
// a - attributes
//
__kernel void scat_clr(__global float4 *c,
					   __global float4 *p,
					   __global float4 *v,
					   __global float4 *o,
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
