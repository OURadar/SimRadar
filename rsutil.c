#include "rs.h"
#include <stdbool.h>
#include <getopt.h>
#include <dirent.h>
#include <errno.h>

#define ITALIC(x)            "\033[3m" x "\033[23m"
#define UNDERLINE(x)         "\033[4m" x "\033[24m"
#define HIGHLIGHT(x)         "\033[38;5;82;48;5;238m" x "\033[0m"
#define UNDERLINE_ITALIC(x)  "\033[3;4m" x "\033[23;24m"

#

void set_debris_flux_field_to_test(RSHandle *H) {
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


#pragma mark - Local Functions

int RS_indent_copy(char *dst, char *src, const int width) {
    int k = 0;
    char *e, *s = src;
    if (width == 0) {
        k = sprintf(dst, "%s", src);
        return k;
    }
    char indent[width + 1];
    memset(indent, ' ', width);
    indent[width] = '\0';
    do {
        e = strchr(s, '\n');
        if (e) {
            *e = '\0';
            k += sprintf(dst + k, "%s%s\n", indent, s);
            s = e + 1;
        }
    } while (e != NULL);
    k += sprintf(dst + k, "%s%s", indent, s);
    return k;
}

char *RS_test_by_number_description(const int indent) {
    static char text[4096];
    char helpText[] =
    " 0 - Generate iCDF from CDF\n";
    RS_indent_copy(text, helpText, indent);
    if (strlen(text) > 3000) {
        fprintf(stderr, "Warning. Approaching limit. (%lu)\n", strlen(text));
    }
    return text;
}

void RS_test_by_number(const int number, const void *arg) {
    switch (number) {
        case 0:
            printf("Test 0.\n");
            set_debris_flux_field_to_test(NULL);
            break;
        default:
            printf("Test %d is invalid.\n", number);
            break;
    }
}

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
           "  -v (--verbose)\n"
           "         Increases verbosity level.\n"
           "%s"
           "\n"
           "\n\n"
           "%s (SimRadar %s)\n\n",
           name,
           RS_test_by_number_description(9),
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
                RS_test_by_number(k, argc == optind ? NULL : argv[optind]);
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
