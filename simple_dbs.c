//
//  simple_dbs.c
//
//  This example illustrates a simple usage of the RS Framework to simulate a DBS scan.
//
//  Created by Boonleng Cheong on 2/14/2019.
//  Copyright (c) 2019 Boonleng Cheong. All rights reserved.
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
    
    // Set up the concepts and basic parameters
    RS_set_concept(S, RSSimulationConceptFixedScattererPosition | RSSimulationConceptVerticallyPointingRadar);
    RS_set_antenna_params(S, 5.0f, 30.5f);    // Antenna beamwidth in degrees and gain in dB
    RS_set_tx_params(S, 0.2e-6f, 10.0e3f);    // Equivalent transmit pulsewidth in seconds and power in watts
    RS_set_lambda(S, 3.0e8 / 915.0e6);        // Wavelength in meters (derived from frequency)
    RS_set_prt(S, 1.0e-3f);                   // Pulse repetition time in seconds

    RS_show_radar_params(S);

    // Propose a scan pattern
    POSPattern *scan_pattern = POS_init_with_string("D:0,75,50/90,75,50/0,90,50");
    RS_set_scan_pattern(S, scan_pattern);

    // After the wind table is set, we can use the API to suggest the optimal scan box
    RSBox box = RS_suggest_scan_domain(S);

    // Set the scan box
    RS_set_scan_box(S,
                    box.origin.r, box.origin.r + box.size.r, 30.0f,   // Range
                    box.origin.a, box.origin.a + box.size.a, 1.0f,    // Azimuth
                    box.origin.e, box.origin.e + box.size.e, 1.0f);   // Elevation
    

    // Choose an LES configuration
    RS_set_vel_data_to_config(S, LESConfigFlat);

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
