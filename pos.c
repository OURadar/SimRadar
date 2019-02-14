//
//  pos.c
//  Radar Simulation Framework
//
//  Created by Boonleng Cheong 9/12/2018
//  Copyright (c) 2018 Boonleng Cheong. All rights reserved.
//

#include "pos.h"

#pragma mark - Life Cycle

POSPattern *POS_init(void) {
    return POS_init_with_string("P:5,-12:12:0.05/10,-12:12:0.05/15,-12:12:0.05");
}

void POS_free(POSPattern *scan_pattern) {
    free(scan_pattern);
}

POSPattern *POS_init_with_string(const char *scan_string) {
    POSPattern *scan_pattern = (POSPattern *)malloc(sizeof(POSPattern));
    memset(scan_pattern, 0, sizeof(POSPattern));
    if (scan_pattern == NULL) {
        rsprint("Unable to allocate memory for scan_pattern");
        return NULL;
    }
    POS_parse_from_string(scan_pattern, scan_string);
    return scan_pattern;
}

#pragma mark - Methods

int POS_get_next_angles(POSPattern *scan) {
    int k = scan->index;
    // Current azimuth and elevation
    scan->az = scan->positions[k].az;
    scan->el = scan->positions[k].el;
    #if defined(DEBUG_POS)
    rsprint("%d / %d   %d / %d  %.2f %.2f\n",
            scan->index, scan->count,
            scan->positions[k].index, scan->positions[k].count,
            scan->az, scan->el);
    #endif
    // Update internal indices for next iteration
    scan->positions[k].index++;
    if (scan->positions[k].index == scan->positions[k].count) {
        scan->positions[k].index = 0;
        scan->index++;
        if (scan->index == scan->count) {
            scan->index = 0;
        }
    }
    return 0;
}

int POS_parse_from_string(POSPattern *scan, const char *string) {
    int i, j, k;
    float f1, f2, f3, f4;
    const char delim[] = "/";
    char scan_pattern[1024], *token;
    rsprint("Parsing scanning pattern '%s' ...\n", string);
    if (string[1] != ':') {
        rsprint("Expected : after the scan mode character.\n");
        return 1;
    }
    strcpy(scan_pattern, string + 2);
    scan->mode = string[0];
    switch (scan->mode) {
        case 'p':
        case 'P':
            // PPI
            rsprint("PPI scanning pattern ...\n");
            token = strtok(scan_pattern, delim);
            i = 0;
            j = 0;
            while (token && j < POS_MAX_PATTERN_COUNT) {
                k = sscanf(token, "%f,%f:%f:%f", &f1, &f2, &f3, &f4);
                scan->sweeps[i].elStart = f1;
                scan->sweeps[i].elEnd = f1;
                scan->sweeps[i].elDelta = 0.0f;
                scan->sweeps[i].azStart = f2;
                scan->sweeps[i].azEnd = f3;
                scan->sweeps[i].azDelta = f4;
                //printf("k = %d   f1 = %.3f   f2 = %.3f   f3 = %.3f   f4 = %.3f\n", k, f1, f2, f3, f4);
                do {
                    scan->positions[j].el = f1;
                    scan->positions[j].az = f2;
                    scan->positions[j].index = 0;
                    scan->positions[j].count = 1;
                    #if defined(DEBUG_POS)
                    rsprint("POS: j = %d   el = %5.2f   az = %6.2f   count = %u \n",
                            j, scan->positions[j].el, scan->positions[j].az, scan->positions[j].count);
                    #endif
                    f2 += f4;
                    j++;
                } while (fabs(scan->positions[j - 1].az - f3) > 0.1f * f4 && j < POS_MAX_PATTERN_COUNT);
                token = strtok(NULL, delim);
                i++;
            }
            scan->sweepCount = i;
            scan->sweepIndex = 0;
            scan->count = j;
            scan->index = 0;
            break;
        case 'r':
        case 'R':
            // RHI
            rsprint("RHI scanning pattern ...\n");
            token = strtok(scan_pattern, delim);
            i = 0;
            j = 0;
            while (token && j < POS_MAX_PATTERN_COUNT) {
                k = sscanf(token, "%f,%f:%f:%f", &f1, &f2, &f3, &f4);
                scan->sweeps[i].azStart = f1;
                scan->sweeps[i].azEnd = f1;
                scan->sweeps[i].azDelta = 0.0f;
                scan->sweeps[i].elStart = f2;
                scan->sweeps[i].elEnd = f3;
                scan->sweeps[i].elDelta = f4;
                //printf("k = %d   f1 = %.3f   f2 = %.3f   f3 = %.3f   f4 = %.3f\n", k, f1, f2, f3, f4);
                do {
                    scan->positions[j].az = f1;
                    scan->positions[j].el = f2;
                    scan->positions[j].index = 0;
                    scan->positions[j].count = 1;
                    #if defined(DEBUG_POS)
                    rsprint("POS: j = %d   el = %5.2f   az = %6.2f   count = %u \n",
                            j, scan->positions[j].el, scan->positions[j].az, scan->positions[j].count);
                    #endif
                    f2 += f4;
                    j++;
                } while (fabs(scan->positions[j - 1].el - f3) > 0.1f * f4 && j < POS_MAX_PATTERN_COUNT);
                token = strtok(NULL, delim);
                i++;
            }
            scan->sweepCount = i;
            scan->sweepIndex = 0;
            scan->count = j;
            scan->index = 0;
            break;
        case 'd':
        case 'D':
            rsprint("DBS scanning pattern ...\n");
            token = strtok(scan_pattern, delim);
            j = 0;
            while (token && j < POS_MAX_PATTERN_COUNT) {
                k = sscanf(token, "%f,%f,%f", &f1, &f2, &f3);
                #if defined(DEBUG_POS)
                printf("k = %d   f1 = %.3f   f2 = %.3f   f3 = %.3f\n", k, f1, f2, f3);
                #endif
                scan->positions[j].az = f1;
                scan->positions[j].el = f2;
                scan->positions[j].index = 0;
                scan->positions[j].count = (uint32_t)f3;
                #if defined(DEBUG_POS)
                rsprint("POS: j = %d   el = %5.2f   az = %6.2f   count = %u \n",
                        j, scan->positions[j].el, scan->positions[j].az, scan->positions[j].count);
                #endif
                token = strtok(NULL, delim);
                j++;
            }
            scan->count = j;
            scan->index = 0;
            break;
        default:
            break;
    }
    
    return 0;
}

bool POS_is_ppi(POSPattern *scan) {
    return scan->mode == 'p' || scan->mode == 'P';
}

bool POS_is_rhi(POSPattern *scan) {
    return scan->mode == 'r' || scan->mode == 'R';
}

bool POS_is_dbs(POSPattern *scan) {
    return scan->mode == 'd' || scan->mode == 'D';
}

void POS_summary(POSHandle P) {
    POSPattern *scan = (POSPattern *)P;
    int j;
    for (j = 0; j < scan->count; j++) {
        rsprint("POS: j = %d   el = %5.2f   az = %6.2f   count = %u \n",
                j, scan->positions[j].el, scan->positions[j].az, scan->positions[j].count);
    }
}
