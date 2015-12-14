Simulation of a Radar
=====================

A polarimetric radar time-series emulator utilizing air-drag model for particle motions and a realistic radar cross library for particle back scattering calculations. Implemented with OpenCL for massive parallel computations. This is awesome!


Get the Project
---------------

To start using or working with this framework, you can just `git clone` the code repository using the HTTPS link on the front page. An `xcodeproj` project is included so you can manage the source codes using Xcode on Mac OS X. Git can be set up under Xcode for the source control to stay up to date. If you would like to contribute to the framework, please me at <boonleng@ou.edu>.

### Requirements ###

On Linux:

* [GCC] GNU C Compiler
* [OpenCL] framework version 1.1 or 1.2
* [HDF5] framework

On Mac:

* [Xcode 6]
* [Sparkle framework]

[GCC]: http://gcc.gnu.org
[OpenCL]: https://www.khronos.org/opencl
[HDF5]: https://www.hdfgroup.org/HDF5
[Xcode 6]: https://developer.apple.com/xcode
[Sparkle framework]: http://sparkle-project.org


Installing HDF5 on a Mac
------------------------

The easiest way to obtain HDF5 framework on a Mac is through Homebrew (http://brew.sh). Once you have Homebrew installed, simply use the command `brew install hdf5` or `brew install homebrew/science/hdf5` on the terminal. Homebrew handles all the dependency check and installed the pre-requisites for you.


OSCER Boomer
------------

There are several GPU equiped nodes and everything needed is installed. However, the `git` software does not have HTTP access to to the ARRC git repository. Until then, manually the software project folder to your home folder. Batch scripts are included to schedule jobs for the GPU compute nodes, i.e., CUDA pool.


Radar Simulation Framework
--------------------------

A set of C functions are collected in Radar Simulation (RS) framework, which abstracts the low-level interaction witht the GPU for workload parallelization. OpenCL was selected because of the vendor neutral implementation.

### LES, ADM & RCS Data ###

A zip archive with data of LES (Large Eddy Simulation), ADM (Air Drag Model) and RCS (Radar Cross Section) can be downloaded from

http://arrc.ou.edu/~boonleng/simradar/tables.zip

The extracted folder `tables` can be placed in one of the following locations:

- ~/Downloads
- ~/Documents
- ~/Desktop

### Using the Radar Simulation (RS) Framework ###

The simulation framework is written is plain C for performance and portability. All calculations are implemented within RS framework with functions prefix RS. To include the RS framework, there is only one header, i.e., `rs.h` is needed. The following codes create a simple simulation domain:

    #include "rs.h"

    int main(int argc, char *argv[]) {

        RSHandle  *S;
        ADMHandle *A;
        LESHandle *L;
        RCSHandle *R;

        // Initialize the RS framework
        S = RS_init();
        if (S == NULL) {
            fprintf(stderr, "%s : Some errors occurred during RS_init().\n", now());
            return EXIT_FAILURE;
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

        // Set up the parameters: use the setter functions to change the state.

        RS_set_antenna_params(S, 1.0f, 44.5f);                // 1.0-deg, 44.5 dBi gain

        RS_set_tx_params(S, 30.0f * 2.0f / 3.0e8f, 10.0e3);   // Resolution in m, power in W

        RS_set_scan_box(S,
            10.0e3, 15.0e3, 250.0f,  // Range in between 10,000 and 15,000 m, 250-m spacing
            -10.0f, 10.0f, 1.0f,     // Azimuth in between -10.0 and +10.0 deg, 1.0-deg spacing
            0.0f, 8.0f, 1.0f);       // Elevation in between 0.0 and 8.0 deg, 1.0-deg spacing

        RS_set_range_weight_to_triangle(S, 120.0f);

        RS_clear_wind_data(S);
        RS_set_wind_data_to_LES_table(S, LES_get_frame(L, 0));

        RS_clear_adm_data(S);
        RS_set_adm_data_to_ADM_table(S, ADM_get_frame(A));

        RS_clear_rcs_data(S);
        RS_set_rcs_data_to_RCS_table(S, RCS_get_frame(R));

        // Populate the domain with scatter bodies.
        // This is also the function that triggers kernel compilation, GPU memory allocation and
        // upload all the parameters to the GPU.
        RS_populate(S);

        // Now, we are ready to make pulse(s)
        for (int k=0; k<10; k++) {
            RS_set_beam_pos(S, 15.0f, 10.0f);
            RS_advance_time(S);
            RS_make_pulse(S);
            RS_download_pulse_only(S);
        }

        // Retrieve the results from the GPUs
        RS_download(S);        

        printf("Final scatter body positions:\n");

        RS_show_scat_pos(S);

        RS_free(S);

        LES_free(L);

        return EXIT_SUCCESS;
    }

Assuming you already have the library compile successfully and the archived library is placed under `lib/librs.a`, this example can be compiled on a Mac using the following command:

    gcc -I./ -L./lib -o example example.c -lrs -framework OpenCL -lm -lpthread

Alternatively, if you are on a linux machine, the following should work:

    gcc -I./ -L./lib -o example example.c -lrs -lOpenCL -lm -lpthread

On linux machines, it is important that the GPU driver's include and library paths are also included in the compilation command.


The SimRadar App for Mac OS X
-----------------------------

A dedicated project SimRadar, which is a Mac OS X implemtation of visualization and graphical user interface, is included. It demonstrates how to wrap the framework in Objective-C. There is currently no plan to make this a full-fledge application that allows users to access all simulation parameters through the GUI.


### Sparkle Framework ####

The Sparkle framework is not included as part of the git package simply because it is developed and maintained by a third party (http://sparkle-project.org). The latest release can be downloaded from the official website but the version that is used with this software can be obtained from http://arrc.ou.edu/~boonleng/Sparkle.framework.zip. The extracted folder Sparkle.framework should go into the **SimRadar** project folder.



Implmentation
=============


Details on Scatterer Attributes
-------------------------------

Multiple arrays of type `cl_float` are used to keep track of a set of attributes associated with each scatterer. The following list provides a summary of the attriutes and the variables used on the C-level abstraction.

    cl_mem                 scat_pos;   // x, y, z coordinates
    cl_mem                 scat_vel;   // u, v, w wind components
    cl_mem                 scat_ori;   // orientation descbried by a quaternion
    cl_mem                 scat_tum;   // tumbling motion = change of orientation derived from ADM
    cl_mem                 scat_att;   // scatterer type, dot products, range, etc.
    cl_mem                 scat_sig;   // signal: Ih Qh Iv Qv
    cl_mem                 scat_rnd;   // random seed
