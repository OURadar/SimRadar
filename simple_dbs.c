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
    
    RSHandle  *S;
    const int num_pulses = 300;

    // Initialize the RS framework
    S = RS_init();
    if (S == NULL) {
        fprintf(stderr, "%s : Some errors occurred during RS_init().\n", now());
        return EXIT_FAILURE;
    }
    
    S->verb = 1;
    
    // Set up the concepts and basic parameters
    RS_set_concept(S, RSSimulationConceptFixedScattererPosition | RSSimulationConceptVerticallyPointingRadar);
    RS_set_sampling_spacing(S, 30.0f, 1.0, 1.0);    // Sampling spacing in range, azimuth and elevation
    RS_set_antenna_params(S, 5.0f, 30.5f);          // Antenna beamwidth in degrees and gain in dB
    RS_set_tx_params(S, 0.2e-6f, 10.0e3f);          // Equivalent transmit pulsewidth in seconds and power in watts
    RS_set_lambda(S, 3.0e8 / 915.0e6);              // Wavelength in meters (derived from frequency)
    RS_set_prt(S, 1.0 / 140.0);                     // Pulse repetition time in seconds

    // Summary of radar parameters
    RS_show_radar_params(S);

    // Choose an LES configuration
    RS_set_vel_data_to_config(S, LESConfigFlat);

    // Propose a scan pattern
    POSPattern *scan_pattern = POS_init_with_string("D:0,75,50/90,75,50/0,90,50");
    RS_set_scan_pattern(S, scan_pattern);
    
    // (Optional) After the wind table is set, we can use the API to suggest the optimal scan box
    // RSBox box = RS_suggest_scan_domain(S);
    // RS_set_scan_box(S, box);

    // Populate the domain with scatter bodies.
    // This is also the function that triggers kernel compilation, GPU memory allocation and
    // upload all the parameters to the GPU.
    RS_populate(S);
    
    // Show some basic info
    printf("%s : Emulating %s frame%s with %s scatter bodies\n",
           now(), commaint(num_pulses), num_pulses>1?"s":"", commaint(S->num_scats));
    
    // ---------------------------------------------------------------------------------------------------------------
    
    // Now we bake
    for (int k = 0; k < num_pulses; k++) {
        RS_make_pulse(S);
        RS_advance_beam(S);
        RS_advance_time(S);
        
        // POSPattern *scan_pattern = S->P;
        // printf("k %d    EL %.2f    AZ %.2f\n", k, scan_pattern->el, scan_pattern->az);
    }
    
    // Retrieve the results from the GPUs
    RS_download(S);
    
    printf("%s : Final scatter body positions, velocities and orientations:\n", now());
 
    // Show some scatterer attributes
    RS_show_scat_pos(S);
    RS_show_scat_sig(S);
    
    RS_free(S);
    
    return EXIT_SUCCESS;
}
