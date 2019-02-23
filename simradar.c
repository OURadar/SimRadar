//
//  simradar.c
//  SimRadar
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
//  Created by Boonleng Cheong.
//
//

#include "rs.h"
#include "iq.h"
#include <stdbool.h>
#include <getopt.h>
#include <dirent.h>
#include <errno.h>

#define MAX_FILELIST                65536

#if defined (_OPEN_MPI)
#include <mpi.h>
#endif

enum ACCEL_TYPE {
    ACCEL_TYPE_GPU,
    ACCEL_TYPE_CPU
};

typedef struct user_params {
    RSSimulationConcept concept;
    POSPattern scan_pattern;

    float beamwidth;
    float density;
    float lambda;
    float prt;
    float pw;
    float dsd_sizes[100];

    int   num_pulses;
    int   warm_up_pulses;
    int   seed;
    int   dsd_count;

    int   debris_type[RS_MAX_DEBRIS_TYPES];
    int   debris_count[RS_MAX_DEBRIS_TYPES];
    int   debris_group_count;
    
    char  les_config[256];

    bool  output_iq_file;
    bool  output_state_file;
    bool  preview_only;
    bool  quiet_mode;
    bool  skip_questions;
    bool  tight_box;
    bool  show_progress;
    bool  resume_seed;

    char output_dir[1024];
} UserParams;

typedef union simstate {
    char raw[63 * 1024];
    RSHandle master;
} SimState;

//
//   s h o w _ h e l p
//
#define PROGNAME      "simradar"

void show_help() {
    int k;
    int size = 10 * 1024;
    char *buff = (char *)malloc(size);
    k = sprintf(buff, "SimRadar\n\n"
           PROGNAME " [options]\n\n"
           "OPTIONS\n"
           "     Unless specifically stated, all options are interpreted in sequence. Some\n"
           "     options can be specified multiples times for repetitions. For example, the\n"
           "     debris particle count is set for each type sequentially by repeating the\n"
           "     option multiple times for each debris type.\n"
           "\n"
           "  --alarm\n"
           "         Make an alarm when the simulation is complete.\n"
           "\n"
           "  -c (--concept) " UNDERLINE("concepts") "\n"
           "         Sets the simulation concepts to be used, which are OR together for\n"
           "         multiple values that can be combined together.\n"
           "            B - Bounded particle velocity.\n"
           "            D - Dragged background.\n"
           "            F - Fixed scatterer position.\n"
           "            T - Transparent background.\n"
           "            U - Uniform rain drop size density with scaled RCS.\n"
           "            V - Vertically pointed radar (profiler)\n"
           "         Examples:\n"
           "            --concept DU\n"
           "                sets simulation to use the concept of dragged background and\n"
           "                uniform density of rain drop size.\n"
           "            --concept B\n"
           "                sets simulation to use the concept of bounded particle velocity\n"
           "                but left the others as default.\n"
           "\n"
           "  -d (--debris) " UNDERLINE("type") "," UNDERLINE("count") "\n"
           "         Adds debris of " UNDERLINE("type") " with population of " UNDERLINE("count") ".\n"
           "         When is option is specified multiple times, multiple debris types will\n"
           "         be used in the simulator.\n"
           "         Debris type is as follows:\n"
           );
    for (int i = 1; i < OBJConfigCount; i++) {
        k += sprintf(buff + k, "            o  %d - %s\n", i, OBJConfigString(i));
    }
    k += sprintf(buff + k, "\n"
           "  -D (--density) " UNDERLINE("D") "\n"
           "         Set the density of particles to " UNDERLINE("D") " scatterers per resolution volume\n"
           "\n"
           "  --dontask\n"
           "         Sets the program to skip all the confirmation questions.\n"
           "\n"
           "  -f " UNDERLINE("count") "\n"
           "         Sets the number of frames to " UNDERLINE("count") ". This option is identical -p.\n"
           "         See -p for more information.\n"
           "\n"
           "  -l (--lambda) " UNDERLINE("wavelength") "\n"
           "         Sets the radar wavelength to " UNDERLINE("wavelength") " meters. Framework default value\n"
           "         is 0.10 m if this is not specified.\n"
           "\n"
           "  -L (--les) " UNDERLINE("LESTable") "\n"
           "         Sets the LES field to use. This is the same string that is used to name\n"
           "         the folder under ${SIMRADAR_TABLE_HOME}/tables/les/${LESTable}. If not\n"
           "         specified, the default LES field is 'suctvort'.\n"
           "\n"
           "  -N (--no-run)\n"
           "         No simulation. Previews the scanning angles of the setup. No data will\n"
           "         be generated.\n"
           "\n"
           "  -o     Sets the program to produce an output file. The filename is derived\n"
           "         based on the current date and time and an output file with name like\n"
           "         sim-20160229-143941-E03.0.iq will be placed in the ~/Downloads folder.\n"
           "\n"
           "  -O (--out-dir) " UNDERLINE("destination") "\n"
           "         Sets the output directory to " UNDERLINE("destination") ". There is no\n"
           "         safe check so the user must make sure it exists.\n"
           "\n"
           "  -p " UNDERLINE("count") "\n"
           "         Sets the number of pulses to " UNDERLINE("count") ". There is no\n"
           "         hard boundaries on which pulse marks the end of a sweep. If user wants\n"
           "         a sweep that contain 2400 pulses, it can be accomplished by setting\n"
           "         sweep mode = P, start = -12, end = +12, delta = 0.01, and combine with\n"
           "         option -p 2400 for a simulation session of 2400 pulses.\n"
           "\n"
           "  --resume-seed\n"
           "         Runs the simulator by resuming the latest seed generated, plus one, by\n"
           "         inspecting the output files with extension .iq in the specified output\n"
           "         directory, if supplied, or the default output directory.\n"
           "\n"
           "  --savestate\n"
           "         Sets the program to generate a simulation state file at the end of the\n"
           "         simulation. An output file like sim-20160229-143941-E03.0.simstate will\n"
           "         be generated in the ~/Downloads folder.\n"
           "\n"
           "  --sweep " UNDERLINE("M:...") "\n"
           "         Sets the beam to scan mode.\n"
           "         The argument " UNDERLINE("M:...") " are parameters for mode, followed\n"
           "         the by scan-specific paramters.\n"
           "            M = P for PPI (plane position indicator) mode\n"
           "            M = R for RHI (range height indicator) mode\n"
           "            M = D for DBS (Doppler beam swinging) mode\n"
           "         For PPI and RHI scans, the scan-specific parameters are expected as:\n"
           "            (P/R):(sweep angle),(start),(end),(delta)\n"
           "         For DBS scans, the scan-specific parameters are expected as:\n"
           "             D:(azimuth),(elevation),(count)\n"
           "         Examples:\n"
           "            --sweep P:3.0,-12:12:0.01\n"
           "                sets the scan mode in PPI, start at elevation 3.0, from azimuth -12 deg\n"
           "                and ends at azimuth +12 deg. The beam position delta is 0.01 deg, which\n"
           "                means the azimuth changes by 0.01 deg at every pulse.\n"
           "            --sweep R:90.0,0.5:12.0:0.02\n"
           "                sets the scan mode in RHI, start at azimuth 90.0 deg, from elevation 0.5-deg\n"
           "                and ends at elevation 12.0 deg. The beam position delta is 0.02 deg, which\n"
           "                means the elevation changes by 0.02 deg at every pulse.\n"
           "            --sweep D:0,75,100/90,75,100/0,90,100\n"
           "                sets the scan mode in DBS, start with beam azimuth 100-deg, elevation\n"
           "                75-deg for 100 pulses, then azimuth 90-deg and elevation 75-deg for\n"
           "                100 pulses, and finally, azimuth 0-deg and elevation 90-deg for 100\n"
           "                pulses. The whole volume repeats indefinitely.\n"
           "\n"
           "  -t " UNDERLINE("period") "\n"
           "         Sets the pulse repetition time to " UNDERLINE("period") " seconds.\n"
           "\n"
           "  -T (--tightbox)\n"
           "         Sets the program to use a tight box, i.e., only simulate from ground to\n"
           "         the scan elevation. Note that framework padding will still be respected.\n"
           "\n"
           "  -W (--warmup) " UNDERLINE("count") "\n"
           "         Sets the warm up stage to use " UNDERLINE("count") " pulses.\n"
           "\n\n"
           "EXAMPLES\n"
           "     The following simulates a vortex and creates a PPI scan data using default\n"
           "     scan parameters. This allows you quickly check if the tools works. An\n"
           "     output file will be generated in the ~/Downloads folder.\n"
           "           " PROGNAME " -o\n"
           "\n"
           "     The following simulates a vortex and creates a PPI scan data using\n"
           "     scan parameter: mode = 'P' (PPI), el = 3.0 deg, start = -12, end = +12,\n"
           "     delta = 0.01, p = 2400 (number of pulses).\n"
           "           " PROGNAME " --sweep P:3.0,-12:12:0.01 -p 2400 -o\n"
           "\n"
           "     The following simulates a vortex and creates an RHI scan data using\n"
           "     scan parameters: mode = 'R' (RHI), az = 1.0 deg, start = 0, end = 12,\n"
           "     delta = 0.01, p = 1200.\n"
           "           " PROGNAME " --sweep R:1.0,0:12:0.01 -p 1200 -o\n"
           "\n"
           "     The following simulates a vortex and creates a PPI scan data using\n"
           "     10,000 debris type #1, which is the leaf.\n"
           "           " PROGNAME " --sweep P:1.0,-12:12:0.01 -p 1200 -d 1,10000 -o\n"
           "\n"
           "     The following simulates a vortex and creates a PPI scan data with\n"
           "     scan parameters: mode = 'P' (PPI), el = 1.0 deg, start = -12, end = +12,\n"
           "     delta = 0.01, PRT = 0.5ms. It would take 4800 pulses to cover the sector\n"
           "     so -p 4800 would complete the sweep.\n"
           "           " PROGNAME " -o -T --sweep P:1.0,-12:12:0.005 -t 0.0005 -p 4800\n"
           "\n"
           "     The following simulates the same as before but loads the domain with 10^5\n"
           "     debris objects\n"
           "           " PROGNAME " -o --concept DBU -T --sweep P:1.0,-12:12:0.005 -t 0.0005 -p 4800 -d 1,10000\n"
           "\n"
           "     The following simulates the same as before but use the LES field 'suctvort_large'\n"
           "     debris objects\n"
           "           " PROGNAME " -o --concept DBU -T -L suctvort_large --sweep P:1.0,-12:12:0.005 -t 0.0005 -p 4800 -d 1,10000\n"
           "\n"
           "     The following simulates a profiling radar by specifying the concept option '-c FV'\n"
           "     for fixed scatterer position and vertically pointing radar. The LES field is 'flat'.\n"
           "     The scan pattern is a DBS. Starting at azimuth = 0 deg, elevation at 75 deg for 10\n"
           "     pulses, then azimtuh of 90 deg, elevation 75 deg for 10 pulses and finally azimuth\n"
           "     at 0 deg, elevation 0 deg for 10 pulses. Total of 60 pulses with a PRT of 0.01 s.\n"
           "     The scan repeats itself every 30 seconds.\n"
           "           " PROGNAME " -o -c FV -L flat --sweep D:0,75,10/90,75,10/0,90,10 -t 0.01 -p 60 -N\n"
           );
    printf("%s\n(%.1f)\n", buff, (float)k / size * 100.0f);
    free(buff);
}

enum ValueType {
    ValueTypeInt,
    ValueTypeFloat,
    ValueTypeChar,
    ValueTypeBool,
    ValueTypeFloatArray,
    ValueTypeNotSupplied
};

#define PARAMS_FLOAT_NOT_SUPPLIED   -999.9f
#define PARAMS_INT_NOT_SUPPLIED     -999

static char * filename_prefix(const UserParams *user) {
    static char filename[768];
    snprintf(filename, sizeof(filename), "%s/sim-%s-%s%04.1f", 
        user->output_dir,
        nowlong(),
        POS_is_ppi(&(user->scan_pattern)) ? "E": (POS_is_rhi(&(user->scan_pattern)) ? "A" : "S"),
        POS_is_ppi(&(user->scan_pattern)) ? user->scan_pattern.sweeps[0].elStart: (POS_is_rhi(&(user->scan_pattern)) ? user->scan_pattern.sweeps[0].azStart : (float)user->num_pulses));
    return filename;
}

static void show_user_param(const char *name, const void* value, const char *unit, const char type, const int count) {
    char str_buf[64] = "not supplied";
    char *value_str = str_buf;
    float *fp;
    int *ip;
    int k;
    switch (type) {
        case ValueTypeInt:
            ip = (int *)value;
            if (*ip == PARAMS_INT_NOT_SUPPLIED) {
                value_str = str_buf;
            } else {
                value_str = commaint(*ip);
            }
            break;
        case ValueTypeFloat:
            fp = (float *)value;
            if (*fp == PARAMS_FLOAT_NOT_SUPPLIED) {
                value_str = str_buf;
            } else {
                value_str = commafloat(*fp);
            }
            break;
        case ValueTypeChar:
            value_str = (char *)value;
            if (strlen(value_str) == 0) {
                value_str = str_buf;
            }
            break;
        case ValueTypeBool:
            if (*(char *)value) {
                strcpy(value_str, "true");
            }
        case ValueTypeFloatArray:
            fp = (float *)value;
            if (count > 0) {
                snprintf(str_buf, 63, "%.2f", fp[0]);
                for (k = 1; k < count; k++) {
                    snprintf(str_buf + strlen(str_buf), 63 - strlen(str_buf), ", %.2f", fp[k]);
                }
                snprintf(str_buf + strlen(str_buf), 63 - strlen(str_buf), " %s", unit);
            }
        default:
            value_str = str_buf;
            break;
    }
    if (type == ValueTypeBool && *(char *)value == true) {
        printf("  %-25s\n", name);
    } else {
        printf("  %-25s = %s %s\n", name, value_str, value_str == str_buf ? "" : unit);
    }
}

static void write_iq_file(const UserParams user, const IQFileHeader *file_header, const IQPulseHeader *pulse_headers, const cl_float4 *pulse_cache, const int stride, const int offset) {
    char charbuff[2048];

    memset(charbuff, 0, sizeof(charbuff));
    // snprintf(charbuff, sizeof(charbuff), "%s/sim-%s-%s%04.1f.iq",
    //          user.output_dir,
    //          nowlongoffset(offset),
    //          POS_is_ppi(&user.scan_pattern) ? "E": (POS_is_rhi(&user.scan_pattern) ? "A" : "S"),
    //          POS_is_ppi(&user.scan_pattern) ? user.scan_pattern.sweeps[0].elStart : (POS_is_rhi(&user.scan_pattern) ? user.scan_pattern.sweeps[0].azStart : (float)user.num_pulses));
    snprintf(charbuff, sizeof(charbuff), "%s.iq", filename_prefix(&user));
    printf("%s : Output file : " UNDERLINE("%s") "\n", now(), charbuff);
    FILE *fid = fopen(charbuff, "wb");
    if (fid == NULL) {
        fprintf(stderr, "%s : Error creating file for IQ data.\n", now());
    }
    fwrite(file_header, sizeof(IQFileHeader), 1, fid);

    // Flush out the cache
    for (int k = 0; k < user.num_pulses; k++) {
        fwrite(&pulse_headers[k], sizeof(IQPulseHeader), 1, fid);
        fwrite(&pulse_cache[k * stride], sizeof(cl_float4), stride, fid);
    }
    printf("%s : Data file with %s B (seed = %s).\n", now(), commaint(ftell(fid)), commaint(file_header->simulation_seed));
    printf("%s : Samples = %.4e%+.4ei  %.4e%+.4ei ...\n", now(), pulse_cache[0].s0, pulse_cache[0].s1, pulse_cache[1].s0, pulse_cache[1].s1);
    fclose(fid);
}

int cstring_cmp(const void *a, const void *b)
{
    const char **ia = (const char **)a;
    const char **ib = (const char **)b;
    return strcmp(*ia, *ib);
}

int get_last_seed(const char *output_dir) {
    int k;
    char path[1024];
    struct dirent *dir;
    struct stat file_stat;
    
    DIR *d;
    char filename[1024];
    char *filelist[MAX_FILELIST];
    
    FILE *f;
    
    IQFileHeader file_header;
    
    // Copy path and truncate the last path delimeter
    strncpy(path, output_dir, 1023);
    if (path[strlen(path) - 1] == '/') {
        path[strlen(path) - 1] = '\0';
    }
    
    d = opendir(path);
    if (d == NULL) {
        fprintf(stderr, "Directory does not exists.\n");
        return EXIT_FAILURE;
    }

    k = 0;
    while ((dir = readdir(d)) != NULL) {
        if (strlen(dir->d_name) < 3 || strstr(dir->d_name, ".iq") == NULL) {
            continue;
        }
        filelist[k] = (char *)malloc(strlen(dir->d_name) + 1);
        strcpy(filelist[k], dir->d_name);
        k++;
        if (k > MAX_FILELIST) {
            fprintf(stderr, "Too many files in the directory.\n");
            return EXIT_FAILURE;
        }
    }

    closedir(d);

    if (k == 0) {
        printf("No files.\n");
        return 0;
    }

    // Sort the file based on names
    qsort(filelist, k, sizeof(char *), cstring_cmp);

    // Pick the last file
    sprintf(filename, "%s/%s", path, filelist[k - 1]);
    if (stat(filename, &file_stat) < 0) {
        printf("%s\n", strerror(errno));
    }
    f = fopen(filename, "r+");
    fread(&file_header, sizeof(file_header), 1, f);
    fclose(f);

    // Free the filelist
    while (k > 0) {
        k--;
        free(filelist[k]);
    }
    
    return file_header.simulation_seed;
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
    char charbuff[4096];
    FILE *fid = NULL;

    // A structure unit that encapsulates command line user parameters
    UserParams user;
    memset(&user, 0, sizeof(UserParams));

    user.concept           = RSSimulationConceptNull;

    user.beamwidth         = PARAMS_FLOAT_NOT_SUPPLIED;
    user.density           = PARAMS_FLOAT_NOT_SUPPLIED;
    user.lambda            = PARAMS_FLOAT_NOT_SUPPLIED;
    user.prt               = PARAMS_FLOAT_NOT_SUPPLIED;
    user.pw                = PARAMS_FLOAT_NOT_SUPPLIED;
    user.dsd_count         = 0;

    user.seed              = PARAMS_INT_NOT_SUPPLIED;
    user.num_pulses        = PARAMS_INT_NOT_SUPPLIED;
    user.warm_up_pulses    = PARAMS_INT_NOT_SUPPLIED;

    user.output_iq_file    = false;
    user.output_state_file = false;
    user.preview_only      = false;
    user.quiet_mode        = true;
    user.skip_questions    = false;
    user.show_progress     = true;
    user.tight_box         = false;
    user.resume_seed       = false;

    user.output_dir[0]     = '\0';

    struct timeval t0, t1, t2;

    gettimeofday(&t0, NULL);


    IQFileHeader file_header;
    memset(&file_header, 0, sizeof(IQFileHeader));
    
    // ---------------------------------------------------------------------------------------------------------------

    static struct option long_options[] = {
        {"alarm"         , no_argument      , 0, 'A'}, // ASCII 65 - 90 : A - Z
        {"cpu"           , no_argument      , 0, 'C'},
        {"density"       , required_argument, 0, 'D'},
        {"savestate"     , no_argument      , 0, 'E'},
        {"no-progress"   , no_argument      , 0, 'F'},
        {"mpdsd"         , required_argument, 0, 'G'},
        {"resume-seed"   , no_argument      , 0, 'H'},
        {"les"           , required_argument, 0, 'L'},
        {"no-run"        , no_argument      , 0, 'N'},
        {"out-dir"       , required_argument, 0, 'O'},
        {"sweep"         , required_argument, 0, 'S'},
        {"tightbox"      , no_argument      , 0, 'T'},
        {"warmup"        , required_argument, 0, 'W'},
        {"concept"       , required_argument, 0, 'c'}, // ASCII 97 - 122 : a - z
        {"debris"        , required_argument, 0, 'd'},
        {"help"          , no_argument      , 0, 'h'},
        {"gpu"           , no_argument      , 0, 'g'},
        {"frames"        , required_argument, 0, 'f'},
        {"lambda"        , required_argument, 0, 'l'},
        {"output"        , no_argument      , 0, 'o'},
        {"pulses"        , required_argument, 0, 'p'},
        {"seed"          , required_argument, 0, 's'},
        {"prt"           , required_argument, 0, 't'},
        {"pulsewidth"    , required_argument, 0, 'w'},
        {"quiet"         , no_argument      , 0, 'q'},
        {"verbose"       , no_argument      , 0, 'v'},
        {"dont-ask"      , no_argument      , 0, 'y'},
        {0, 0, 0, 0}
    };
    
    // Construct short_options from long_options
    char str[1024] = "";
    for (k = 0; k < sizeof(long_options) / sizeof(struct option); k++) {
        struct option *o = &long_options[k];
        snprintf(str + strlen(str), 1024, "%c%s", o->val, o->has_arg == required_argument ? ":" : (o->has_arg == optional_argument ? "::" : ""));
    }
    //printf("str = '%s'\n", str);

    uint32_t u1, u2;
    char c1, *pc1, *pc2;
    // Process the input arguments and set the simulator parameters
    int opt, long_index = 0;
    while ((opt = getopt_long(argc, argv, str, long_options, &long_index)) != -1) {
        switch (opt) {
            case 'A':
                user.quiet_mode = false;
                break;
            case 'c':
                user.concept = RSSimulationConceptNull;
                if (strcasestr(optarg, "B")) {
                    user.concept |= RSSimulationConceptBoundedParticleVelocity;
                }
                if (strcasestr(optarg, "D")) {
                    user.concept |= RSSimulationConceptDraggedBackground;
                }
                if (strcasestr(optarg, "U")) {
                    user.concept |= RSSimulationConceptUniformDSDScaledRCS;
                }
                if (strcasestr(optarg, "T")) {
                    user.concept |= RSSimulationConceptTransparentBackground;
                }
                if (strcasestr(optarg, "F")) {
                    user.concept |= RSSimulationConceptFixedScattererPosition;
                }
                if (strcasestr(optarg, "V")) {
                    user.concept |= RSSimulationConceptVerticallyPointingRadar;
                }
                break;
            case 'C':
                accel_type = ACCEL_TYPE_CPU;
                break;
            case 'd':
                k = sscanf(optarg, "%d,%d", &u1, &u2);
                if (k == 2) {
                    if (u1 < 1 || u1 >= OBJConfigCount) {
                        fprintf(stderr, "Debris type %d is invalid.\n", u1);
                        exit(EXIT_FAILURE);
                    }
                    user.debris_type[user.debris_group_count] = u1;
                    user.debris_count[user.debris_group_count] = u2;
                    user.debris_group_count++;
                } else {
                    fprintf(stderr, "Each debris group should be specified as -dTYPE,COUNT without space before or after comma.\n");
                    exit(EXIT_FAILURE);
                    break;
                }
                //debris_count[debris_types++] = atoi(optarg);
                break;
            case 'D':
                user.density = atof(optarg);
                break;
            case 'E':
                user.output_state_file = true;
                break;
            case 'f':
                user.num_pulses = atoi(optarg);
                break;
            case 'F':
                user.show_progress = false;
                break;
            case 'g':
                accel_type = ACCEL_TYPE_GPU;
                break;
            case 'G':
                //k = sscanf(optarg, "%c:%f:%f:%f", &c1, &f1, &f2, &f3);
                strcpy(charbuff, optarg);
                k = 0;
                pc2 = optarg - 1;
                do {
                    pc1 = pc2 + 1;
                    user.dsd_sizes[k++] = 1.0e-3f * atof(pc1);
                } while ((pc2 = strstr(pc1, ":")) != NULL);
                user.dsd_count = k;
                if (verb > 2) {
                    for (k = 0; k < user.dsd_count; k++) {
                        printf("k=%d  size=%.2f mm\n", k, 1000.0f * user.dsd_sizes[k]);
                    }
                }
                break;
            case 'h':
                show_help();
                exit(EXIT_SUCCESS);
                break;
            case 'H':
                user.resume_seed = true;
                break;
            case 'l':
                user.lambda = atof(optarg);
                break;
            case 'L':
                strncpy(user.les_config, optarg, sizeof(user.les_config));
                break;
            case 'N':
                user.preview_only = true;
                break;
            case 'o':
                user.output_iq_file = true;
                break;
            case 'O':
                strncpy(user.output_dir, optarg, sizeof(user.output_dir));
                break;
            case 'p':
                user.num_pulses = atoi(optarg);
                break;
            case 'q':
                user.quiet_mode = true;
                break;
            case 's':
                user.seed = atoi(optarg);
                break;
            case 'S':
                POS_parse_from_string(&user.scan_pattern, optarg);
                break;
            case 't':
                user.prt = atof(optarg);
                break;
            case 'T':
                user.tight_box = true;
                break;
            case 'v':
                verb++;
                break;
            case 'w':
                user.pw = atof(optarg);
                break;
            case 'W':
                user.warm_up_pulses = atoi(optarg);
                break;
            case 'y':
                user.skip_questions = true;
                break;
            default:
                exit(EXIT_FAILURE);
                break;
        }
    }

    // ---------------------------------------------------------------------------------------------------------------

#if defined (_OPEN_MPI)

    int world_size, world_rank;
    char processor_name[MPI_MAX_PROCESSOR_NAME];
    MPI_Status status;

    MPI_Init(NULL, NULL);
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);
    MPI_Get_processor_name(processor_name, &k);

    //printf("Node " UNDERLINE("%s") " ( %d out of %d )\n",  processor_name, world_rank, world_size);

    if (user.resume_seed) {
        if (world_rank == 0) {
            user.seed = get_last_seed(user.output_dir) + 1;
            // Distribute the seed to all the other workers
            for (k = 1; k < world_size; k++) {
                MPI_Send(&user.seed, sizeof(user.seed), MPI_BYTE, k, 's', MPI_COMM_WORLD);
            }
        } else {
            MPI_Recv(&user.seed, sizeof(user.seed), MPI_BYTE, 0, 's', MPI_COMM_WORLD, &status);
        }
    }

    if (user.seed != PARAMS_INT_NOT_SUPPLIED) {
        user.seed += world_rank;
    }

#else

    if (user.resume_seed) {
        user.seed = get_last_seed(user.output_dir) + 1;
    }

#endif

    if (verb > 1) {
        printf("----------------------------------------------\n");
        printf("  User parameters:\n");
        printf("----------------------------------------------\n");
        show_user_param("Beamwidth", &user.beamwidth, "deg", ValueTypeFloat, 0);
        show_user_param("TX lambda", &user.lambda, "m", ValueTypeFloat, 0);
        show_user_param("TX pulse width", &user.pw, "s", ValueTypeFloat, 0);
        show_user_param("Number of pulses", &user.num_pulses, "", ValueTypeInt, 0);
        show_user_param("Output directory", user.output_dir, "", ValueTypeChar, 0);
        show_user_param("User random seed", &user.seed, "", ValueTypeInt, 0);
        if (!(user.concept & RSSimulationConceptFixedScattererPosition)) {
            show_user_param("Warm up pulses", &user.warm_up_pulses, "", ValueTypeInt, 0);
            show_user_param("Particle density", &user.density, "", ValueTypeFloat, 0);
            show_user_param("User DSD profile", user.dsd_sizes, "mm", ValueTypeFloatArray, user.dsd_count);
        }
        show_user_param("User LES configuration", user.les_config, "", ValueTypeChar, 0);
        char name[64];
        char type[64];
        for (k = 0; k < user.debris_group_count; k++) {
            sprintf(name, "Debris [%d]", k);
            sprintf(type, "%s @", OBJConfigString(user.debris_type[k]));
            show_user_param(name, type, commaint(user.debris_count[k]), ValueTypeChar, 0);
        }
        printf("----------------------------------------------\n");
    }

    // ---------------------------------------------------------------------------------------------------------------

    // Some assumed parameters if not set
    if (user.concept == RSSimulationConceptNull) {
        user.concept = RSSimulationConceptDraggedBackground
                     | RSSimulationConceptBoundedParticleVelocity
                     | RSSimulationConceptUniformDSDScaledRCS;
    }
    if (POS_is_empty(&user.scan_pattern)) {
        rsprint("Using default scan mode.\n");
        POS_parse_from_string(&user.scan_pattern, "P:3.0,-12:12:0.01");
        if (user.num_pulses < 0) {
            user.num_pulses = 1000;
        }
    }

    // Some conditions that no simulation should be commenced

    if (user.num_pulses < 0) {
        fprintf(stderr, "Error. No number pulses was specified.\n");
        exit(EXIT_FAILURE);
    }
    
    if (sizeof(IQFileHeader) != sizeof(file_header.raw)) {
        fprintf(stderr, "Error. sizeof(IQFileHeader) = %zu  !=  sizeof(file_header.raw) = %zu\n", sizeof(IQFileHeader), sizeof(file_header.raw));
        exit(EXIT_FAILURE);
    }

    if (sizeof(RSHandle) > sizeof(SimState)) {
        fprintf(stderr, "Error. sizeof(RSHandler) = %zu  >  %s\n", sizeof(RSHandle), commaint(sizeof(SimState)));
        exit(EXIT_FAILURE);
    }

    // ---------------------------------------------------------------------------------------------------------------

    // Preview only
    if (user.preview_only) {
        #define FLT_FMT  "\033[1;33m%+6.2f\033[0m"
        printf("Scan mode: \033[1;92m%c\033[0m\n", user.scan_pattern.mode);
        if (user.scan_pattern.mode == 'P' || user.scan_pattern.mode == 'p') {
            for (k = 0; k < user.scan_pattern.sweepCount; k++) {
                printf("    %d   EL: " FLT_FMT " deg   AZ: " FLT_FMT " -- " FLT_FMT " deg    delta: " FLT_FMT " deg\n",
                       k, user.scan_pattern.sweeps[k].elStart, user.scan_pattern.sweeps[k].azStart, user.scan_pattern.sweeps[k].azEnd, user.scan_pattern.sweeps[k].azDelta);
            }
        } else if (user.scan_pattern.mode == 'R' || user.scan_pattern.mode == 'r') {
            printf("    %d   AZ: " FLT_FMT " deg   EL: " FLT_FMT " -- " FLT_FMT " deg    delta: " FLT_FMT " deg\n",
                   k, user.scan_pattern.sweeps[0].azStart, user.scan_pattern.sweeps[0].elStart, user.scan_pattern.sweeps[0].elEnd, user.scan_pattern.sweeps[0].elDelta);
        } else {
            printf("   I need upgrade here.\n");
        }
        for (k = 0; k < user.num_pulses; k++) {
            POS_get_next_angles(&user.scan_pattern);
            printf("k = %4d   el = %6.2f deg   az = %6.2f deg\n", k, user.scan_pattern.el, user.scan_pattern.az);
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
        return EXIT_FAILURE;
    }

#if defined (_OPEN_MPI)

    rsprint("Session initialized on %s (%d / %d / %s)\n", now(), processor_name, world_rank, world_size, commaint(user.seed));

#else

    rsprint("Session initialized\n", now());

#endif

    RS_set_concept(S, user.concept);
    RS_set_scan_pattern(S, &user.scan_pattern);

    // ---------------------------------------------------------------------------------------------------------------

    // Pre-process some parameters to ensure proper logic

    if (user.num_pulses > 1000 && user.output_iq_file == false && user.skip_questions == false) {
        printf("Simulating more than 1,000 pulses but no file will be generated.\n"
               "Do you want to generate an output file instead (Y/N/N) ? ");
        c1 = getchar();
        if (c1 == 'y' || c1 == 'Y') {
            user.output_iq_file = true;
        }
    }

    if (user.warm_up_pulses == PARAMS_INT_NOT_SUPPLIED) {
        if (user.num_pulses > 1000)  {
            user.warm_up_pulses = 2000;
        } else {
            user.warm_up_pulses = 0;
        }
    }
    

    // ---------------------------------------------------------------------------------------------------------------

    // Set user parameters that were supplied
    if (user.beamwidth != PARAMS_FLOAT_NOT_SUPPLIED) {
        RS_set_antenna_params(S, user.beamwidth, 44.5f);
    }

    if (user.density != PARAMS_FLOAT_NOT_SUPPLIED) {
        RS_set_density(S, user.density);
    }

    if (user.pw != PARAMS_FLOAT_NOT_SUPPLIED) {
        RS_set_tx_params(S, user.pw, 50.0e3f);
    }

    if (user.lambda != PARAMS_FLOAT_NOT_SUPPLIED) {
        RS_set_lambda(S, user.lambda);
    }

    if (user.seed != PARAMS_INT_NOT_SUPPLIED) {
        RS_set_random_seed(S, user.seed);
    }

    if (!(S->sim_concept & RSSimulationConceptFixedScattererPosition)) {
        if (user.dsd_count > 0) {
            RS_set_dsd_to_mp_with_sizes(S, user.dsd_sizes, user.dsd_count);
        } else {
            RS_set_dsd_to_mp(S);
        }
    }

    if (strlen(user.les_config)) {
      RS_set_vel_data_to_config(S, user.les_config);
    }

    // ---------------------------------------------------------------------------------------------------------------

#if defined (_OPEN_MPI)

    // Suppress child nodes output after this point for Open MPI runs

    if (world_rank > 0) {
        verb = 0;
        RS_set_verbosity(S, 0);
    }

#endif

    RSBox box = RS_suggest_scan_domain(S);

    // Set debris population
    for (k = 0; k < user.debris_group_count; k++) {
        if (user.debris_count[k]) {
            RS_add_debris(S, user.debris_type[k], user.debris_count[k]);
        }
    }

    if (!POS_is_dbs(&user.scan_pattern)) {
        // Revise the counts so that we use GPU preferred numbers
        RS_revise_debris_counts_to_gpu_preference(S);
    }

    if (user.tight_box) {
        if (POS_is_ppi(&user.scan_pattern)) {
            // No need to go all the way up if we are looking low
            //box.size.e = MIN(box.size.e, scan.el);
            box.size.e = MIN(box.size.e, user.scan_pattern.sweeps[user.scan_pattern.sweepCount - 1].elStart);
        } else if (POS_is_rhi(&user.scan_pattern)) {
            // Need to make sure we cover the very top
            //box.size.e = MAX(scan.start, scan.end);
            box.size.e = MIN(box.size.e, user.scan_pattern.sweeps[user.scan_pattern.sweepCount - 1].elEnd);
        }
    }

    RS_set_scan_box(S,
                    box.origin.r, box.origin.r + box.size.r, 15.0f,                       // Range
                    box.origin.a, box.origin.a + box.size.a, S->params.antenna_bw_deg,    // Azimuth
                    box.origin.e, box.origin.e + box.size.e, S->params.antenna_bw_deg);   // Elevation

    // Save the framework default PRT for later
    if (user.prt == PARAMS_FLOAT_NOT_SUPPLIED) {
        user.prt = S->params.prt;
    } else {
        // Set PRT to the actual one
        // Do not comment out. I know it will be set to 1 / 60 during warm up but show info needs this.
        RS_set_prt(S, user.prt);
    }

    if (verb) {
        RS_show_radar_params(S);
    }

    // Populate the domain with scatter bodies.
    // This is also the function that triggers kernel compilation, GPU memory allocation and
    // upload all the parameters to the GPU.
    RS_populate(S);

    // Show some basic info

#if defined (_OPEN_MPI)

    printf("%s : Emulating %s frame%s with %s scatter bodies on %s\n",
           now(), commaint(user.num_pulses), user.num_pulses > 1 ? "s" : "", commaint(S->num_scats), processor_name);

#else

    printf("%s : Emulating %s frame%s with %s scatter bodies\n",
           now(), commaint(user.num_pulses), user.num_pulses > 1 ? "s" : "", commaint(S->num_scats));

#endif

    // At this point, we are ready to bake
    float dt = 0.1f, fps = 0.0f, prog = 0.0f, eta = 9999999.0f;

    // Some warm up if we are going for real
    setbuf(stdout, NULL);
    if (user.warm_up_pulses > 0) {
        strcpy(charbuff, commaint(user.warm_up_pulses));
        RS_set_prt(S, 1.0f / 60.0f);
        gettimeofday(&t1, NULL);
        for (k = 0; k < user.warm_up_pulses; k++) {
            // Skip computing progress if we are not showing progress
            if (user.show_progress) {
                gettimeofday(&t2, NULL);
                dt = DTIME(t1, t2);
                if (dt >= 0.25f) {
                    t1 = t2;
                    printf("Warming up ... %s out of %s ... \033[32m%.2f%%\033[0m  \r", commaint(k), charbuff, (float)k / user.warm_up_pulses * 100.0f);
                }
            }
            RS_advance_time(S);
        }
        if (user.show_progress) {
            printf("%80s\r", " ");
        }
    }

    // Set PRT to the actual one
    RS_set_prt(S, user.prt);

    // ---------------------------------------------------------------------------------------------------------------

    gettimeofday(&t1, NULL);

    // Allocate a pulse cache
    IQPulseHeader *pulse_headers = (IQPulseHeader *)malloc(user.num_pulses * sizeof(IQPulseHeader));
    cl_float4 *pulse_cache = (cl_float4 *)malloc(user.num_pulses * S->params.range_count * sizeof(cl_float4));
    memset(pulse_headers, 0, user.num_pulses * sizeof(IQPulseHeader));
    memset(pulse_cache, 0, user.num_pulses * S->params.range_count * sizeof(cl_float4));

    // Now we bake
    int k0 = 0;
    for (k = 0; k < user.num_pulses; k++) {
        if (user.show_progress) {
            gettimeofday(&t2, NULL);
            dt = DTIME(t1, t2);
            if (dt >= 0.25f) {
                t1 = t2;
                prog =  (float)k / user.num_pulses * 100.0f;
                if (k > 3) {
                    fps = 0.5f * fps + 0.5f * (float)(k - k0) / dt;
                } else {
                    fps = (float)(k - k0) / dt;
                }
                eta = (float)(user.num_pulses - k) / fps;
                k0 = k;
                if (verb < 2) {
                    printf("k %5d   (e%6.2f, a%5.2f)   %.2f fps   \033[1;33m%.2f%%\033[0m   eta %.0f second%s   \r", k, user.scan_pattern.el, user.scan_pattern.az, fps, prog, eta, eta > 1.5f ? "s" : "");
                 }
            }
        }
        RS_set_beam_pos(S, user.scan_pattern.az, user.scan_pattern.el);
        RS_make_pulse(S);

        // Only download the necessary data
        if (verb > 2) {
            RS_download(S);

            RS_show_scat_sig(S);

            if (verb > 3) { 
                printf("signal:\n");
                if (S->num_workers == 2) {
                    for (int r = 0; r < S->params.range_count; r++) {
                        printf("sig[%2d] = (%10.3e %10.3e %10.3e %10.3e) <- (%10.3e %10.3e %10.3e %10.3e) + (%10.3e %10.3e %10.3e %10.3e)\n",
                               r,
                               S->pulse[r].s0, S->pulse[r].s1, S->pulse[r].s2, S->pulse[r].s3,
                               S->pulse_tmp[0][r].s0, S->pulse_tmp[0][r].s1, S->pulse_tmp[0][r].s2, S->pulse_tmp[0][r].s3,
                               S->pulse_tmp[1][r].s0, S->pulse_tmp[1][r].s1, S->pulse_tmp[1][r].s2, S->pulse_tmp[1][r].s3);
                    }
                } else {
                    for (int r = 0; r < S->params.range_count; r++) {
                        printf("sig[%2d] = (%10.3e %10.3e %10.3e %10.3e) <- (%10.3e %10.3e %10.3e %10.3e)\n",
                               r,
                               S->pulse[r].s0, S->pulse[r].s1, S->pulse[r].s2, S->pulse[r].s3,
                               S->pulse_tmp[0][r].s0, S->pulse_tmp[0][r].s1, S->pulse_tmp[0][r].s2, S->pulse_tmp[0][r].s3);
                    }
                }
                printf("\n");
            }
        } else if (user.output_iq_file) {
            RS_download_pulse_only(S);
        }

        // Gather information for the  pulse header
        if (user.output_iq_file) {
            pulse_headers[k].time = S->sim_tic;
            pulse_headers[k].az_deg = user.scan_pattern.az;
            pulse_headers[k].el_deg = user.scan_pattern.el;
            memcpy(&pulse_cache[k * S->params.range_count], S->pulse, S->params.range_count * sizeof(cl_float4));
        }

        // Advance time
        RS_advance_time(S);

        // Update scan angles for the next pulse
        POS_get_next_angles(&user.scan_pattern);
    }

    // Overall fps
    gettimeofday(&t2, NULL);
    dt = DTIME(t0, t2);
    float acc_fps = user.num_pulses / dt;

    // Clear the last line and beep five times
    fprintf(stderr, "%120s\r", "");
    if (!user.quiet_mode) {
        #if defined (__APPLE__)
        system("say -v Bells dong dong dong dong &");
        #else
        fprintf(stderr, "\a\a\a\a\a");
        #endif
    }

#if defined (_OPEN_MPI)

    printf("%s : Finished on %s.  Total time elapsed = %.2f s  (%.1f FPS / %.1f FPS)\n", now(), processor_name, dt, acc_fps, fps);
    
#else
    
    printf("%s : Finished.  Total time elapsed = %.2f s  (%.1f FPS / %.1f FPS)\n", now(), dt, acc_fps, fps);

#endif
    
    // Download everything once we are all done.
    RS_download(S);

    if (verb > 2) {
        printf("%s : Final scatter body positions, velocities and orientations:\n", now());
        RS_show_scat_pos(S);
    }

    // ---------------------------------------------------------------------------------------------------------------

    // Initialize a file if the user wants output files
    if (user.output_iq_file || user.output_state_file) {
        file_header.params = S->params;
        for (k = 0; k < S->num_types; k++) {
            file_header.counts[k] = (uint32_t)S->counts[k];
        }
        snprintf(file_header.scan_mode, sizeof(file_header.scan_mode), "%c", user.scan_pattern.mode);
        file_header.scan_start      = user.scan_pattern.sweeps[0].azStart;
        file_header.scan_end        = user.scan_pattern.sweeps[0].azEnd;
        file_header.scan_delta      = user.scan_pattern.sweeps[0].azDelta;
        file_header.simulation_seed = S->random_seed;
    }

    if (strlen(user.output_dir) == 0) {
        snprintf(user.output_dir, sizeof(user.output_dir), "%s/Downloads", getenv("HOME"));
    } else {
        size_t len = strlen(user.output_dir);
        if (user.output_dir[len - 1] == '/') {
            user.output_dir[len - 1] = '\0';
        }
        // Check if directory exists
        struct stat dir_stat;
        char os_cmd[1024];
        snprintf(os_cmd, 1024, "mkdir -p \"%s\"", user.output_dir);
        printf("%s : %s\n", now(), os_cmd);
        if (stat(user.output_dir, &dir_stat) < 0) {
            system(os_cmd);
        }
    }
    
    if (user.output_iq_file) {

#if defined (_OPEN_MPI)

        // Let master node do all the file writing to avoid identical filenames
        if (world_rank == 0) {
            int count;
            write_iq_file(user, &file_header, pulse_headers, pulse_cache, S->params.range_count, 0);
            // Collect data from worker nodes
            for (k = 1; k < world_size; k++) {
                MPI_Recv(&file_header, sizeof(IQFileHeader), MPI_BYTE, k, 0, MPI_COMM_WORLD, &status);
                if (verb > 1) {
                    printf("%s : Received file header from node %d  (seed = %s).\n", now(), status.MPI_SOURCE, commaint(file_header.simulation_seed));
                }
                MPI_Recv(pulse_headers, user.num_pulses * sizeof(IQPulseHeader), MPI_BYTE, k, 1, MPI_COMM_WORLD, &status);
                if (verb > 1) {
                    // printf("%s : Received pulse headers of %s B from node %d.\n", now(), commaint(status._count), status.MPI_SOURCE);
                    MPI_Get_count(&status, MPI_INT, &count);
                    printf("%s : Received pulse headers of %s B from node %d.\n", now(), commaint(count), status.MPI_SOURCE);
                }
                MPI_Recv(pulse_cache, user.num_pulses * S->params.range_count * sizeof(cl_float4), MPI_BYTE, k, 2, MPI_COMM_WORLD, &status);
                if (verb > 1) {
                    // printf("%s : Received pulse data of %s B from node %d.\n", now(), commaint(status._count), status.MPI_SOURCE);
                    MPI_Get_count(&status, MPI_INT, &count);
                    printf("%s : Received pulse data of %s B from node %d.\n", now(), commaint(count), status.MPI_SOURCE);
                }
                write_iq_file(user, &file_header, pulse_headers, pulse_cache, S->params.range_count, k);
            }
        } else {
            // Send data to master node
            MPI_Send(&file_header, sizeof(IQFileHeader), MPI_BYTE, 0, 0, MPI_COMM_WORLD);
            MPI_Send(pulse_headers, user.num_pulses * sizeof(IQPulseHeader), MPI_BYTE, 0, 1, MPI_COMM_WORLD);
            MPI_Send(pulse_cache, user.num_pulses * S->params.range_count * sizeof(cl_float4), MPI_BYTE, 0, 2, MPI_COMM_WORLD);
        }

#else

        write_iq_file(user, &file_header, pulse_headers, pulse_cache, S->params.range_count, 0);
        
#endif

    }

    if (user.output_state_file) {
        memset(charbuff, 0, sizeof(charbuff));
        // snprintf(charbuff, sizeof(charbuff), "%s/sim-%s-%s%04.1f.simstate",
        //          user.output_dir,
        //          nowlong(),
        //          POS_is_ppi(&user.scan_pattern) ? "E": (POS_is_rhi(&user.scan_pattern) ? "A" : "S"),
        //          POS_is_ppi(&user.scan_pattern) ? user.scan_pattern.sweeps[0].elStart: (POS_is_rhi(&user.scan_pattern) ? user.scan_pattern.sweeps[0].azStart : (float)user.num_pulses));
        snprintf(charbuff, sizeof(charbuff), "%s.simstate", filename_prefix(&user));
        printf("%s : Output file : " UNDERLINE ("%s") "\n", now(), charbuff);
        fid = fopen(charbuff, "wb");
        if (fid == NULL) {
            fprintf(stderr, "%s : Error creating file for simulation state data.\n", now());
        }
        fwrite(&file_header, sizeof(IQFileHeader), 1, fid);
        SimState state;
        memset(&state, 0, sizeof(SimState));
        memcpy(&state.master, S, sizeof(RSHandle));
        fwrite(S, sizeof(SimState), 1, fid);
        if (verb > 1) {
            printf("%s : Total header size = %s B.\n", now(), commaint(ftell(fid)));
            printf("%s : sizeof(LESTable) = %zu   sizeof(ADMTable) = %zu   sizeof(RCSTable) = %zu\n", now(), sizeof(LESTable), sizeof(ADMTable), sizeof(RCSTable));
        }
        fwrite(S->scat_pos, sizeof(cl_float4), S->num_scats, fid);
        fwrite(S->scat_vel, sizeof(cl_float4), S->num_scats, fid);
        fwrite(S->scat_ori, sizeof(cl_float4), S->num_scats, fid);
        fwrite(S->scat_tum, sizeof(cl_float4), S->num_scats, fid);
        fwrite(S->scat_aux, sizeof(cl_float4), S->num_scats, fid);
        fwrite(S->scat_rcs, sizeof(cl_float4), S->num_scats, fid);
        fwrite(S->scat_sig, sizeof(cl_float4), S->num_scats, fid);
        fwrite(S->scat_rnd, sizeof(cl_uint4), S->num_scats, fid);
        printf("%s : State file with %s B.\n", now(), commaint(ftell(fid)));
        fclose(fid);
    }

    free(pulse_headers);
    free(pulse_cache);

    printf("%s : Session ended\n", now());

    RS_free(S);

#if defined (_OPEN_MPI)

    MPI_Finalize();

#endif

    return EXIT_SUCCESS;
}
