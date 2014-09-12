/*
 *
 * Test a reduction kernel
 *
 */

#include <errno.h>
#include "rs.h"

#define NUM_ELEM  (2 * 1024 * 1024)
//#define NUM_ELEM  (64)


int main(int argc, char **argv)
{
	struct timeval t1, t2;
	
	cl_uint num_devices;
	cl_device_id devices[4];
	cl_uint num_cus[4];
	
	get_device_info(&num_devices, devices, num_cus, 3);
	
	cl_int ret;
	cl_context context;
	cl_program program;
	cl_mem input;
	cl_mem psums_1;
	cl_mem psums_2;
	cl_kernel kernel_ramp, kernel_reduce;
	cl_command_queue queue[4];
	cl_event event;
	
	size_t ret_size = 0;
	size_t max_workgroup_size = 0;
	ret = clGetDeviceInfo(devices[0], CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(size_t), &max_workgroup_size, &ret_size);
	if (ret != CL_SUCCESS) {
		fprintf(stderr, "%s : Unable to obtain CL_DEVICE_MAX_WORK_GROUP_SIZE.\n", now());
		exit(EXIT_FAILURE);
	}
	
	// OpenCL context
	context = clCreateContext(NULL, num_devices, devices, &pfn_notify, NULL, &ret);
	if (ret != CL_SUCCESS) {
		fprintf(stderr, "%s : Error creating OpenCL context.  ret = %d\n", now(), ret);
		exit(EXIT_FAILURE);
	}
	
	char *src_ptr[RS_MAX_KERNEL_LINES];
	cl_uint len = read_kernel_source_from_files(src_ptr, "reduce.cl", NULL);
	
	// Program
	program = clCreateProgramWithSource(context, len, (const char **)src_ptr, NULL, &ret);
	if (clBuildProgram(program, 1, devices, "", NULL, NULL) != CL_SUCCESS) {
		char char_buf[RS_MAX_STR];
		clGetProgramBuildInfo(program, devices[0], CL_PROGRAM_BUILD_LOG, RS_MAX_STR, char_buf, NULL);
		fprintf(stderr, "CL Compilation failed:\n%s", char_buf);
		exit(EXIT_FAILURE);
	}
	
	input = clCreateBuffer(context, CL_MEM_READ_ONLY, NUM_ELEM * sizeof(cl_float4), NULL, &ret);
	psums_1 = clCreateBuffer(context, CL_MEM_READ_WRITE, NUM_ELEM * sizeof(cl_float4), NULL, &ret);
	psums_2 = clCreateBuffer(context, CL_MEM_READ_WRITE, NUM_ELEM * sizeof(cl_float4), NULL, &ret);

	kernel_ramp = clCreateKernel(program, "ramp", &ret);
	if (ret != CL_SUCCESS) {
		fprintf(stderr, "Error\n");
		exit(EXIT_FAILURE);
	}
	clSetKernelArg(kernel_ramp, 0, sizeof(input), &input);
	
	
	kernel_reduce = clCreateKernel(program, "reduce", &ret);

	size_t global_work_size;
	size_t work_group_size;

	ret = clGetKernelWorkGroupInfo(kernel_reduce, devices[0], CL_KERNEL_WORK_GROUP_SIZE, sizeof(size_t), &work_group_size, NULL);
	printf("%s : CL_KERNEL_WORK_GROUP_SIZE = %zu\n", now(), work_group_size);

	for (int i=0; i<num_devices; i++) {
		queue[i] = clCreateCommandQueue(context, devices[i], 0, &ret);
		if (ret != CL_SUCCESS) {
			fprintf(stderr, "Error creating queue.\n");
			exit(EXIT_FAILURE);
		}
	}
	
	gettimeofday(&t1, NULL);
	
	
	global_work_size = NUM_ELEM;
	clEnqueueNDRangeKernel(queue[0], kernel_ramp, 1, NULL, &global_work_size, NULL, 0, NULL, &event);
	clWaitForEvents(1, &event);
	clReleaseEvent(event);

	cl_float4 *host_mem = (cl_float4 *)malloc(NUM_ELEM * sizeof(cl_float4));

	clEnqueueReadBuffer(queue[0], input, CL_TRUE, 0, NUM_ELEM * sizeof(cl_float4), host_mem, 0, NULL, NULL);
	BOOL all_same = TRUE;
	for (int i=0; i<NUM_ELEM; i++) {
		all_same &= (host_mem[i].s0 == (float)(i % 32));
	}
	printf("All numbers are as expected: %s\n\n", all_same ? "YES" : "NO");
	
	if (!all_same) {
		printf("Input:\n");
		for (int i=0; i<1000; i++) {
			cl_float4 v;
			clEnqueueReadBuffer(queue[0], input, CL_TRUE, i * sizeof(cl_float4), sizeof(cl_float4), &v, 0, NULL, NULL);
			printf("%7d :  %9.1f  %9.1f  %9.1f  %9.1f\n", i, v.x, v.y, v.z, v.w);
		}
		for (int i=NUM_ELEM-3; i<NUM_ELEM; i++) {
			cl_float4 v;
			clEnqueueReadBuffer(queue[0], input, CL_TRUE, i * sizeof(cl_float4), sizeof(cl_float4), &v, 0, NULL, NULL);
			printf("%7d :  %9.1f  %9.1f  %9.1f  %9.1f\n", i, v.x, v.y, v.z, v.w);
		}
		printf("\n");
	}
	

	ReductionParams *R = make_reduction_params(NUM_ELEM, 64, 64);
	
	int err;
		
	// printf("in/out @ %p %p\n", input, psums_2);
	
	for (int i=0; i<R->pass_counts; i++) {

		size_t global = R->group_counts[i] * R->work_item_counts[i];
		size_t local = R->work_item_counts[i];

		printf("Pass %d   global %4d   local/work_items=%3d   groups=%3d   entries=%7d\n",
			   i,
			   (int)global,
			   (int)local,
			   R->group_counts[i],
			   R->entry_counts[i]);
		
		err = CL_SUCCESS;
		if (i == 0) {
			err |= clSetKernelArg(kernel_reduce, 0, sizeof(cl_mem), &input);
			err |= clSetKernelArg(kernel_reduce, 1, sizeof(cl_mem), &psums_1);
		} else if (i % 2 == 0) {
			err |= clSetKernelArg(kernel_reduce, 0, sizeof(cl_mem), &psums_2);
			err |= clSetKernelArg(kernel_reduce, 1, sizeof(cl_mem), &psums_1);
		} else {
			err |= clSetKernelArg(kernel_reduce, 0, sizeof(cl_mem), &psums_1);
			err |= clSetKernelArg(kernel_reduce, 1, sizeof(cl_mem), &psums_2);
		}
		err |= clSetKernelArg(kernel_reduce, 2, R->work_item_counts[i] * sizeof(cl_float4), NULL);
		err |= clSetKernelArg(kernel_reduce, 3, sizeof(unsigned int), &R->work_item_counts[i]);
		err |= clSetKernelArg(kernel_reduce, 4, sizeof(unsigned int), &R->entry_counts[i]);
		if (err != CL_SUCCESS) {
			fprintf(stderr, "Error: Failed to set kernel arguments.\n");
			exit(EXIT_FAILURE);
		}
		
		err = clEnqueueNDRangeKernel(queue[0], kernel_reduce, 1, NULL, &global, &local, 0, NULL, NULL);
		if (err != CL_SUCCESS) {
			fprintf(stderr, "Error: Failed in clEnqueueNDRangeKernel().\n");
			exit(EXIT_FAILURE);
		}
	}
	
	clFinish(queue[0]);

	gettimeofday(&t2, NULL);

	if (R->pass_counts % 2 == 1) {
		clEnqueueReadBuffer(queue[0], psums_1, CL_TRUE, 0, 1 * sizeof(cl_float4), host_mem, 0, NULL, NULL);
	} else {
		clEnqueueReadBuffer(queue[0], psums_2, CL_TRUE, 0, 1 * sizeof(cl_float4), host_mem, 0, NULL, NULL);
	}
	
	printf("Output = %.1f\n", host_mem[0].s0);

//	printf("Output:\n");
//	{
//		int i = 0;
//		printf("%7d :  %9.1f  %9.1f  %9.1f  %9.1f\n", i, host_mem[i].x, host_mem[i].y, host_mem[i].z, host_mem[i].w);
//	}
//	printf("\n");
//	
//	for (int i=0; i<4; i++) {
//		printf("%7d :  %9.1f  %9.1f  %9.1f  %9.1f\n", i, host_mem[i].x, host_mem[i].y, host_mem[i].z, host_mem[i].w);
//	}

//	for (int i=NUM_ELEM/2-3; i<NUM_ELEM/2; i++) {
//		printf("%7d :  %9.1f  %9.1f  %9.1f  %9.1f\n", i, host_mem[i].x, host_mem[i].y, host_mem[i].z, host_mem[i].w);
//	}
//	printf("\n");
//	for (int i=NUM_ELEM-3; i<NUM_ELEM; i++) {
//		printf("%7d :  %9.1f  %9.1f  %9.1f  %9.1f\n", i, host_mem[i].x, host_mem[i].y, host_mem[i].z, host_mem[i].w);
//	}
//	printf("\n");
	
	free_reduction_params(R);
	
	
	for (int i=0; i<num_devices; i++) {
		clReleaseCommandQueue(queue[i]);
	}
	
	free(host_mem);
	
	clReleaseKernel(kernel_ramp);
	clReleaseKernel(kernel_reduce);
	clReleaseMemObject(input);
	clReleaseMemObject(psums_2);
	clReleaseProgram(program);
	clReleaseContext(context);
	
	return 0;
}
