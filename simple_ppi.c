//
//  simple_ppi.c
//
//  This example illustrates a simple usage of the RS Framework to simulate a PPI scan.
//
//  Created by Boon Leng Cheong on 2/29/16.
//  Copyright © 2016 Boon Leng Cheong. All rights reserved.
//

#include "rs.h"

//
//
//  M A I N
//
//
int main(int argc, char *argv[]) {
    
    int k = 0;

    RSHandle  *S;
    
    // Initialize the RS framework
    S = RS_init();
    if (S == NULL) {
        fprintf(stderr, "%s : Some errors occurred during RS_init().\n", now());
        return EXIT_FAILURE;
    }
    
    // Set up the parameters: use the setter functions to change the state.
    RS_set_antenna_params(S, 1.0f, 44.5f);
    RS_set_tx_params(S, 0.2e-6f, 50.0e3f);
    RS_set_prt(S, 1.0e-3f);

    // Set the DSD profile
    RS_set_dsd_to_mp(S);

    // Set the first debris object to be leaf
    RS_set_obj_data_to_config(S, OBJConfigLeaf);
    
    // Set the first debris type to have a population of 1024
    RS_set_debris_count(S, 1, 1024);
    
    // Revise to the GPU preferred counts if there is no strict requirements on the debris count
    RS_revise_debris_counts_to_gpu_preference(S);
    
    // Propose a scan pattern
    POSPattern *scan_pattern = POS_init();
    RS_set_scan_pattern(S, scan_pattern);
    
    // After the wind table is set, we can use the API to suggest the optimal scan box
    RSBox box = RS_suggest_scan_domain(S);
    
    // Set the scan box
    RS_set_scan_box(S,
                    box.origin.r, box.origin.r + box.size.r, 15.0f,   // Range
                    box.origin.a, box.origin.a + box.size.a, 1.0f,    // Azimuth
                    box.origin.e, box.origin.e + box.size.e, 1.0f);   // Elevation

    RS_show_radar_params(S);

    // Populate the domain with scatter bodies.
    // This is also the function that triggers kernel compilation, GPU memory allocation and
    // upload all the parameters to the GPU.
    RS_populate(S);
    
    // Show some basic info
    const int num_pulses = 1200;
    printf("%s : Emulating %s frame%s with %s scatter bodies\n",
           now(), commaint(num_pulses), num_pulses>1?"s":"", commaint(S->num_scats));
    
    // At this point, we are ready to bake
    
    // ---------------------------------------------------------------------------------------------------------------
    
    float el = 3.0f;
    float az = -12.0f;
    
    // Now we bake
    for (k = 0; k < num_pulses; k++) {
        RS_set_beam_pos(S, az, el);
        RS_make_pulse(S);
        RS_advance_time(S);
        
        // This makes az go from -12 to +12.
        az = az + 0.02f;
        
        // Show some output to the screen so we know everything is okay.
        if (k % 300 == 0) {
            fprintf(stderr, "Pulse %d\n", k);
        }
    }
    
    // Retrieve the results from the GPUs
    RS_download(S);
    
    printf("%s : Final scatter body positions, velocities and orientations:\n", now());
    
    RS_show_scat_pos(S);
    
    RS_show_scat_sig(S);
    
    RS_free(S);
    
    return EXIT_SUCCESS;
}
