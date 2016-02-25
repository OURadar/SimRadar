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
	TEST_GPU_SIMPLE             = TEST_ADVANCE_TIME_GPU | TEST_MAKE_PULSE_GPU | TEST_DOWNLOAD | TEST_IO,
	TEST_GPU_ALL                = TEST_ADVANCE_TIME_GPU | TEST_MAKE_PULSE_GPU_PASS_1 | TEST_MAKE_PULSE_GPU_PASS_2 | TEST_DOWNLOAD | TEST_IO,
	TEST_CPU_ALL                = TEST_ADVANCE_TIME_CPU | TEST_MAKE_PULSE_CPU,
	TEST_ALL                    = TEST_GPU_ALL | TEST_CPU_ALL
};



int main(int argc, char **argv)
{
	char c;
	char verb = 0;
	uint32_t test = TEST_GPU_SIMPLE;

    float density = 0.0f;
	unsigned int N = 0;
	
	struct timeval t1, t2;
	
	while ((c = getopt(argc, argv, "vac012igdn:s:tDh?")) != -1) {
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
            case 'D':
                test |= TEST_DB_ATTS;
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
    ADMHandle *A = ADM_init();
    if (A == NULL) {
        fprintf(stderr, "%s : Some errors occurred during ADM_init().\n", now());
        return EXIT_FAILURE;
    }
    RCSHandle *R = RCS_init();
    if (R == NULL) {
        fprintf(stderr, "%s : Some errors occurred during RCS_init().\n", now());
        return EXIT_FAILURE;
    }

    if (density > 0) {
        RS_set_density(H, density);
    }
	
	RS_set_scan_box(H,
					15.0e3f, 20.0e3f, 250.0f,
					-10.0f, 10.0f, 1.0f,
					0.0f, 8.0f, 1.0f);

	RS_set_range_weight_to_triangle(H, 250.0f);
	
	RS_set_angular_weight_to_standard(H, 2.0f / 180.0f * M_PI);
    
    RS_set_adm_data_to_ADM_table(H, ADM_get_table(A, ADMConfigModelPlate));
    
    RS_set_rcs_data_to_RCS_table(H, RCS_get_table(R, RCSConfigLeaf));

    RS_set_debris_count(H, 1, 100000);
    
    RS_revise_debris_counts_to_gpu_preference(H);
	
	RS_populate(H);
	
	printf("\nTest(s) using %s scatter bodies for %d iterations:\n\n", commaint(H->num_scats), N);

	RS_advance_time(H);
    
#define FMT   "%30s  %8.4f ms\n"
#define FMT2  "%30s  %8.4f ms  (%.2f GB/s)\n"
	
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
    printf("\nTest(s) using %s debris objects for %d iterations:\n\n", commaint(H->debris_population[1]), N);
    
    //
    //  db_atts
    //
    if (test & TEST_DB_ATTS) {
        byte_size = 6 * H->debris_population[1] * sizeof(cl_float4);
        gettimeofday(&t1, NULL);
        int k = 1;
        for (i=0; i<N; i++) {
            clEnqueueNDRangeKernel(H->worker[0].que,
                                   H->worker[0].kern_db_atts,
                                   1,
                                   &H->worker[0].debris_origin[k],
                                   &H->worker[0].debris_population[k],
                                   NULL,
                                   0,
                                   NULL,
                                   NULL);
        }
        clFinish(H->worker[0].que);
        gettimeofday(&t2, NULL);
        dt = DTIME(t1, t2) / (float)N;
        printf(FMT2, "db_atts", 1.0e3f * dt, 1.0e-9f * byte_size / dt);
    }
    
    //
    //  make_pulse_pass_1
    //
    if (test & TEST_MAKE_PULSE_GPU_PASS_1) {
        gettimeofday(&t1, NULL);
        for (i=0; i<N; i++) {
            clEnqueueNDRangeKernel(H->worker[0].que,
                                   H->worker[0].kern_make_pulse_pass_1,
                                   1,
                                   NULL,
                                   &H->worker[0].make_pulse_params.global[0],
                                   &H->worker[0].make_pulse_params.local[0],
                                   0,
                                   NULL,
                                   NULL);
        }
        clFinish(H->worker[0].que);
        gettimeofday(&t2, NULL);
        printf(FMT, "make_pulse_pass_1", 1.0e3f * DTIME(t1, t2) / (float)N);
    }
    
    //
    //  make_pulse_pass_2
    //
    if (test & TEST_MAKE_PULSE_GPU_PASS_2) {
        gettimeofday(&t1, NULL);
        for (i=0; i<N; i++) {
            clEnqueueNDRangeKernel(H->worker[0].que,
                                   H->worker[0].kern_make_pulse_pass_2,
                                   1,
                                   NULL,
                                   &H->worker[0].make_pulse_params.global[1],
                                   &H->worker[0].make_pulse_params.local[1],
                                   0,
                                   NULL,
                                   NULL);
        }
        clFinish(H->worker[0].que);
        gettimeofday(&t2, NULL);
        printf(FMT, "make_pulse_pass_2", 1.0e3f * DTIME(t1, t2) / (float)N);
    }
    

    RS_free(H);

	return EXIT_SUCCESS;
}
