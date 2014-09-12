__kernel void ramp(__global float4 *array)
{
	unsigned int k = get_global_id(0);
	
	float v = (float)(k % 32);
	array[k] = float4(v, v, v, v);
}

__kernel void reduce(__global float4 *in, __global float4 *out, __local float4 *shared, const unsigned int group_size, const unsigned int n)
{
	// This kernel takes two groups of work item at a time.
	// Each work item pairs are summed and stored in local memory.
	// Then, move to the next group of group-pairs, i.e., local_stride = work_items * groups
	
	const float4 zero = {0.0f, 0.0f, 0.0f, 0.0f};
	const unsigned int group_id = get_global_id(0) / get_local_size(0);
	const unsigned int group_stride = 2 * group_size;
	const size_t local_stride = group_stride * group_size;

	const size_t local_id = get_local_id(0);

	shared[local_id] = zero;
	
	size_t i = group_id * group_stride + local_id;

	while (i < n) {
		float4 a = in[i];
		float4 b = in[i + group_size];
		shared[local_id] += a + b;
		i += local_stride;
	}
	barrier(CLK_LOCAL_MEM_FENCE);
	
	/*
	if (group_size >= 512 && local_id < 256)
	{
		shared[local_id] += shared[local_id + 256];
	}
	barrier(CLK_LOCAL_MEM_FENCE);
	
	if (group_size >= 256 && local_id < 128)
	{
		shared[local_id] += shared[local_id + 128];
	}
	barrier(CLK_LOCAL_MEM_FENCE);

	if (group_size >= 128 && local_id < 64)
	{
		shared[local_id] += shared[local_id + 64];
	}
	barrier(CLK_LOCAL_MEM_FENCE);
	 */

	if (group_size >= 64 && local_id < 32)
	{
		shared[local_id] += shared[local_id + 32];
	}
	barrier(CLK_LOCAL_MEM_FENCE);

	if (group_size >= 32 && local_id < 16)
	{
		shared[local_id] += shared[local_id + 16];
	}
	barrier(CLK_LOCAL_MEM_FENCE);

	if (group_size >= 16 && local_id < 8)
	{
		shared[local_id] += shared[local_id + 8];
	}
	barrier(CLK_LOCAL_MEM_FENCE);

	if (group_size >= 8 && local_id < 4)
	{
		shared[local_id] += shared[local_id + 4];
	}
	barrier(CLK_LOCAL_MEM_FENCE);

	if (group_size >= 4 && local_id < 2)
	{
		shared[local_id] += shared[local_id + 2];
	}
	barrier(CLK_LOCAL_MEM_FENCE);

	if (group_size >= 2 && local_id < 1)
	{
		shared[local_id] += shared[local_id + 1];
	}
	barrier(CLK_LOCAL_MEM_FENCE);

	if (local_id == 0)
	{
		out[group_id] = shared[0];
	}
}
