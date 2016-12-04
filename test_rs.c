/*
 *
 * Test a reduction kernel
 *
 */

#include <errno.h>
#include "rs.h"

enum {
	TEST_N0NE                   = 0,
	TEST_ADVANCE_TIME_GPU       = 1,
	TEST_ADVANCE_TIME_CPU       = 1 << 1,
	TEST_MAKE_PULSE_GPU         = 1 << 2,
	TEST_MAKE_PULSE_GPU_PASS_1  = 1 << 3,
	TEST_MAKE_PULSE_GPU_PASS_2  = 1 << 4,
	TEST_MAKE_PULSE_CPU         = 1 << 5,
	TEST_DOWNLOAD               = 1 << 6,
    TEST_IO                     = 1 << 7,
    TEST_DUMMY                  = 1 << 8,
    TEST_SIG_AUX                = 1 << 9,
    TEST_BG_ATTS                = 1 << 10,
    TEST_EL_ATTS                = 1 << 11,
    TEST_DB_ATTS                = 1 << 12,
    TEST_KERNEL_MASK            = (TEST_BG_ATTS | TEST_EL_ATTS | TEST_DB_ATTS | TEST_SIG_AUX | TEST_MAKE_PULSE_GPU_PASS_1 | TEST_MAKE_PULSE_GPU_PASS_2),
	TEST_GPU_SIMPLE             = (TEST_ADVANCE_TIME_GPU | TEST_MAKE_PULSE_GPU | TEST_DOWNLOAD | TEST_IO),
	TEST_GPU_ALL                = (TEST_ADVANCE_TIME_GPU | TEST_MAKE_PULSE_GPU_PASS_1 | TEST_MAKE_PULSE_GPU_PASS_2 | TEST_DOWNLOAD | TEST_IO),
	TEST_CPU_ALL                = (TEST_ADVANCE_TIME_CPU | TEST_MAKE_PULSE_CPU),
	TEST_ALL                    = (TEST_GPU_ALL | TEST_CPU_ALL)
};



int main(int argc, char **argv)
{
	char c;
	char verb = 0;
	uint32_t test = TEST_GPU_SIMPLE;

    float density = 0.0f;
	unsigned int N = 0;
	
	struct timeval t1, t2;
	
	while ((c = getopt(argc, argv, "vac012igdn:s:tkh?")) != -1) {
		switch (c) {
            case 'v':
                verb++;
                break;
			case 'a':
				test = TEST_ALL;
				break;
            case '0':
                test = TEST_N0NE;
                break;
			case '1':
				test |= TEST_MAKE_PULSE_GPU_PASS_1;
				break;
			case '2':
				test |= TEST_MAKE_PULSE_GPU_PASS_2;
				break;
            case 'i':
                test |= TEST_IO;
                break;
			case 'g':
				test |= TEST_GPU_SIMPLE;
				break;
			case 'd':
				test |= TEST_DOWNLOAD;
				break;
			case 'c':
				test |= TEST_MAKE_PULSE_CPU;
				break;
            case 't':
                test |= TEST_DUMMY;
                break;
            case 'k':
            test |= TEST_KERNEL_MASK;
                break;
			case 'n':
				N = atoi(optarg);
				break;
            case 's':
                density = atof(optarg);
                break;
			case 'h':
			case '?':
				printf("%s\n\n"
					   "%s [OPTIONS]\n\n"
					   "    -a     All CPU & GPU tests\n"
					   "    -c     CPU test\n"
					   "    -1     GPU Pass 1 test\n"
					   "    -2     GPU Pass 2 test\n"
					   "    -g     All GPU Tests\n"
					   "    -v     increases verbosity\n"
					   "    -n N   speed test using N iterations\n"
					   "    -s S   speed test using scatter density S\n"
					   "\n",
					   argv[0], argv[0]);
				return EXIT_FAILURE;
			default:
				fprintf (stderr, "Unknown option character `\\x%x'.\n", optopt);
				break;
		}
	}
	
	if (test & TEST_ALL && N == 0) {
		N = 100;
    }

	int i;
	double dt;
	size_t byte_size;
	
	RSHandle *H = RS_init_verbose(verb);
	if (H == NULL) {
		fprintf(stderr, "%s : Some errors occurred.\n", now());
		return EXIT_FAILURE;
	}

    if (density > 0) {
        RS_set_density(H, density);
    }
	
	RS_set_range_weight_to_triangle(H, 250.0f);
	
	RS_set_angular_weight_to_standard(H, 2.0f / 180.0f * M_PI);
    
    RS_set_obj_data_to_config(H, OBJConfigLeaf);

    RS_set_debris_count(H, 1, 100 * 1000);
    
    RS_revise_debris_counts_to_gpu_preference(H);
	
    RS_set_scan_box(H,
                    15.0e3f, 20.0e3f, 250.0f,
                    -10.0f, 10.0f, 1.0f,
                    0.0f, 5.0f, 1.0f);
    
	RS_populate(H);
	
	printf("\nTest(s) using %s scatterers and %s debris objects for %s iterations:\n\n",
           commaint(H->num_scats), commaint(H->counts[0]), commaint(N));

	RS_advance_time(H);
    
#define FMT   "%30s  %8.4f ms\n"
#define FMT2  "%30s  %8.4f ms   %6.2f GB/s\n"
	
    printf("Framework functions:\n\n");

    //
    // RS_io_test()
    //
    if (test & TEST_IO) {
        byte_size = H->num_scats * 2 * sizeof(cl_float4);
        gettimeofday(&t1, NULL);
        for (i=0; i<N; i++)
            RS_io_test(H);
        gettimeofday(&t2, NULL);
        dt = DTIME(t1, t2) / (float)N;
        printf(FMT2, "RS_io_test()", 1.0e3f * dt, 1.0e-9f * byte_size / dt);
    }

    //
	//  RS_advance_time()
	//
	if (test & TEST_ADVANCE_TIME_GPU) {
        // 4 Input arguments for scat_mov() kernel
        byte_size = H->num_scats * 4 * sizeof(cl_float4);
		gettimeofday(&t1, NULL);
		for (i=0; i<N; i++)
			RS_advance_time(H);
		gettimeofday(&t2, NULL);
		dt = DTIME(t1, t2) / (float)N;
		printf(FMT2, "RS_advance_time()", 1.0e3f * dt, 1.0e-9f * byte_size / dt);
	}

	//
	//  RS_make_pulse()
	//
	if (test & TEST_MAKE_PULSE_GPU) {
		gettimeofday(&t1, NULL);
		for (i=0; i<N; i++)
			RS_make_pulse(H);
		gettimeofday(&t2, NULL);
        dt = DTIME(t1, t2) / (float)N;
		printf(FMT, "RS_make_pulse()", 1.0e3f * dt);
	}

	//
	//  RS_download()
	//
	if (test & TEST_DOWNLOAD) {
        // Only range_count * H + V - IQ data
        byte_size = 5 * H->num_scats * sizeof(cl_float4);
		gettimeofday(&t1, NULL);
		for (i=0; i<N; i++)
			RS_download(H);
		gettimeofday(&t2, NULL);
		dt = DTIME(t1, t2) / (float)N;
		printf(FMT2, "RS_download()", 1.0e3f * dt, 1.0e-9f * byte_size / dt);
	}
	
    //
    //  Some kernels
    //
    if (test & TEST_KERNEL_MASK) {
        printf("\nInternal kernel functions:\n\n");
    }
    
    //
    //  make_pulse_pass_1
    //
    if (test & TEST_MAKE_PULSE_GPU_PASS_1) {
        byte_size = H->workers[0].make_pulse_params.entry_counts[0] * 2 * sizeof(cl_float4);
        gettimeofday(&t1, NULL);
        for (i=0; i<N; i++) {
            clEnqueueNDRangeKernel(H->workers[0].que,
                                   H->workers[0].kern_make_pulse_pass_1,
                                   1,
                                   NULL,
                                   &H->workers[0].make_pulse_params.global[0],
                                   &H->workers[0].make_pulse_params.local[0],
                                   0,
                                   NULL,
                                   NULL);
        }
        clFinish(H->workers[0].que);
        gettimeofday(&t2, NULL);
        dt = DTIME(t1, t2) / (float)N;
        printf(FMT2, "make_pulse_pass_2", 1.0e3f * dt, 1.0e-9f * byte_size / dt);
    }
    
    //
    //  make_pulse_pass_2
    //
    if (test & TEST_MAKE_PULSE_GPU_PASS_2) {
        byte_size = H->workers[0].make_pulse_params.entry_counts[1] * sizeof(cl_float4);
        gettimeofday(&t1, NULL);
        for (i=0; i<N; i++) {
            clEnqueueNDRangeKernel(H->workers[0].que,
                                   H->workers[0].kern_make_pulse_pass_2,
                                   1,
                                   NULL,
                                   &H->workers[0].make_pulse_params.global[1],
                                   &H->workers[0].make_pulse_params.local[1],
                                   0,
                                   NULL,
                                   NULL);
        }
        clFinish(H->workers[0].que);
        gettimeofday(&t2, NULL);
        dt = DTIME(t1, t2) / (float)N;
        printf(FMT2, "make_pulse_pass_2", 1.0e3f * dt, 1.0e-9f * byte_size / dt);
    }
    
    //
    //  db_atts
    //
    if (test & TEST_DB_ATTS) {
        byte_size = 6 * H->counts[1] * sizeof(cl_float4);
        gettimeofday(&t1, NULL);
        int k = 1;
        for (i=0; i<N; i++) {
            clEnqueueNDRangeKernel(H->workers[0].que,
                                   H->workers[0].kern_db_atts,
                                   1,
                                   &H->workers[0].origins[k],
                                   &H->workers[0].counts[k],
                                   NULL,
                                   0,
                                   NULL,
                                   NULL);
        }
        clFinish(H->workers[0].que);
        gettimeofday(&t2, NULL);
        dt = DTIME(t1, t2) / (float)N;
        printf(FMT2, "db_atts", 1.0e3f * dt, 1.0e-9f * byte_size / dt);
    }
    
    //
    //  el_atts
    //
    if (test & TEST_EL_ATTS) {
        byte_size = 4 * H->counts[0] * sizeof(cl_float4);
        gettimeofday(&t1, NULL);
        for (i=0; i<N; i++) {
            clEnqueueNDRangeKernel(H->workers[0].que,
                                   H->workers[0].kern_el_atts,
                                   1,
                                   &H->workers[0].origins[0],
                                   &H->workers[0].counts[0],
                                   NULL,
                                   0,
                                   NULL,
                                   NULL);
        }
        clFinish(H->workers[0].que);
        gettimeofday(&t2, NULL);
        dt = DTIME(t1, t2) / (float)N;
        printf(FMT2, "el_atts", 1.0e3f * dt, 1.0e-9f * byte_size / dt);
    }
    
    //
    //  scat_sig_aux
    //
    if (test & TEST_SIG_AUX) {
        byte_size = 4 * H->num_scats * sizeof(cl_float4);
        gettimeofday(&t1, NULL);
        for (i=0; i<N; i++) {
            clEnqueueNDRangeKernel(H->workers[0].que,
                                   H->workers[0].kern_scat_sig_aux,
                                   1,
                                   NULL,
                                   &H->num_scats,
                                   NULL,
                                   0,
                                   NULL,
                                   NULL);
        }
        clFinish(H->workers[0].que);
        gettimeofday(&t2, NULL);
        dt = DTIME(t1, t2) / (float)N;
        printf(FMT2, "scat_sig_aux", 1.0e3f * dt, 1.0e-9f * byte_size / dt);
    }

    RS_free(H);

	return EXIT_SUCCESS;
}
