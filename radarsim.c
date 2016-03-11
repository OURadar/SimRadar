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
#include "iq.h"
#include <getopt.h>

enum ACCEL_TYPE {
    ACCEL_TYPE_GPU,
    ACCEL_TYPE_CPU
};

enum SCAN_MODE {
    SCAN_MODE_STARE,
    SCAN_MODE_PPI,
    SCAN_MODE_RHI
};

typedef struct scan_params {
    char mode;
    float start;
    float end;
    float delta;
    float az;
    float el;
} ScanParams;

int get_next_scan_angles(ScanParams *params) {
    if (params->mode == SCAN_MODE_PPI) {
        params->az += params->delta;
        if (params->delta > 0.0f) {
            if (params->az > params->end) {
                params->az = params->start;
            } else if (params->az < params->start) {
                params->az = params->end;
            }
        } else {
            if (params->az > params->start) {
                params->az = params->end;
            } else if (params->az < params->end) {
                params->az = params->start;
            }

        }
        if (params->az < params->start || params->az > params->end) {
            return 1;
        }
    } else if (params->mode == SCAN_MODE_RHI) {
        params->el += params->delta;
        if (params->el > params->end) {
            params->el = params->start;
        } else if (params->el < params->start) {
            params->el = params->end;
        }
        if (params->el < params->start || params->el > params->end) {
            return 2;
        }
    }
    return 0;
}

static char *scan_mode_str(char scan_mode) {
    static char str[16];
    switch (scan_mode) {
        case SCAN_MODE_PPI:
        snprintf(str, sizeof(str), "PPI");
        break;
        
        case SCAN_MODE_RHI:
        snprintf(str, sizeof(str), "RHI");
        break;

        case SCAN_MODE_STARE:
        snprintf(str, sizeof(str), "STARE");
        break;

        default:
        break;
    }
    return str;
}

//
//   s h o w _ h e l p
//
#define CLEAR         "\033[0m"
#define UNDERLINE(x)  "\033[4m" x "\033[0m"
#define PROGNAME      "radarsim"

void show_help() {
    printf("Radar simulation\n\n"
           PROGNAME " [options]\n\n"
           "OPTIONS\n"
           "     Unless specifically stated, all options are interpreted in sequence\n"
           "  --alarm\n"
           "         Make an alarm when the simulation is complete.\n"
           "\n"
           "  -D (--density) " UNDERLINE("D") "\n"
           "         Set the density of particles to " UNDERLINE("D") " scatterers per resolution volume\n"
           "\n"
           "  -N (--preview)\n"
           "         No simulation. Previews the scanning angles of the setup. No data will\n"
           "         be generated.\n"
           "\n"
           "  --sweep " UNDERLINE("M:S:E:D") "\n"
           "         Sets the beam to scan mode.\n"
           "         The argument " UNDERLINE("M:S:E:D") " are parameters for mode, start, end, and delta.\n"
           "            M = R for RHI (range height indicator) mode\n"
           "            M = P for RHI (range height indicator) mode\n"
           "         Examples:\n"
           "            --sweep P:-12:12:0.1\n"
           "                sets the scan mode in PPI, start from azimuth -12-deg and ends\n"
           "                at azimuth +12-deg. The beam. Position delta is 0.1-deg, which\n"
           "                means the azimuth changes by 0.1-deg at every pulse.\n"
           "            --sweep R:0.5:12.0:0.2\n"
           "                sets the scan mode in RHI, start from elevation 0.5-deg and ends\n"
           "                at elevation 12.0-deg. The beam position delta is 0.2-deg, which\n"
           "                means the elevation changes by 0.5-deg at every pulse.\n"
           "\n"
           "  -W (--warmup) " UNDERLINE("count") "\n"
           "         Sets the warm up stage to use " UNDERLINE("count") " pulses.\n"
           "\n"
           "  -a (--azimuth) " UNDERLINE("angle") "\n"
           "         Sets the scan azimuth to " UNDERLINE("angle") " degrees.\n"
           "         See --sweep for more information.\n"
           "\n"
           "  -e (--elevation) " UNDERLINE("angle") "\n"
           "         Sets the scan elevation to " UNDERLINE("angle") " degrees.\n"
           "         See --sweep for more information.\n"
           "\n"
           "  -t " UNDERLINE("period") "\n"
           "         Sets the pulse repetition time to " UNDERLINE("period") " seconds.\n"
           "\n"
           "  -o     Sets the program to produce an output file. The filename is derived\n"
           "         based on the current date and time and an output file with name like\n"
           "         sim-20160229-143941-E03.0.iq will be placed in the ~/Downloads folder.\n"
           "\n"
           "  -p " UNDERLINE("count") "\n"
           "         Sets the number of pulses to " UNDERLINE("count") ". There is no\n"
           "         hard boundaries on which pulse marks the end of a sweep. If user wants\n"
           "         a sweep that contain 2400 pulses, it can be accomplished by setting\n"
           "         sweep mode = P, start = -12, end = +12, delta = 0.01, and combine with\n"
           "         option -p 2400 for a simulation session of 2400 pulses.\n"
           "\n"
           "  -f " UNDERLINE("count") "\n"
           "         Sets the number of frames to " UNDERLINE("count") ". This option is identical -p.\n"
           "         See -p for more information.\n"
           "\n"
           "  --lambda " UNDERLINE("wavelength") "\n"
           "         Sets the radar wavelength to " UNDERLINE("wavelength") " meters.\n"
           "\n"
           "  -d (--debris) " UNDERLINE("count") "\n"
           "         Sets the population of debris to " UNDERLINE("count") ".\n"
           "         When is option is specified multiple times, multiple debris types will\n"
           "         be used in the simulator.\n"
           "         Debris type is as follows:\n"
           "            o  Leaf\n"
           "            o  Wood Board\n"
           "\n"
           "  -c (--concept) " UNDERLINE("concepts") "\n"
           "         Sets the simulation concepts to be used, which are OR together for\n"
           "         multiple values that can be combined together.\n"
           "            D - Dragged background.\n"
           "            U - Uniform rain drop size density with scaled RCS.\n"
           "            V - Bounded particle velocity.\n"
           "         Examples:\n"
           "            --concept DU\n"
           "                sets simulation to use the concept of dragged background and\n"
           "                uniform density of rain drop size.\n"
           "            --concept V\n"
           "                sets simulation to use the concept of bounded particle velocity\n"
           "                but left the others as default.\n"
           "\n\n"
           "EXAMPLES\n"
           "     The following simulates a vortex and creates a PPI scan data using default\n"
           "     scan parameters. This allows you quickly check if the tools works. An\n"
           "     output file will be generated in the ~/Downloads folder.\n"
           "           " PROGNAME " -o\n"
           "\n"
           "     The following simulates a vortex and creates a PPI scan data using\n"
           "     scan parameter: mode = 'P' (PPI), start = -12, end = +12, delta = 0.01,\n"
           "     el = 3.0 deg, p = 2400 (number of pulses).\n"
           "           " PROGNAME " -e 3.0 --sweep P:-12:12:0.01 -p 2400 -o\n"
           "\n"
           "     The following simulates a vortex and creates an RHI scan data using\n"
           "     scan parameters: mode = 'R' (RHI), start = 0, end = 12, delta = 0.01,\n"
           "     az = 1.0 deg, p = 1200.\n"
           "           " PROGNAME " -a 1.0 --sweep R:0:12:0.01 -p 1200 -o\n"
           "\n"
           "     The following simulates a vortex and creates an PPI scan data using\n"
           "     10,000 debris type #1, which is the leaf.\n"
           "           " PROGNAME " -a 1.0 --sweep R:0:12:0.01 -p 1200 -d 10000 -o\n"
           "\n"
           );
}

//
//
//  M A I N
//
//
int main(int argc, char *argv[]) {
    
    int k = 0;
    char verb = 0;
    char accel_type = 0;
    char quiet_mode = true;
    char preview_only = false;
    char output_file = false;
    int num_pulses = 5;

    float density = 0.0f;
    float lambda = 0.0f;
    float pw = 0.2e-6f;   // pulse width in seconds
    float prt = 1.0e-3f;
    
    // A structure unit that encapsulates the scan strategy
    ScanParams scan;
    scan.mode = SCAN_MODE_PPI;
    scan.start = - 12.0f;
    scan.end   = +12.0f;
    scan.delta = 0.01f;
    scan.az = scan.start;
    scan.el = 3.0f;
    
    struct timeval t0, t1, t2;
    
    gettimeofday(&t0, NULL);
    
    int debris_types = 0;
    int debris_count[RS_MAX_DEBRIS_TYPES];
    int warm_up_pulses = 2000;
    RSSimulationConcept concept = RSSimulationConceptUniformDSDScaledRCS;
    
    memset(debris_count, 0, RS_MAX_DEBRIS_TYPES * sizeof(int));

    // ---------------------------------------------------------------------------------------------------------------

    static struct option long_options[] = {
        {"alarm"      , no_argument      , 0, 'A'}, // ASCII 65 - 90 : A - Z
        {"cpu"        , no_argument      , 0, 'C'},
        {"density"    , required_argument, 0, 'D'},
        {"preview"    , no_argument      , 0, 'N'},
        {"sweep"      , required_argument, 0, 'S'},
        {"warmup"     , required_argument, 0, 'W'},
        {"azimuth"    , required_argument, 0, 'a'}, // ASCII 97 - 122 : a - z
        {"concept"    , required_argument, 0, 'c'},
        {"debris"     , required_argument, 0, 'd'},
        {"elevation"  , required_argument, 0, 'e'},
        {"help"       , no_argument      , 0, 'h'},
        {"gpu"        , no_argument      , 0, 'g'},
        {"frames"     , required_argument, 0, 'f'},
        {"lambda"     , required_argument, 0, 'l'},
        {"output"     , no_argument      , 0, 'o'},
        {"pulses"     , required_argument, 0, 'p'},
        {"prt"        , required_argument, 0, 't'},
        {"pulsewidth" , required_argument, 0, 'w'},
        {"quiet"      , no_argument      , 0, 'q'},
        {"verbose"    , no_argument      , 0, 'v'},
        {0, 0, 0, 0}
    };
    
    // Construct short_options from long_options
    char str[1024] = "";
    for (k = 0; k < sizeof(long_options) / sizeof(struct option); k++) {
        struct option *o = &long_options[k];
        snprintf(str + strlen(str), 1024, "%c%s", o->val, o->has_arg ? ":" : "");
    }
    //printf("str = '%s'\n", str);
    
    char c1;
    float f1, f2, f3;
    // Process the input arguments and set the simulator parameters
    int opt, long_index = 0;
    while ((opt = getopt_long(argc, argv, str, long_options, &long_index)) != -1) {
        switch (opt) {
            case 'a':
                scan.az = atof(optarg);
                break;
            case 'A':
                quiet_mode = false;
                break;
            case 'c':
                if (strcasestr(optarg, "D")) {
                    concept |= RSSimulationConceptDraggedBackground;
                }
                if (strcasestr(optarg, "U")) {
                    concept |= RSSimulationConceptUniformDSDScaledRCS;
                }
                if (strcasestr(optarg, "V")) {
                    concept |= RSSimulationConceptBoundedParticleVelocity;
                }
                break;
            case 'C':
                accel_type = ACCEL_TYPE_CPU;
                break;
            case 'd':
                debris_count[debris_types++] = atoi(optarg);
                break;
            case 'e':
                scan.el = atof(optarg);
                break;
            case 'g':
                accel_type = ACCEL_TYPE_GPU;
                break;
            case 'h':
                show_help();
                exit(EXIT_SUCCESS);
                break;
            case 'f':
                num_pulses = atoi(optarg);
                break;
            case 'l':
                lambda = atof(optarg);
                break;
            case 'o':
                output_file = true;
                break;
            case 'p':
                num_pulses = atoi(optarg);
                break;
            case 'q':
                quiet_mode = true;
                break;
            case 't':
                prt = atof(optarg);
                break;
            case 'v':
                verb++;
                break;
            case 'w':
                pw = atof(optarg);
                break;
            case 'D':
                density = atof(optarg);
                break;
            case 'N':
                preview_only = true;
                break;
            case 'S':
                k = sscanf(optarg, "%c:%f:%f:%f", &c1, &f1, &f2, &f3);
                if (k < 4) {
                    fprintf(stderr, "Error in scanmode argument.\n");
                    exit(EXIT_FAILURE);
                }
                scan.mode = c1 == 'P' ? SCAN_MODE_PPI : ( c1 == 'R' ? SCAN_MODE_RHI : SCAN_MODE_STARE);
                scan.start = f1;
                scan.end = f2;
                scan.delta = f3;
                if (scan.mode == SCAN_MODE_PPI) {
                    scan.az = f1;
                } else if (scan.mode == SCAN_MODE_RHI) {
                    scan.el = f1;
                }
                break;
            case 'W':
                warm_up_pulses = atoi(optarg);
                break;
            default:
                exit(EXIT_FAILURE);
                break;
        }
    }

    // ---------------------------------------------------------------------------------------------------------------

    // Preview only
    if (preview_only) {
        #define FLT_FMT  "\033[1;33m%+6.2f\033[0m"
        printf("Scan mode: \033[1;32m%s\033[0m", scan_mode_str(scan.mode));
        if (scan.mode == SCAN_MODE_RHI) {
            printf("   AZ: " FLT_FMT " deg", scan.az);
        } else {
            printf("   EL: " FLT_FMT " deg", scan.el);
        }
        if (scan.mode == SCAN_MODE_RHI) {
            printf("   EL: " FLT_FMT " -- " FLT_FMT " deg    delta: " FLT_FMT " deg\n", scan.start, scan.end, scan.delta);
        } else if (scan.mode == SCAN_MODE_PPI) {
            printf("   AZ: " FLT_FMT " -- " FLT_FMT " deg    delta: " FLT_FMT " deg\n", scan.start, scan.end, scan.delta);
        } else {
            printf("   EL: " FLT_FMT " deg\n", scan.el);
        }
        for (k = 0; k < num_pulses; k++) {
            fprintf(stderr, "k = %4d   el = %6.2f deg   az = %5.2f deg\n", k, scan.el, scan.az);
            get_next_scan_angles(&scan);
        }
        return EXIT_SUCCESS;
    }

    // ---------------------------------------------------------------------------------------------------------------

    // Initialize the RS framework
    RSHandle *S;
    if (accel_type == ACCEL_TYPE_CPU) {
        S = RS_init_for_cpu_verbose(verb);
    } else {
        S = RS_init_verbose(verb);
    }
    if (S == NULL) {
        fprintf(stderr, "%s : Some errors occurred during RS_init().\n", now());
        return EXIT_FAILURE;
    }
    
    printf("%s : Session started\n", now());
    
    ADMHandle *A;
    LESHandle *L;
    RCSHandle *R;
//    ARPSHandle *O;
    
    
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
    
    // Initialize the ARPS ingest
//    O = ARPS_init();
//    if (O == NULL) {
//        fprintf(stderr, "%s : Some errors occurred during ARPS_init().\n", now());
//        return EXIT_FAILURE;
//    }
    
    RS_set_concept(S, concept);
    
    RS_set_antenna_params(S, 1.0f, 44.5f);
    
    RS_set_tx_params(S, pw, 50.0e3f);
    
    if (density > 0.0f) {
        RS_set_density(S, density);
    }
    
    if (lambda > 0.0f) {
        RS_set_lambda(S, lambda);
    }

    // Number of LES entries needed based on the number of pulses to be simulated
    int nvel = (int)ceilf(((float)num_pulses * S->params.prt + (float)warm_up_pulses * 1.0f / 60.0f) / LES_get_table_period(L));
    for (int k = 0; k < MIN(RS_MAX_VEL_TABLES, nvel); k++) {
        RS_set_vel_data_to_LES_table(S, LES_get_frame(L, k));
    }
    
    RS_set_adm_data_to_ADM_table(S, ADM_get_table(A, ADMConfigModelPlate));
    RS_set_adm_data_to_ADM_table(S, ADM_get_table(A, ADMConfigSquarePlate));
    
    RS_set_rcs_data_to_RCS_table(S, RCS_get_table(R, RCSConfigLeaf));
    RS_set_rcs_data_to_RCS_table(S, RCS_get_table(R, RCSConfigWoodBoard));

    RSBox box = RS_suggest_scan_domain(S, 16);
    
    // Set debris population
    for (k = 0; k < debris_types; k++) {
        if (debris_count[k]) {
            RS_set_debris_count(S, k + 1, debris_count[k]);
        }
    }
    RS_revise_debris_counts_to_gpu_preference(S);
    
    if (scan.mode == SCAN_MODE_PPI) {
        // No need to go all the way up if we are looking low
        box.size.e = MIN(box.size.e, scan.el);
    } else if (scan.mode == SCAN_MODE_RHI) {
        // Need to make sure we cover the very top
        box.size.e = MAX(scan.start, scan.end);
    }
    
    RS_set_scan_box(S,
                    box.origin.r, box.origin.r + box.size.r, 15.0f,   // Range
                    box.origin.a, box.origin.a + box.size.a, 1.0f,    // Azimuth
                    box.origin.e, box.origin.e + box.size.e, 1.0f);   // Elevation
    
    RS_set_dsd_to_mp(S);

    // Populate the domain with scatter bodies.
    // This is also the function that triggers kernel compilation, GPU memory allocation and
    // upload all the parameters to the GPU.
    RS_populate(S);
    
    // Show some basic info
    printf("%s : Emulating %s frame%s with %s scatter bodies\n",
           now(), commaint(num_pulses), num_pulses>1?"s":"", commaint(S->num_scats));

    // At this point, we are ready to bake
    float dt, fps, prog, eta;
    
    // Some warm up if we are going for real
    if (num_pulses >= 1200) {
        RS_set_prt(S, 1.0f / 60.0f);
        gettimeofday(&t1, NULL);
        for (k = 0; k < warm_up_pulses; k++) {
            gettimeofday(&t2, NULL);
            dt = DTIME(t1, t2);
            if (dt >= 1.0f) {
                t1 = t2;
                fprintf(stderr, "Warming up ... \033[32m%.2f%%\033[0m  \r", (float)k / warm_up_pulses * 100.0f);
            }
            RS_advance_time(S);
        }
    }

    // Set PRT to the actual one
    RS_set_prt(S, prt);

    // ---------------------------------------------------------------------------------------------------------------
    
    gettimeofday(&t1, NULL);
    
    // Allocate a pulse cache
    IQPulseHeader *pulse_headers = (IQPulseHeader *)malloc(num_pulses * sizeof(IQPulseHeader));
    cl_float4 *pulse_cache = (cl_float4 *)malloc(num_pulses * S->params.range_count * sizeof(cl_float4));
    memset(pulse_headers, 0, num_pulses * sizeof(IQPulseHeader));
    memset(pulse_cache, 0, num_pulses * S->params.range_count * sizeof(cl_float4));

    // Now we bake
    int k0 = 0;
    for (k = 0; k<num_pulses; k++) {
        gettimeofday(&t2, NULL);
        dt = DTIME(t1, t2);
        if (dt >= 0.25f) {
            t1 = t2;
            prog =  (float)k / num_pulses * 100.0f;
            if (k > 3) {
                fps = 0.5f * fps + 0.5f * (float)(k - k0) / dt;
            } else {
                fps = (float)(k - k0) / dt;
            }
            eta = (float)(num_pulses - k) / fps;
            k0 = k;
            fprintf(stderr, "k %5d   e%6.2f, a%5.2f   %.2f fps  \033[1;33m%.2f%%\033[0m   eta %.0f second%s   \r", k, scan.el, scan.az, fps, prog, eta, eta > 1.5f ? "s" : "");
        }
        RS_set_beam_pos(S, scan.az, scan.el);
        RS_make_pulse(S);
        RS_advance_time(S);

        // Only download the necessary data
        if (verb > 2) {
            RS_download(S);

            RS_show_scat_sig(S);
    
            printf("signal:\n");
            for (int r = 0; r < S->params.range_count; r++) {
                printf("sig[%d] = (%.4f %.4f %.4f %.4f)\n", r, S->pulse[r].s0, S->pulse[r].s1, S->pulse[r].s2, S->pulse[r].s3);
            }
            printf("\n");
        } else if (output_file) {
            RS_download_pulse_only(S);
        }

        // Gather information for the  pulse header
        if (output_file) {
            pulse_headers[k].time = S->sim_time;
            pulse_headers[k].az_deg = scan.az;
            pulse_headers[k].el_deg = scan.el;
            memcpy(&pulse_cache[k * S->params.range_count], S->pulse, S->params.range_count * sizeof(cl_float4));
        }

        // Update scan angles for the next pulse
        get_next_scan_angles(&scan);
    }
    
    // Clear the last line and beep five times
    fprintf(stderr, "%120s\r", "");
    if (!quiet_mode) {
        #if defined (__APPLE__)
        system("say -v Bells dong dong dong dong &");
        #else
        fprintf(stderr, "\a\a\a\a\a");
        #endif
    }
    
    gettimeofday(&t2, NULL);
    dt = DTIME(t0, t2);
    printf("%s : Finished.  Total time elapsed = %.2f s\n", now(), dt);
    
    if (verb > 2) {
        RS_download(S);
        printf("%s : Final scatter body positions, velocities and orientations:\n", now());
        RS_show_scat_pos(S);
        RS_show_scat_sig(S);
    }

    if (output_file) {
        // Initialize a file if the user wants an output file
        FILE *fid = NULL;
        IQFileHeader file_header;
        memset(&file_header, 0, sizeof(IQFileHeader));
        
        file_header.params = S->params;
        for (k = 0; k < S->num_body_types; k++) {
            file_header.debris_population[k] = (uint32_t)S->debris_population[k];
        }
        snprintf(file_header.scan_mode, sizeof(file_header.scan_mode), "%s", scan_mode_str(scan.mode));
        file_header.scan_start = scan.start;
        file_header.scan_end   = scan.end;
        file_header.scan_delta = scan.delta;
        
        if (output_file) {
            char filename[4096];
            memset(filename, 0, 4096);
            snprintf(filename, 256, "%s/Downloads/sim-%s-%s%04.1f.iq",
                     getenv("HOME"),
                     nowlong(),
                     scan.mode == SCAN_MODE_PPI ? "E": (scan.mode == SCAN_MODE_RHI ? "A" : "S"),
                     scan.mode == SCAN_MODE_PPI ? scan.el: (scan.mode == SCAN_MODE_RHI ? scan.az : (float)num_pulses));
            printf("%s : Output file : \033[1;32m%s\033[0m\n", now(), filename);
            fid = fopen(filename, "wb");
            if (fid == NULL) {
                fprintf(stderr, "%s : Error creating file for writing data.\n", now());
                output_file = FALSE;
            }
            // For now, we simply write a 4K header. Will populate with more contents next time
            fwrite(&file_header, sizeof(IQFileHeader), 1, fid);
        }

        // Flush out the cache
        for (k = 0; k < num_pulses; k++) {
            fwrite(&pulse_headers[k], sizeof(IQPulseHeader), 1, fid);
            fwrite(&pulse_cache[k * S->params.range_count], sizeof(cl_float4), S->params.range_count, fid);
        }
        printf("%s : Data file with %s bytes.\n", now(), commaint(ftell(fid)));
        fclose(fid);
    }
    
    free(pulse_headers);
    free(pulse_cache);
    
    printf("%s : Session ended\n", now());

    RS_free(S);
    
    LES_free(L);
    
    ADM_free(A);
    
    RCS_free(R);
    
    //ARPS_free(O);
    
    return EXIT_SUCCESS;
}
