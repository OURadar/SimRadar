//
//  radarsim.c
//  Radar Simulator
//
//  This is an example of how to use the Radar Simulator framework (librs.a).
//  All functions with prefix RS_ are built-in functions in the framework
//  and this example shows the general flow of using the framework to emulate.
//  a radar and generate time-series data. The RS framework is written in C
//  so any superset language, e.g., C++, Objective-C, and Visual C++, can use
//  the framework to generate radar data.
//
//  Framework requirements: OpenCL 1.1
//
//  Created by Boon Leng Cheong.
//
//

#include "rs.h"

enum {
	ACCEL_TYPE_GPU,
	ACCEL_TYPE_CPU
};

//
//
//  M A I N
//
//
int main(int argc, char *argv[]) {

	char c;
	char verb = 0;
	char accel_type = 0;
	int num_frames = 5;
	float density = 0.0f;

	struct timeval t1, t2;

	while ((c = getopt(argc, argv, "vcgf:a:d:h?")) != -1) {
		switch (c) {
			case 'v':
				verb++;
				break;
			case 'c':
				accel_type = ACCEL_TYPE_CPU;
				break;
			case 'g':
				accel_type = ACCEL_TYPE_GPU;
				break;
			case 'f':
				num_frames = atoi(optarg);
				break;
			case 'a':
				accel_type = atoi(optarg);
				break;
			case 'd':
				density = atof(optarg);
				break;
			case 'h':
			case '?':
				printf("%s\n\n"
					   "%s [-v] [-c] [-g] FILE1 FILE2 ...\n\n"
					   "    -v    increases verbosity\n"
					   "    -c    CPU\n"
					   "    -g    GPU\n"
					   "    -f F  generates F frames\n"
					   "\n",
					   argv[0], argv[0]);
				return EXIT_FAILURE;
			default:
				fprintf (stderr, "Unknown option character `\\x%x'.\n", optopt);
				break;
		}
	}

	printf("%s : Session started\n", now());
	
	RSHandle *S;
    ADMHandle *A;
    LESHandle *L;
    RCSHandle *R;

	// Initialize the RS framework
	if (accel_type == ACCEL_TYPE_CPU) {
		S = RS_init_for_cpu_verbose(verb);
	} else {
		S = RS_init_verbose(verb);
	}
	if (S == NULL) {
		fprintf(stderr, "%s : Some errors occurred during RS_init().\n", now());
		return EXIT_FAILURE;
	}

	if (density > 0.0f) {
		RS_set_density(S, density);
	}
	
    // Initialize the LES ingest
    L = LES_init();
    if (L == NULL) {
        fprintf(stderr, "%s : Some errors occurred during LES_init().\n", now());
		return EXIT_FAILURE;
    }
    
    // Initialize the ADM ingest
    A = ADM_init();
    if (A == NULL) {
        fprintf(stderr, "%s : Some errors occurred during ADM_init().\n", now());
        return EXIT_FAILURE;
    }
    
    // Initialize the RCS ingest
    R = RCS_init();
    if (R == NULL) {
        fprintf(stderr, "%s : Some errors occurred during RCS_init().\n", now());
        return EXIT_FAILURE;
    }
    
	// Set up the parameters:
	// Only use the setter functions to change the state.
	RS_set_antenna_params(S, 1.0f, 44.5f);

	RS_set_tx_params(S, 1.0e-6, 50.0e3f);
    
    RS_set_prt(S, 1.0f);

	RS_set_scan_box(S,
					10.0e3, 15.0e3, 250.0f,                     // Range
					-10.0f, 10.0f, 1.0f,                        // Azimuth
					0.0f, 8.0f, 1.0f);                          // Elevation
	
	RS_set_range_weight_to_triangle(S, 120.0f);
	
	RS_set_wind_data_to_cube125(S);

	// Populate the domain with scatter bodies.
	// This is also the function that triggers kernel compilation, GPU memory allocation and
	// upload all the parameters to the GPU.
	RS_populate(S);
	
	// Show some basic info
	if (verb) {
		printf("%s : Emulating %s frame%s\n", now(), commaint(num_frames), num_frames>1 ? "s" : "");
	} else {
		printf("%s : Emulating %s frame%s with %s scatter bodies\n",
			   now(), commaint(num_frames), num_frames>1?"s":"", commaint(S->num_scats));
	}
	
	gettimeofday(&t1, NULL);

	// Now, we are ready to bake
    for (int k=0; k<num_frames; k++) {
        RS_make_pulse(S);
        RS_set_beam_pos(S, 15.0f, 10.0f);
        RS_advance_time(S);

        if (k <= 10) {
            RS_download(S);
            printf("== k = %d ==============\n", k);
            RS_show_scat_pos(S);
        }
    }

	gettimeofday(&t2, NULL);

	if (num_frames >= 10) {
		float dt = DTIME(t1, t2);
		printf("%s : Finished.  Time elapsed = %.2f s  (%.2f FPS).\n", now(), dt, (num_frames - 3) / dt);
	} else {
		printf("%s : Finished.\n", now());
	}
	
	if (accel_type == ACCEL_TYPE_GPU) {
		RS_download(S);
	}

	printf("Final scatter body positions:\n");

	RS_show_scat_pos(S);
	
	RS_free(S);

    LES_free(L);

	printf("%s : Session ended\n", now());

	return EXIT_SUCCESS;
}
