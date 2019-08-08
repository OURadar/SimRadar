#include "rs.h"
#include <stdbool.h>
#include <getopt.h>
#include <dirent.h>
#include <errno.h>

#define CL_SILENCE_DEPRECATION    (1)

#define ITALIC(x)                 "\033[3m" x "\033[23m"
#define UNDERLINE(x)              "\033[4m" x "\033[24m"
#define HIGHLIGHT(x)              "\033[38;5;82;48;5;238m" x "\033[0m"
#define UNDERLINE_ITALIC(x)       "\033[3;4m" x "\033[23;24m"

#define FMT                       "%30s  %8.4f ms\n"
#define FMT2                      "%30s  %8.4f ms   %6.2f GB/s\n"

#

enum {
    TEST_N0NE                   = 0,
    TEST_ADVANCE_TIME_GPU       = 1,
    TEST_MAKE_PULSE_GPU         = 1 << 1,
    TEST_MAKE_PULSE_GPU_PASS_1  = 1 << 2,
    TEST_MAKE_PULSE_GPU_PASS_2  = 1 << 3,
    TEST_DOWNLOAD               = 1 << 4,
    TEST_IO                     = 1 << 5,
    TEST_DUMMY                  = 1 << 6,
    TEST_SIG_AUX                = 1 << 7,
    TEST_BG_ATTS                = 1 << 8,
    TEST_EL_ATTS                = 1 << 9,
    TEST_DB_ATTS                = 1 << 10,
    TEST_KERNEL_MASK            = (TEST_BG_ATTS | TEST_EL_ATTS | TEST_DB_ATTS | TEST_SIG_AUX | TEST_MAKE_PULSE_GPU_PASS_1 | TEST_MAKE_PULSE_GPU_PASS_2),
    TEST_SIMPLE                 = (TEST_ADVANCE_TIME_GPU | TEST_MAKE_PULSE_GPU | TEST_DOWNLOAD | TEST_IO),
    TEST_ALL                    = (TEST_SIMPLE | TEST_KERNEL_MASK),
};

#pragma mark - Local Functions

static void cl_kernel_test_by_flags(const uint32_t flag, const uint32_t verb) {
    float density = 0.0f;
    unsigned int N = 0;
    
    struct timeval t1, t2;

    if (flag & TEST_ALL && N == 0) {
        N = 100;
    }
    
    int i;
    double dt;
    size_t byte_size;
    
    RSHandle *H = RS_init_verbose(verb);
    if (H == NULL) {
        fprintf(stderr, "%s : Some errors occurred.\n", now());
        return;
    }
    
    if (density > 0) {
        RS_set_density(H, density);
    }
    
    RS_set_dsd_to_mp(H);
    
    RS_add_debris(H, OBJConfigLeaf, 100 * 1024);
    
    RS_revise_debris_counts_to_gpu_preference(H);
    
    RS_show_radar_params(H);
    
    RS_populate(H);
    
    printf("\nTest(s) using %s meteorological scatterers and %s debris objects for %s iterations:\n\n",
           commaint(H->counts[0]), commaint(H->counts[1]), commaint(N));
    
    RS_advance_time(H);
    
    if (flag & TEST_SIMPLE) {
        printf("Framework functions:\n\n");
    }
    
    //
    // RS_io_test()
    //
    if (flag & TEST_IO) {
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
    if (flag & TEST_ADVANCE_TIME_GPU) {
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
    if (flag & TEST_MAKE_PULSE_GPU) {
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
    if (flag & TEST_DOWNLOAD) {
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
    if (flag & TEST_KERNEL_MASK) {
        printf("\nInternal kernel functions:\n\n");
    }
    
    //
    //  make_pulse_pass_1
    //
    if (flag & TEST_MAKE_PULSE_GPU_PASS_1) {
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
    if (flag & TEST_MAKE_PULSE_GPU_PASS_2) {
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
    //  bg_atts
    //
    if (flag & TEST_BG_ATTS) {
        byte_size = 4 * H->counts[0] * sizeof(cl_float4);
        gettimeofday(&t1, NULL);
        for (i=0; i<N; i++) {
            clEnqueueNDRangeKernel(H->workers[0].que,
                                   H->workers[0].kern_bg_atts,
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
        printf(FMT2, "bg_atts", 1.0e3f * dt, 1.0e-9f * byte_size / dt);
    }

    //
    //  el_atts
    //
    if (flag & TEST_EL_ATTS) {
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
    //  db_atts
    //
    if (flag & TEST_DB_ATTS) {
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
    //  scat_sig_aux
    //
    if (flag & TEST_SIG_AUX) {
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
}

static void test_LES() {
    printf("Testing LES table reading ...\n");
    
    LESTable *table;
    
    LESHandle L = LES_init_with_config_path("flat", NULL);
    
    if (L == NULL) {
        fprintf(stderr, "Error. Unable to initialize an LES handle.\n");
        return;
    }
    
    LES_show_handle_summary(L);
    
    table = LES_get_frame(L, 0);
    LES_show_table_summary(table);
    
    table = LES_get_frame(L, 9);
    LES_show_table_summary(table);
    
    LES_free(L);
}

static void test_ADM() {
    printf("Testing ADM table reading ...\n");
    
    ADMTable *table;
    
    ADMHandle *A = ADM_init();
    
    if (A == NULL) {
        fprintf(stderr, "Error. Unable to initialize an ADM handle.\n");
        return;
    }
    
    table = ADM_get_table(A, ADMConfigModelPlate);
    ADM_show_table_summary(table);
    
    ADM_free(A);
}

static void test_RCS() {
    printf("Testing RCS table reading ...\n");
    
    RCSTable *table;
    
    RCSHandle *R = RCS_init();
    
    if (R == NULL) {
        fprintf(stderr, "Error. Unable to initialize an RCS handle.\n");
        return;
    }
    
    printf("\nLeaf:\n\n");
    table = RCS_get_table(R, RCSConfigLeaf);
    RCS_show_table_summary(table);
    
    printf("\nWoodboard:\n\n");
    table = RCS_get_table(R, RCSConfigWoodBoard);
    RCS_show_table_summary(table);
    
    printf("\nBrick:\n\n");
    table = RCS_get_table(R, RCSConfigBrick);
    RCS_show_table_summary(table);
    
    RCS_free(R);
}

static void set_debris_flux_field_to_test(RSHandle *H) {
    // CDF: 3 x 3 flux field with a middle cell at 1.0 (cell 4)
    //
    //  1.0  |         o o o o
    //       |         | | | |
    //  0.0  o-o-o-o-o-+-+-+-+---> cell index
    //       0 1 2 3 4 5 6 7 8
    //
    // iCDF should be:
    //
    //        1.0  |                   (This point does not exist in the table
    //             |                    but it is assumed in this convention)
    //    5/count  |      ...  o
    //    4/count  o  ...      |
    //             |           |
    //             +-----------+--> v
    //             0    ...   1.0
    //
    //     iCDF = [4 4.1 4.2 ... 5]
    //
    printf("Debris flux field test.\n");

    int k;
    
    // Desired CDF inverse table size
    const int n = 128;
    
    // Some constants for the derived CDF
    const int pdf_count = 9;
    const int cdf_count = pdf_count + 1;
    double *pdf = (double *)malloc(pdf_count * sizeof(double));
    double *cdf = (double *)malloc(cdf_count * sizeof(double));
    
    // Psuedo-PDF, not yet normalized
    for (k = 0; k < pdf_count; k++) {
        pdf[k] = 0.0;
    }
    pdf[0] = 100.0;
    pdf[2] = 100.0;
    pdf[4] = 100.0;
    pdf[6] = 100.0;
    pdf[8] = 100.0;
    
    //    pdf[1] = 100.0;
    //    pdf[3] = 100.0;
    //    pdf[5] = 100.0;
    //    pdf[7] = 100.0;
    
    // Actual PDF after normalization
    double sum = 0.0;
    for (k = 0; k < pdf_count; k++) {
        sum += pdf[k];
    }
    for (k = 0; k < pdf_count; k++) {
        pdf[k] /= sum;
    }
    
    // The corresponding CDF
    double cumsum = 0.0;
    for (k = 0; k < pdf_count; k++) {
        cdf[k] = cumsum;
        cumsum += pdf[k];
    }
    cdf[k] = 1.0;
    for (k = 0; k < pdf_count; k++) {
        printf("cdf[%d] = %.15f    pdf[%d] = %.15f\n", k, cdf[k], k, pdf[k]);
    }
    printf("cdf[%d] = %.15f\n", k, cdf[k]);
    
    float *tab = (float *)malloc(n * sizeof(float));
    
    int b = 0, e;
    float vl, vh, a, x;
    
    // Derive the CDF inverse lookup table
    for (k = 0; k < n; k++) {
        x = (float)k / (n - 1);
        b = MAX(b - 1, 0);
        while (cdf[b] <= x && b < cdf_count) {
            b++;
        }
        b = MAX(b - 1, 0);
        e = MIN(b + 1, pdf_count);
        if (cdf[b] == cdf[e]) {
            //#if defined(DEBUG_CDF)
            printf("roll back   (b, e) = (%d, %d)   x = %.2f   cdf[b] = %.2f -> %s\n", b, e, x, cdf[b], cdf[b] >= x ? "Y" : "N");
            //#endif
            while (cdf[b] >= x && b > 0) {
                b--;
            }
            e = MIN(b + 1, pdf_count);
            //#if defined(DEBUG_CDF)
            printf("      -->   (b, e) = (%d, %d)\n", b, e);
            //#endif
        }
        // Gather the two points for linear interpolation
        vl = (float)b;
        vh = (float)e;
        if (b == e) {
            tab[k] = vl;
        } else {
            a = (x - cdf[b]) / (cdf[e] - cdf[b]);
            if (cdf[b] <= x && x <= cdf[e]) {
                tab[k] =  vl + a * (vh - vl);
            } else {
                rsprint("ERROR. Unable to continue. I need upgrades. Tell my father.  (b, e) = (%d, %d)  x = %.2f\n", b, e, x);
                return;
            }
        }
        printf("k = %3d   (b, e) = (%d, %d)   x = [%.4f, (%.4f), %.4f]   v = [%.4f, (%.4f), %.4f]\n", k, b, e, cdf[b], x, cdf[e], vl, tab[k], vh);
    }
    
    free(pdf);
    free(cdf);
    free(tab);
}

#pragma mark -

static void test_by_number(const int number, const void *arg) {
    int verb = 0;
    switch (number) {
        case 0:
            verb = *(int *)arg;
            cl_kernel_test_by_flags(TEST_SIMPLE, verb);
            break;
        case 1:
            verb = *(int *)arg;
            cl_kernel_test_by_flags(TEST_KERNEL_MASK, verb);
            break;
        case 2:
            verb = *(int *)arg;
            cl_kernel_test_by_flags(TEST_ALL, verb);
            break;
        case 3:
            test_LES();
            break;
        case 4:
            test_ADM();
            break;
        case 5:
            test_RCS();
            break;
        case 6:
            set_debris_flux_field_to_test(NULL);
            break;
        case 11:
            cl_kernel_test_by_flags(TEST_IO, verb);
            break;
        case 12:
            cl_kernel_test_by_flags(TEST_ADVANCE_TIME_GPU, verb);
            break;
        case 13:
            cl_kernel_test_by_flags(TEST_MAKE_PULSE_GPU, verb);
            break;
        case 14:
            cl_kernel_test_by_flags(TEST_MAKE_PULSE_GPU_PASS_1, verb);
            break;
        case 15:
            cl_kernel_test_by_flags(TEST_MAKE_PULSE_GPU_PASS_2, verb);
            break;
        case 16:
            cl_kernel_test_by_flags(TEST_EL_ATTS, verb);
            break;
        case 17:
            cl_kernel_test_by_flags(TEST_DB_ATTS, verb);
            break;
        case 18:
            cl_kernel_test_by_flags(TEST_SIG_AUX, verb);
            break;
        default:
            printf("Test %d is invalid.\n", number);
            break;
    }
}

static char *test_by_number_description(const int indent) {
    static char text[4096];
    char helpText[] =
    " 0 - Primary framework kernels\n"
    " 1 - Secondary framework kernels\n"
    " 2 - Both primary and secondary framework kernels (0 + 1)\n"
    " 3 - LES module\n"
    " 4 - ADM module\n"
    " 5 - RCS module\n"
    " 6 - Debris flux field derivation\n"
    "\n"
    "Tests 11 - 18 are performance tests on specific CL kernels:\n"
    "\n"
    "11 - RS_io_test()\n"
    "12 - RS_advanced_time()\n"
    "13 - RS_make_pulse()\n"
    "14 - RS_make_pulse_pass_1()\n"
    "15 - RS_make_pulse_pass_2()\n"
    "16 - RS_el_atts()\n"
    "17 - RS_db_atts()\n"
    "18 - scat_sig_aux()\n"
    "\n";
    RS_indent_copy(text, helpText, indent);
    if (strlen(text) > 3000) {
        fprintf(stderr, "Warning. Approaching limit. (%lu)\n", strlen(text));
    }
    return text;
}

#pragma mark -

static void show_help() {
    char name[] = __FILE__;
    *strrchr(name, '.') = '\0';
    printf("SimRadar Utility\n\n"
           "%s [options]\n\n"
           "OPTIONS:\n"
           "     Unless explicitly stated, all options are interpreted in sequence. Some\n"
           "     options can be specified multiples times for repetitions. For example, the\n"
           "     verbosity is increased by repeating the option multiple times.\n"
           "\n"
           "  -h (--help)\n"
           "         Shows this help text.\n"
           "\n"
           "  -t (--test) " UNDERLINE("value") "\n"
           "         Tests a specific component of the SimRadar framework.\n"
           "\n"
           "%s"
           "\n"
           "  -v (--verbose)\n"
           "         Increases verbosity level.\n"
           "\n"
           "\n\n"
           "%s (SimRadar %s)\n\n",
           name,
           test_by_number_description(9),
           name,
           RS_version_string());
}

#pragma mark - Main

//
//
//  M A I N
//
//

int main(int argc, const char **argv) {
    int k, s;
    int verbose = 0;
    char str[1024];
    char name[] = __FILE__;
    *strrchr(name, '.') = '\0';

    // Command line options
    struct option long_options[] = {
        {"alarm"             , no_argument      , NULL, 'A'},    // ASCII 65 - 90 : A - Z
        {"help"              , no_argument      , NULL, 'h'},
        {"test"              , required_argument, NULL, 't'},
        {"verbose"           , no_argument,       NULL, 'v'},
        {0, 0, 0, 0}
    };

    // Go through the options
    s = 0;
    for (k = 0; k < sizeof(long_options) / sizeof(struct option); k++) {
        struct option *o = &long_options[k];
        s += snprintf(str + s, 1023 - s, "%c%s", o->val, o->has_arg == required_argument ? ":" : (o->has_arg == optional_argument ? "::" : ""));
    }
    optind = 1;
    int opt, long_index = 0;
    while ((opt = getopt_long(argc, (char * const *)argv, str, long_options, &long_index)) != -1) {
        switch (opt) {
            case 'A':
                break;
            case 'h':
                show_help();
                exit(EXIT_SUCCESS);
            case 't':
                // A bunch of different tests
                k = atoi(optarg);
                test_by_number(k, argc == optind ? (char *)&verbose : argv[optind]);
                exit(EXIT_SUCCESS);
                break;
            case 'v':
                verbose++;
                break;
            default:
                break;
        }
    }
    printf("Don't want to do anything?\n");
    return 0;
}
