//
//  pos.c
//  Radar Simulation Framework
//
//  Created by Boonleng Cheong 9/12/2018
//  Copyright (c) 2018 Boonleng Cheong. All rights reserved.
//

#include "pos.h"

int POS_get_next_angles(POSPattern *scan) {
    int k = scan->index;
    // Update internal indices for next iteration
    scan->positions[k].index++;
    if (scan->positions[k].index == scan->positions[k].count) {
        scan->positions[k].index = 0;
        scan->index++;
        if (scan->index == scan->count) {
            scan->index = 0;
        }
    }
    scan->az = scan->positions[k].az;
    scan->el = scan->positions[k].el;
    scan->scan_index++;
    return 0;
}
