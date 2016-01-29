/*
 *
 * Test a reduction kernel
 *
 */

#include <errno.h>
#include "rs.h"
#include "rs_priv.h"

#define NUM_ELEM      (1079196)
//#define NUM_ELEM      (102400)
//#define NUM_ELEM      (64)
#define RANGE_GATES   (9)
#define GROUP_ITEMS   (64)
#define GROUP_COUNTS  (64)

enum {
	TEST_N0NE         = 0,
	TEST_CPU          = 1,
	TEST_GPU_PASS_1   = 1 << 1,
	TEST_GPU_PASS_2   = 1 << 2,
    TEST_GPU_DB_ATTS  = 1 << 3,
    TEST_GPU_WA       = 1 << 4,
	TEST_GPU          = TEST_GPU_PASS_1 | TEST_GPU_PASS_2 | TEST_GPU_DB_ATTS | TEST_GPU_WA,
	TEST_ALL          = TEST_CPU | TEST_GPU
};

cl_float4 complex_multiply(const cl_float4 a, const cl_float4 b) {
    return (cl_float4){{
        a.s0 * b.s0 - a.s1 * b.s1,
        a.s1 * b.s0 + a.s0 * b.s1,
        a.s2 * b.s2 - a.s3 * b.s3,
        a.s3 * b.s2 + a.s2 * b.s3
    }};
}

cl_float4 two_way_effects(const cl_float4 sig_in, const float range, const float wav_num) {
    float atten = powf(range, -4.0f);
    float phase = range * wav_num;
    float c = cosf(phase), s = sinf(phase);
    cl_float4 tmp = complex_multiply(sig_in, (cl_float4){{c, s, c, s}});
    tmp.s0 *= atten;
    tmp.s1 *= atten;
    tmp.s2 *= atten;
    tmp.s3 *= atten;
    return tmp;
}

float deg2rad(const float deg) {
    return deg * 0.01745329251994f;
}

int main(int argc, char **argv)
{
	char c;
	char verb = 0;
	char test = TEST_N0NE;
	const cl_float4 zero = {{0.0f, 0.0f, 0.0f, 0.0f}};

	unsigned int speed_test_iterations = 0;
	
	struct timeval t1, t2;
	
	cl_float4 *host_rcs;
    cl_float4 *host_pos;
	cl_float4 *host_aux;
	cl_float4 *cpu_pulse;
	
    cl_uint num_devices;
    cl_device_id devices[4];
    cl_uint vendors[4];
    cl_uint num_cus[4];
    
	int err;
	cl_int ret;
	cl_context context;
	cl_program program;
	
    cl_mem sig;
    cl_mem pos;
    cl_mem ori;
    cl_mem vel;
    cl_mem tum;
	cl_mem aux;
    cl_mem rcs;
    cl_mem rnd;
	cl_mem work;
	cl_mem pulse;
    
    cl_float16 sim_desc;
    
	cl_mem range_weight;
    cl_float4 range_weight_desc;
    
    cl_mem angular_weight;
    cl_float4 angular_weight_desc;
    
    cl_mem les;
    cl_float16 les_desc;
    
    cl_mem adm_cd;
    cl_mem adm_cm;
    cl_float16 adm_desc;
    
    cl_mem rcs_real;
    cl_mem rcs_imag;
    cl_float16 rcs_desc;
	
    cl_kernel kernel_pop;
    cl_kernel kernel_scat_wa;
    cl_kernel kernel_db_atts;
	cl_kernel kernel_make_pulse_pass_1;
	cl_kernel kernel_make_pulse_pass_2;
	cl_command_queue queue;
	
	size_t global_size = 0;
	size_t max_workgroup_size = 0;
	
    cl_event events[3];
    
    unsigned int num_elem = NUM_ELEM;

	while ((c = getopt(argc, argv, "ac12dwgvn:p:h?")) != -1) {
		switch (c) {
			case 'a':
				test = TEST_ALL;
				break;
			case '1':
				test |= TEST_GPU_PASS_1;
				break;
			case '2':
				test |= TEST_GPU_PASS_2;
				break;
            case 'd':
                test |= TEST_GPU_DB_ATTS;
                break;
            case 'w':
                test |= TEST_GPU_WA;
                break;
			case 'g':
				test |= TEST_GPU;
				break;
			case 'c':
				test |= TEST_CPU;
				break;
			case 'v':
				verb++;
				break;
			case 'n':
				speed_test_iterations = atoi(optarg);
				break;
			case'p':
				num_elem = atoi(optarg);
				break;
			case 'h':
			case '?':
				printf("%s\n\n"
					   "%s [OPTIONS]\n\n"
					   "    -a     All CPU & GPU tests\n"
					   "    -c     CPU test\n"
					   "    -1     GPU test: make_pulse_pass_1\n"
					   "    -2     GPU test: make_pulse_pass_2\n"
                       "    -d     GPU test: scat_db_atts\n"
                       "    -w     GPU test: scat_wa\n"
					   "    -g     All GPU Tests\n"
					   "    -v     increases verbosity\n"
					   "    -n N   speed test using N iterations\n"
					   "\n",
					   argv[0], argv[0]);
				return EXIT_FAILURE;
			default:
				fprintf (stderr, "Unknown option character `\\x%x'.\n", optopt);
				break;
		}
	}
	
    // Some basic simulation parameters
    sim_desc.s[RSSimulationDescriptionBeamUnitX] = 0.0f;
    sim_desc.s[RSSimulationDescriptionBeamUnitY] = 1.0f;
    sim_desc.s[RSSimulationDescriptionBeamUnitZ] = 0.0f;
    sim_desc.s[RSSimulationDescriptionWaveNumber] = 4.0f * M_PI / 0.1f;

    if (test & TEST_ALL && speed_test_iterations == 0) {
		speed_test_iterations = 500;
	}
	
	// Check for some info
    get_device_info(CL_DEVICE_TYPE_GPU, &num_devices, devices, num_cus, vendors, verb);
    
	// Get the OpenCL devices
	ret = clGetDeviceInfo(devices[0], CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(size_t), &max_workgroup_size, &global_size);
	if (ret != CL_SUCCESS) {
		fprintf(stderr, "%s : Unable to obtain CL_DEVICE_MAX_WORK_GROUP_SIZE.\n", now());
		exit(EXIT_FAILURE);
	}
	
	// OpenCL context. Use the 1st device
	context = clCreateContext(NULL, 1, devices, &pfn_notify, NULL, &ret);
	if (ret != CL_SUCCESS) {
		fprintf(stderr, "%s : Error creating OpenCL context.  ret = %d\n", now(), ret);
		exit(EXIT_FAILURE);
	}
	
	char *src_ptr[RS_MAX_KERNEL_LINES];
	cl_uint len = read_kernel_source_from_files(src_ptr, "rs.cl", NULL);
	
	// Program
	program = clCreateProgramWithSource(context, len, (const char **)src_ptr, NULL, &ret);
	if (clBuildProgram(program, 1, devices, "", NULL, NULL) != CL_SUCCESS) {
		char char_buf[RS_MAX_STR];
		clGetProgramBuildInfo(program, devices[0], CL_PROGRAM_BUILD_LOG, RS_MAX_STR, char_buf, NULL);
		fprintf(stderr, "CL Compilation failed:\n%s", char_buf);
		exit(EXIT_FAILURE);
	}
	
	cl_ulong buf_ulong;
	clGetDeviceInfo(devices[0], CL_DEVICE_MAX_CONSTANT_BUFFER_SIZE, sizeof(cl_ulong), &buf_ulong, NULL);
	if (RANGE_GATES * GROUP_ITEMS * sizeof(cl_float4) > buf_ulong) {
		fprintf(stderr, "Local memory size exceeded.  %d > %d\n",
				(int)(RANGE_GATES * GROUP_ITEMS * sizeof(cl_float4)),
				(int)buf_ulong);
		exit(EXIT_FAILURE);
	}

	// Command queue
    queue = clCreateCommandQueue(context, devices[0], 0, &ret);
    if (ret != CL_SUCCESS) {
        fprintf(stderr, "Error creating queue.\n");
        exit(EXIT_FAILURE);
    }
    
    // Round up to the next 2x group size multiples as make_pulse_pass_1 sum by 2x group size
    unsigned int nice_num_elem = (unsigned int)ceilf((float)num_elem / GROUP_ITEMS / 2) * GROUP_ITEMS * 2;
    if (num_elem != nice_num_elem) {
        fprintf(stderr, "Number of elements revised: %d -> %d\n", num_elem, nice_num_elem);
        num_elem = nice_num_elem;
    } else {
        printf("Number of points = %d\n", num_elem);
    }

    global_size = num_elem;

	// CPU memory
	host_rcs = (cl_float4 *)malloc(MAX(num_elem, RANGE_GATES * GROUP_ITEMS) * sizeof(cl_float4));
    host_pos = (cl_float4 *)malloc(MAX(num_elem, RANGE_GATES * GROUP_ITEMS) * sizeof(cl_float4));
	host_aux = (cl_float4 *)malloc(MAX(num_elem, RANGE_GATES * GROUP_ITEMS) * sizeof(cl_float4));
	cpu_pulse = (cl_float4 *)malloc(RANGE_GATES * sizeof(cl_float4));

    // Range weight table parameters
    float range_weight_cpu[] = {0.0f, 1.0f, 0.0f};
    float table_range_start = -25.0f, table_range_delta = 25.0f;
    const float xs = 1.0f / table_range_delta;
    const float xo = -table_range_start * xs;
    const float xm = (float)(sizeof(range_weight_cpu) / sizeof(float)) - 1.0;
    range_weight_desc = (cl_float4){{xs, xo, xm, 0.0f}};
    printf("Range weight:  dx = %.2f  x0 = %.2f  xm = %.1f\n", xs, xo, xm);
    
    // Angular weight table parameters
    float angular_weight_cpu[] = {0.0f, 0.7f, 1.0f, 0.7f, 0.0f};
    angular_weight_desc = (cl_float4){{1.0f / deg2rad(10.0f), -(deg2rad(-20.0f)) * 1.0f / deg2rad(10.0f), 4.0f}};
    printf("Angular weight:  dx = %.2f  x0 = %.2f  xm = %.1f\n", angular_weight_desc.s0, angular_weight_desc.s1, angular_weight_desc.s2);
	
	// GPU memory
	sig = clCreateBuffer(context, CL_MEM_READ_WRITE, num_elem * sizeof(cl_float4), NULL, &ret);
    pos = clCreateBuffer(context, CL_MEM_READ_WRITE, num_elem * sizeof(cl_float4), NULL, &ret);
    ori = clCreateBuffer(context, CL_MEM_READ_WRITE, num_elem * sizeof(cl_float4), NULL, &ret);
    vel = clCreateBuffer(context, CL_MEM_READ_WRITE, num_elem * sizeof(cl_float4), NULL, &ret);
    tum = clCreateBuffer(context, CL_MEM_READ_WRITE, num_elem * sizeof(cl_float4), NULL, &ret);
	aux = clCreateBuffer(context, CL_MEM_READ_WRITE, num_elem * sizeof(cl_float4), NULL, &ret);
    rcs = clCreateBuffer(context, CL_MEM_READ_WRITE, num_elem * sizeof(cl_float4), NULL, &ret);
    rnd = clCreateBuffer(context, CL_MEM_READ_WRITE, num_elem * sizeof(cl_uint4), NULL, &ret);
	work = clCreateBuffer(context, CL_MEM_READ_WRITE, RANGE_GATES * GROUP_ITEMS * sizeof(cl_float4), NULL, &ret);
	pulse = clCreateBuffer(context, CL_MEM_READ_WRITE, RANGE_GATES * sizeof(cl_float4), NULL, &ret);
	range_weight = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, sizeof(range_weight_cpu), range_weight_cpu, &ret);
    angular_weight = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, sizeof(angular_weight_cpu), angular_weight_cpu, &ret);

    cl_float4 *table = (cl_float4 *)malloc(3 * 4 * 5 * sizeof(cl_float4));
    
#if defined (CL_VERSION_1_2)
    
    cl_image_desc desc;
    desc.image_type = CL_MEM_OBJECT_IMAGE3D;
    desc.image_width  = 3;
    desc.image_height = 4;
    desc.image_depth  = 5;
    desc.image_array_size = 0;
    desc.image_row_pitch = desc.image_width * sizeof(cl_float4);
    desc.image_slice_pitch = desc.image_height * desc.image_row_pitch;
    desc.num_mip_levels = 0;
    desc.num_samples = 0;
    desc.buffer = NULL;
    
    cl_mem_flags flags = CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR;
    cl_image_format format = {CL_RGBA, CL_FLOAT};
    
    les = clCreateImage(context, flags, &format, &desc, table, &ret);
    adm_cd = clCreateImage(context, flags, &format, &desc, table, &ret);
    adm_cm = clCreateImage(context, flags, &format, &desc, table, &ret);
    rcs_real = clCreateImage(context, flags, &format, &desc, table, &ret);
    rcs_imag = clCreateImage(context, flags, &format, &desc, table, &ret);
    
#else
    
    les = clCreateImage3D(H->worker[i].context, flags, &format, 3, 4, 5, 3 * sizeof(cl_float4), 4 * 3 * sizeof(cl_float4), table, &ret);
    adm_cd = clCreateImage3D(H->worker[i].context, flags, &format, 3, 4, 5, 3 * sizeof(cl_float4), 4 * 3 * sizeof(cl_float4), table, &ret);
    adm_cm = clCreateImage3D(H->worker[i].context, flags, &format, 3, 4, 5, 3 * sizeof(cl_float4), 4 * 3 * sizeof(cl_float4), table, &ret);
    rcs_real = clCreateImage3D(H->worker[i].context, flags, &format, 3, 4, 5, 3 * sizeof(cl_float4), 4 * 3 * sizeof(cl_float4), table, &ret);
    rcs_imag = clCreateImage3D(H->worker[i].context, flags, &format, 3, 4, 5, 3 * sizeof(cl_float4), 4 * 3 * sizeof(cl_float4), table, &ret);
    
#endif
    
    les_desc.s[RSTable3DDescriptionScaleX] = 1.0f;
    les_desc.s[RSTable3DDescriptionScaleY] = 1.0f;
    les_desc.s[RSTable3DDescriptionScaleZ] = 1.0f;
    les_desc.s[RSTable3DDescriptionOriginX] = 0.0f;
    les_desc.s[RSTable3DDescriptionOriginY] = 0.0f;
    les_desc.s[RSTable3DDescriptionOriginZ] = 0.0f;
    les_desc.s[RSTable3DDescriptionMaximumX] = 2.0f;
    les_desc.s[RSTable3DDescriptionMaximumY] = 3.0f;
    les_desc.s[RSTable3DDescriptionMaximumZ] = 4.0f;
    les_desc.s[RSTable3DDescriptionRefreshTime] = 1.0f;
    
    rcs_desc.s[RSTable3DDescriptionScaleX] = 1.0f;
    rcs_desc.s[RSTable3DDescriptionScaleY] = 1.0f;
    rcs_desc.s[RSTable3DDescriptionScaleZ] = 1.0f;
    rcs_desc.s[RSTable3DDescriptionOriginX] = 0.0f;
    rcs_desc.s[RSTable3DDescriptionOriginY] = 0.0f;
    rcs_desc.s[RSTable3DDescriptionOriginZ] = 0.0f;
    rcs_desc.s[RSTable3DDescriptionMaximumX] = 2.0f;
    rcs_desc.s[RSTable3DDescriptionMaximumY] = 3.0f;
    rcs_desc.s[RSTable3DDescriptionMaximumZ] = 4.0f;
    
    adm_desc.s[RSTable3DDescriptionScaleX] = 1.0f;
    adm_desc.s[RSTable3DDescriptionScaleY] = 1.0f;
    adm_desc.s[RSTable3DDescriptionScaleZ] = 1.0f;
    adm_desc.s[RSTable3DDescriptionOriginX] = 0.0f;
    adm_desc.s[RSTable3DDescriptionOriginY] = 0.0f;
    adm_desc.s[RSTable3DDescriptionOriginZ] = 0.0f;
    adm_desc.s[RSTable3DDescriptionMaximumX] = 2.0f;
    adm_desc.s[RSTable3DDescriptionMaximumY] = 3.0f;
    adm_desc.s[RSTable3DDescriptionMaximumZ] = 4.0f;
    
    sim_desc.s[RSSimulationDescriptionBeamUnitX] = 0.0f;
    sim_desc.s[RSSimulationDescriptionBeamUnitY] = 1.0f;
    sim_desc.s[RSSimulationDescriptionBeamUnitZ] = 0.0f;
    sim_desc.s[RSSimulationDescriptionTotalParticles] = num_elem;
    sim_desc.s[RSSimulationDescriptionWaveNumber] = 4.0f * M_PI / 0.1f;
    sim_desc.s[RSSimulationDescriptionBoundOriginX] = -1000.0f;
    sim_desc.s[RSSimulationDescriptionBoundOriginY] = 8000.0f;
    sim_desc.s[RSSimulationDescriptionBoundOriginZ] = 0.0f;
    sim_desc.s[RSSimulationDescriptionBoundSizeX] = 2000.0f;
    sim_desc.s[RSSimulationDescriptionBoundSizeY] = 2000.0f;
    sim_desc.s[RSSimulationDescriptionBoundSizeZ] = 2000.0f;
    
    free(table);

    // Global / local parameterization for CL kernels
    RSMakePulseParams R = RS_make_pulse_params(num_elem, GROUP_ITEMS, GROUP_COUNTS, 1.0f, 0.25f, RANGE_GATES);
    
    // -----------------------------------------
    
    // Populate kernel setup
	kernel_pop = clCreateKernel(program, "pop", &ret);
	if (ret != CL_SUCCESS) {
		fprintf(stderr, "Error\n");
		exit(EXIT_FAILURE);
	}
    clSetKernelArg(kernel_pop, 0, sizeof(cl_mem), &rcs);
	clSetKernelArg(kernel_pop, 1, sizeof(cl_mem), &aux);
	clSetKernelArg(kernel_pop, 2, sizeof(cl_mem), &pos);
	clSetKernelArg(kernel_pop, 3, sizeof(cl_float16), &sim_desc);
    
    // Weight and attenuate setup
    kernel_scat_wa = clCreateKernel(program, "scat_wa", &ret);
    if (ret != CL_SUCCESS) {
        fprintf(stderr, "Error\n");
        exit(EXIT_FAILURE);
    }
    clSetKernelArg(kernel_scat_wa, RSScattererAngularWeightKernalArgumentSignal, sizeof(cl_mem),                    &sig);
    clSetKernelArg(kernel_scat_wa, RSScattererAngularWeightKernalArgumentAuxiliary, sizeof(cl_mem),                 &aux);
    clSetKernelArg(kernel_scat_wa, RSScattererAngularWeightKernalArgumentPosition, sizeof(cl_mem),                  &pos);
    clSetKernelArg(kernel_scat_wa, RSScattererAngularWeightKernalArgumentRadarCrossSection, sizeof(cl_mem),         &rcs);
    clSetKernelArg(kernel_scat_wa, RSScattererAngularWeightKernalArgumentWeightTable, sizeof(cl_mem),               &angular_weight);
    clSetKernelArg(kernel_scat_wa, RSScattererAngularWeightKernalArgumentWeightTableDescription, sizeof(cl_float4), &angular_weight_desc);
    clSetKernelArg(kernel_scat_wa, RSScattererAngularWeightKernalArgumentSimulationDescription, sizeof(cl_float16), &sim_desc);
    
    // Debris attributes
    kernel_db_atts = clCreateKernel(program, "db_atts", &ret);
    if (ret != CL_SUCCESS) {
        fprintf(stderr, "Error: Failed to compile kernel.\n");
        exit(EXIT_FAILURE);
    }
    
    err = CL_SUCCESS;
    ret |= clSetKernelArg(kernel_db_atts, RSDebrisAttributeKernelArgumentPosition,                      sizeof(cl_mem),     &pos);
    ret |= clSetKernelArg(kernel_db_atts, RSDebrisAttributeKernelArgumentOrientation,                   sizeof(cl_mem),     &ori);
    ret |= clSetKernelArg(kernel_db_atts, RSDebrisAttributeKernelArgumentVelocity,                      sizeof(cl_mem),     &vel);
    ret |= clSetKernelArg(kernel_db_atts, RSDebrisAttributeKernelArgumentTumble,                        sizeof(cl_mem),     &tum);
    ret |= clSetKernelArg(kernel_db_atts, RSDebrisAttributeKernelArgumentSignal,                        sizeof(cl_mem),     &sig);
    ret |= clSetKernelArg(kernel_db_atts, RSDebrisAttributeKernelArgumentRandomSeed,                    sizeof(cl_mem),     &rnd);
    ret |= clSetKernelArg(kernel_db_atts, RSDebrisAttributeKernelArgumentBackgroundVelocity,            sizeof(cl_mem),     &les);
    ret |= clSetKernelArg(kernel_db_atts, RSDebrisAttributeKernelArgumentBackgroundVelocityDescription, sizeof(cl_float16), &les_desc);
    ret |= clSetKernelArg(kernel_db_atts, RSDebrisAttributeKernelArgumentAirDragModelDrag,              sizeof(cl_mem),     &adm_cd);
    ret |= clSetKernelArg(kernel_db_atts, RSDebrisAttributeKernelArgumentAirDragModelMomentum,          sizeof(cl_mem),     &adm_cm);
    ret |= clSetKernelArg(kernel_db_atts, RSDebrisAttributeKernelArgumentAirDragModelDescription,       sizeof(cl_float16), &adm_desc);
    ret |= clSetKernelArg(kernel_db_atts, RSDebrisAttributeKernelArgumentRadarCrossSectionReal,         sizeof(cl_mem),     &rcs_real);
    ret |= clSetKernelArg(kernel_db_atts, RSDebrisAttributeKernelArgumentRadarCrossSectionImag,         sizeof(cl_mem),     &rcs_imag);
    ret |= clSetKernelArg(kernel_db_atts, RSDebrisAttributeKernelArgumentRadarCrossSectionDescription,  sizeof(cl_float16), &rcs_desc);
    ret |= clSetKernelArg(kernel_db_atts, RSDebrisAttributeKernelArgumentSimulationDescription,         sizeof(cl_float16), &sim_desc);
    if (ret != CL_SUCCESS) {
        fprintf(stderr, "%s : RS : Error: Failed to set arguments for kernel kern_db_atts().\n", now());
        exit(EXIT_FAILURE);
    }
    
    // Pass 1 setup
    printf("Pass 1   global=%5d   local=%3d   groups=%3d   entries=%7d  local_mem=%5zu (%2d x %d cl_float4)\n",
           (int)R.global[0],
           (int)R.local[0],
           R.group_counts[0],
           R.entry_counts[0],
           R.local_mem_size[0],
           R.range_count,
           (int)R.local[0]);
    
    kernel_make_pulse_pass_1 = clCreateKernel(program, "make_pulse_pass_1", &ret);
    if (ret != CL_SUCCESS) {
        fprintf(stderr, "Error: Failed to compile kernel.\n");
        exit(EXIT_FAILURE);
    }
    err = CL_SUCCESS;
    err |= clSetKernelArg(kernel_make_pulse_pass_1, 0, sizeof(cl_mem), &work);
    err |= clSetKernelArg(kernel_make_pulse_pass_1, 1, sizeof(cl_mem), &sig);
    err |= clSetKernelArg(kernel_make_pulse_pass_1, 2, sizeof(cl_mem), &aux);
    err |= clSetKernelArg(kernel_make_pulse_pass_1, 3, R.local_mem_size[0], NULL);
    err |= clSetKernelArg(kernel_make_pulse_pass_1, 4, sizeof(cl_mem), &range_weight);
    err |= clSetKernelArg(kernel_make_pulse_pass_1, 5, sizeof(cl_float4), &range_weight_desc);
    err |= clSetKernelArg(kernel_make_pulse_pass_1, 6, sizeof(float), &R.range_start);
    err |= clSetKernelArg(kernel_make_pulse_pass_1, 7, sizeof(float), &R.range_delta);
    err |= clSetKernelArg(kernel_make_pulse_pass_1, 8, sizeof(unsigned int), &R.range_count);
    err |= clSetKernelArg(kernel_make_pulse_pass_1, 9, sizeof(unsigned int), &R.group_counts[0]);
    err |= clSetKernelArg(kernel_make_pulse_pass_1, 10, sizeof(unsigned int), &R.entry_counts[0]);
    if (err != CL_SUCCESS) {
        fprintf(stderr, "Error: Failed to set kernel arguments.\n");
        exit(EXIT_FAILURE);
    }
    
    // Should check against hardware limits
    //	ret = clGetKernelWorkGroupInfo(kernel_make_pulse_pass_1, devices[0], CL_KERNEL_WORK_GROUP_SIZE, sizeof(size_t), &work_group_size, NULL);
    //	printf("%s : CL_KERNEL_WORK_GROUP_SIZE = %zu\n", now(), work_group_size);
    
    // Pass 2 setup
    printf("Pass 2   global=%5d   local=%3d   groups=%3d   entries=%7d  local_mem=%5zu ( 1 x %2lu cl_float4)  [%s]\n",
           (int)R.global[1],
           (int)R.local[1],
           R.group_counts[1],
           R.entry_counts[1],
           R.local_mem_size[1], R.local_mem_size[1] / sizeof(cl_float4),
           R.cl_pass_2_method == RS_CL_PASS_2_IN_RANGE ? "Range" :
           (R.cl_pass_2_method == RS_CL_PASS_2_IN_LOCAL ? "Local" : "Universal"));
    
    if (R.cl_pass_2_method == RS_CL_PASS_2_IN_RANGE) {
        kernel_make_pulse_pass_2 = clCreateKernel(program, "make_pulse_pass_2_range", &ret);
    } else if (R.cl_pass_2_method == RS_CL_PASS_2_IN_LOCAL) {
        kernel_make_pulse_pass_2 = clCreateKernel(program, "make_pulse_pass_2_local", &ret);
    } else {
        kernel_make_pulse_pass_2 = clCreateKernel(program, "make_pulse_pass_2_group", &ret);
    }
    if (ret != CL_SUCCESS) {
        fprintf(stderr, "Error: Failed to compile kernel.\n");
        exit(EXIT_FAILURE);
    }
    err = CL_SUCCESS;
    err |= clSetKernelArg(kernel_make_pulse_pass_2, 0, sizeof(cl_mem), &pulse);
    err |= clSetKernelArg(kernel_make_pulse_pass_2, 1, sizeof(cl_mem), &work);
    err |= clSetKernelArg(kernel_make_pulse_pass_2, 2, R.local_mem_size[1], NULL);
    err |= clSetKernelArg(kernel_make_pulse_pass_2, 3, sizeof(unsigned int), &R.range_count);
    err |= clSetKernelArg(kernel_make_pulse_pass_2, 4, sizeof(unsigned int), &R.entry_counts[1]);
    if (err != CL_SUCCESS) {
        fprintf(stderr, "Error: Failed to set kernel arguments.\n");
        exit(EXIT_FAILURE);
    }

    // -----------------------------------------
    
    // Queue populate
    clEnqueueNDRangeKernel(queue, kernel_pop, 1, NULL, &global_size, NULL, 0, NULL, NULL);

    // Queue reading data back
    clEnqueueReadBuffer(queue, rcs, CL_TRUE, 0, global_size * sizeof(cl_float4), host_rcs, 0, NULL, NULL);
    clEnqueueReadBuffer(queue, aux, CL_TRUE, 0, global_size * sizeof(cl_float4), host_aux, 0, NULL, NULL);
    clEnqueueReadBuffer(queue, pos, CL_TRUE, 0, global_size * sizeof(cl_float4), host_pos, 0, NULL, NULL);
    
    // Run the queue
    err = clFinish(queue);
    if (err != CL_SUCCESS) {
        fprintf(stderr, "Error: Failed in clFinish().\n");
        exit(EXIT_FAILURE);
    }
    
    //
	// CPU calculation
	//
	for (int ir=0; ir<RANGE_GATES; ir++) {
		cpu_pulse[ir] = zero;
		float r = (float)ir * R.range_delta + R.range_start;

		for (int i=0; i<num_elem; i++) {
			float r_a = host_aux[i].s0;
            float angle = acosf((sim_desc.s0 * host_pos[i].x + sim_desc.s1 * host_pos[i].y + sim_desc.s2 * host_pos[i].z) / r_a);
            float w_r = read_table(range_weight_cpu, xm, (r_a - r) * xs + xo);
            float w_a = read_table(angular_weight_cpu, angular_weight_desc.s2, angle * angular_weight_desc.s0 + angular_weight_desc.s1);
            
//            if (i < 100 && ir == 0) {
//                printf("angle = %.4f ==? %.4f   wa = %.4f ==? %.4f   r = %.4f ==? %.4f   sig = %.4f\n",
//                       angle, host_aux[i].s2,
//                       w_a, host_aux[i].s3,
//                       r_a, host_aux[i].s0,
//                       host_sig[i].s0);
//            }

//			if (ir < 2) {
//				float fidx = (r_a - r) * range_weight_table_dx + range_weight_table_x0;
//				printf("ir=%2u  r=%5.2f  i=%2u  r_a=%.3f  dr=%.3f  w_r=%.3f  %.2f -> %.0f/%.0f/%.2f\n",
//					   ir, r, i, r_a, r_a-r, w_r, fidx, floorf(fidx), ceilf(fidx), fidx-floorf(fidx));
//			}
            cl_float4 sig = host_rcs[i];
            sig = two_way_effects(sig, r_a, sim_desc.s[RSSimulationDescriptionWaveNumber]);
			cpu_pulse[ir].s0 += sig.s0 * w_r * w_a;
			cpu_pulse[ir].s1 += sig.s1 * w_r * w_a;
			cpu_pulse[ir].s2 += sig.s2 * w_r * w_a;
			cpu_pulse[ir].s3 += sig.s3 * w_r * w_a;
		}
	}
	
	if (verb > 2) {
		int i;
		cl_float4 v, a;
		printf("Input:\n");
		for (i=0; i<MIN(10, num_elem); i++) {
			clEnqueueReadBuffer(queue, sig, CL_TRUE, i * sizeof(cl_float4), sizeof(cl_float4), &v, 0, NULL, NULL);
            clEnqueueReadBuffer(queue, aux, CL_TRUE, i * sizeof(cl_float4), sizeof(cl_float4), &a, 0, NULL, NULL);
			printf("%7d :  %9.1f  %9.1f  %9.1f  %9.1f    |   %9.1f  %9.1f  %9.1f  %9.1f\n", i, v.x, v.y, v.z, v.w, a.x, a.y, a.z, a.w);
		}
        printf("        :         :          :          :          :     |          :          :          :          :\n");
		for (i=MAX(i, num_elem-3); i<num_elem; i++) {
			clEnqueueReadBuffer(queue, sig, CL_TRUE, i * sizeof(cl_float4), sizeof(cl_float4), &v, 0, NULL, NULL);
            clEnqueueReadBuffer(queue, aux, CL_TRUE, i * sizeof(cl_float4), sizeof(cl_float4), &a, 0, NULL, NULL);
            printf("%7d :  %9.1f  %9.1f  %9.1f  %9.1f    |   %9.1f  %9.1f  %9.1f  %9.1f\n", i, v.x, v.y, v.z, v.w, a.x, a.y, a.z, a.w);
		}
		printf("\n");
	}
    
    // Run the kernels to populate, weight and attenuate, make pulse and read back
	err = CL_SUCCESS;
    err |= clEnqueueNDRangeKernel(queue, kernel_pop, 1, NULL, &global_size, NULL, 0, NULL, NULL);
    err |= clEnqueueNDRangeKernel(queue, kernel_scat_wa, 1, NULL, &global_size, NULL, 0, NULL, &events[0]);
	err |= clEnqueueNDRangeKernel(queue, kernel_make_pulse_pass_1, 1, NULL, &R.global[0], &R.local[0], 1, &events[0], &events[1]);
	err |= clEnqueueNDRangeKernel(queue, kernel_make_pulse_pass_2, 1, NULL, &R.global[1], &R.local[1], 1, &events[1], &events[2]);
    err |= clEnqueueReadBuffer(queue, pulse, CL_TRUE, 0, R.range_count * sizeof(cl_float4), host_rcs, 1, &events[2], NULL);
	if (err != CL_SUCCESS) {
		fprintf(stderr, "Error: Failed in clEnqueueNDRangeKernel() and/or clEnqueueReadBuffer().\n");
		exit(EXIT_FAILURE);
	}
    err = clFinish(queue);
    if (err != CL_SUCCESS) {
        fprintf(stderr, "Error: Failed in clFinish().\n");
        exit(EXIT_FAILURE);
    }

    // Validate CPU vs GPU calculations
	printf("CPU Pulse :");
	for (int j=0; j<RANGE_GATES; j++) {
		printf(" %.3e", cpu_pulse[j].s0);
	}
	printf("\n");
	printf("GPU Pulse :");
	for (int j=0; j<R.range_count; j++) {
		printf(" %.3e", host_rcs[j].s0);
	}
	printf("\n");
	printf("Deltas    :");
	float delta = 0.0f, avg_delta = 0.0f;
	for (int j=0; j<R.range_count; j++) {
		delta = (cpu_pulse[j].s0 - host_rcs[j].s0) / MAX(1.0f, host_rcs[j].s0);
		avg_delta += delta;
		printf(" %.1e", delta);
	}
	avg_delta /= R.range_count;
	printf("\n");
	printf("Delta avg : %e\n", avg_delta);
	
    // Some speed test
    if (test & TEST_ALL) {
		int k = 0;
		double t = 0.0f;

		printf("Running speed tests:\n");
		
		if (test & TEST_CPU) {
			gettimeofday(&t1, NULL);
			for (k=0; k<speed_test_iterations; k++) {
				// Make a pulse
				for (int ir=0; ir<RANGE_GATES; ir++) {
					cpu_pulse[ir] = zero;
					float r = (float)ir * R.range_delta + R.range_start;
					
					for (int i=0; i<num_elem; i++) {
                        float r_a = host_aux[i].s0;
                        float angle = acosf((sim_desc.s0 * host_pos[i].x + sim_desc.s1 * host_pos[i].y + sim_desc.s2 * host_pos[i].z) / r_a);
                        float w_r = read_table(range_weight_cpu, xm, (r_a - r) * xs + xo);
                        float w_a = read_table(angular_weight_cpu, angular_weight_desc.s2, angle * angular_weight_desc.s0 + angular_weight_desc.s1);

                        cl_float4 sig = host_rcs[i];
                        sig = two_way_effects(sig, r_a, sim_desc.s[RSSimulationDescriptionWaveNumber]);
                        cpu_pulse[ir].s0 += sig.s0 * w_r * w_a;
                        cpu_pulse[ir].s1 += sig.s1 * w_r * w_a;
                        cpu_pulse[ir].s2 += sig.s2 * w_r * w_a;
                        cpu_pulse[ir].s3 += sig.s3 * w_r * w_a;
					}
				}
			}
			gettimeofday(&t2, NULL);
			t = DTIME(t1, t2);
			printf("CPU Exec Time = %6.2f ms\n",
				   t / speed_test_iterations * 1000.0f);
		}

		if (test & TEST_GPU_PASS_1) {
			gettimeofday(&t1, NULL);
			for (k=0; k<speed_test_iterations; k++) {
				clEnqueueNDRangeKernel(queue, kernel_make_pulse_pass_1, 1, NULL, &R.global[0], &R.local[0], 0, NULL, NULL);
			}
			clFinish(queue);
			gettimeofday(&t2, NULL);
			t = DTIME(t1, t2);
			printf("GPU Exec Time = %6.2f ms   Throughput = %6.2f GB/s  (make_pulse_pass_1)\n",
				   t / speed_test_iterations * 1000.0f,
				   1e-9 * R.entry_counts[0] * 2 * sizeof(cl_float4) * speed_test_iterations / t);
		}

		if (test & TEST_GPU_PASS_2) {
			gettimeofday(&t1, NULL);
			for (k=0; k<speed_test_iterations; k++) {
				clEnqueueNDRangeKernel(queue, kernel_make_pulse_pass_2, 1, NULL, &R.global[1], &R.local[1], 0, NULL, NULL);
			}
			clFinish(queue);
			gettimeofday(&t2, NULL);
			t = DTIME(t1, t2);
			printf("GPU Exec Time = %6.2f ms   Throughput = %6.2f GB/s  (make_pulse_pass_2)\n",
				   t / speed_test_iterations * 1000.0f,
				   1e-9 * R.entry_counts[1] * sizeof(cl_float4) * speed_test_iterations / t);
		}
        
        if (test & TEST_GPU_DB_ATTS) {
            gettimeofday(&t1, NULL);
            for (k=0; k<speed_test_iterations; k++) {
                err = clEnqueueNDRangeKernel(queue, kernel_db_atts, 1, NULL, &global_size, NULL, 0, NULL, NULL);
            }
            clFinish(queue);
            gettimeofday(&t2, NULL);
            t = DTIME(t1, t2);
            printf("GPU Exec Time = %6.2f ms   Throughput = %6.2f GB/s  (scat_db_atts)\n",
                   t / speed_test_iterations * 1000.0f,
                   1e-9 * num_elem * 7 * sizeof(cl_float4) * speed_test_iterations / t);
        }
        
        if (test & TEST_GPU_WA) {
            gettimeofday(&t1, NULL);
            for (k=0; k<speed_test_iterations; k++) {
                err = clEnqueueNDRangeKernel(queue, kernel_scat_wa, 1, NULL, &global_size, NULL, 0, NULL, NULL);
            }
            clFinish(queue);
            gettimeofday(&t2, NULL);
            t = DTIME(t1, t2);
            printf("GPU Exec Time = %6.2f ms   Throughput = %6.2f GB/s  (scat_wa)\n",
                   t / speed_test_iterations * 1000.0f,
                   1e-9 * num_elem * 4 * sizeof(cl_float4) * speed_test_iterations / t);
        }
	}

	free(cpu_pulse);

	free(host_rcs);
    free(host_pos);
	free(host_aux);

    clReleaseCommandQueue(queue);

	clReleaseKernel(kernel_pop);
	clReleaseKernel(kernel_make_pulse_pass_1);
	clReleaseKernel(kernel_make_pulse_pass_2);
	clReleaseMemObject(sig);
	clReleaseMemObject(pos);
    clReleaseMemObject(ori);
    clReleaseMemObject(vel);
    clReleaseMemObject(tum);
    clReleaseMemObject(aux);
    clReleaseMemObject(rcs);
    clReleaseMemObject(rnd);
    clReleaseMemObject(work);
	clReleaseMemObject(pulse);
	clReleaseMemObject(range_weight);
	clReleaseProgram(program);
	clReleaseContext(context);
	
	return 0;
}
