//
//  rs_types.h
//  Radar Simulation Framework
//
//  Created by Boon Leng Cheong.
//

#ifndef _rs_types_h
#define _rs_types_h

#define RS_MAX_NUM_SCATS    120000000               // Maximum tested = 110M, 2016-03-003 (25k body/cell)
#define RS_BODY_PER_CELL          100.0f            // Default scatterer density
#define RS_PARAMS_LAMBDA            0.1f            // Default wavelength in m
#define RS_PARAMS_PRT               1.0e-3f         // Default PRT in s
#define RS_PARAMS_TAU               0.2e-6f         // Default pulse width in s
#define RS_PARAMS_PULSEWIDTH        RS_PARAMS_TAU   // Default pulse width in s, same as RS_PARAMS_TAU
#define RS_PARAMS_BEAMWIDTH         1.0f
#define RS_PARAMS_GATEWIDTH         30.0f

#define RSfloat  float

#if !defined (BOOL)
typedef signed char BOOL;
#endif

#if !defined (TRUE) && !defined (FALSE)
#define TRUE            ((BOOL)1)
#define FALSE           ((BOOL)0)
#endif

/*
typedef struct rs_vertex {
	RSfloat x;               // Position x
	RSfloat y;               // Position y
	RSfloat z;               // Position z
	RSfloat u;               // Velocity u
	RSfloat v;               // Velocity v
	RSfloat w;               // Velocity w
	RSfloat a;               // Amplitude of RCS
	RSfloat p;               // Phase of RCS
} RSVertex;
*/

typedef struct _rs_point {
	RSfloat x;
	RSfloat y;
	RSfloat z;
} RSPoint;

typedef struct _rs_volume {
	RSPoint origin;
	RSPoint size;
} RSVolume;

typedef struct _rs_params {
	RSfloat  c;                    // Speed of light (m/s)
	RSfloat  prt;                  // Pulse repetition time (second)
	RSfloat  loss;                 // System loss
	
	RSfloat  lambda;               // Wavelength (m)
	RSfloat  tx_power_watt;        // Transmit power (watt)
	RSfloat  antenna_gain_dbi;     // Antenna gain (dBi)
	RSfloat  antenna_bw_deg;       // Antenna beamwidth (deg)
	RSfloat  tau;                  // Pulse width (s)

	RSfloat  range_start;          // Start range (m)
	RSfloat  range_end;            // End range (m)
	RSfloat  range_delta;          // Range sampling gate spacing (m)
	
	RSfloat  azimuth_start_deg;    // Start azimuth (deg)
	RSfloat  azimuth_end_deg;      // End azimuth (deg)
	RSfloat  azimuth_delta_deg;    // Azimuth sampling gate spacing (deg)

	RSfloat  elevation_start_deg;   // Start azimuth (deg)
	RSfloat  elevation_end_deg;     // End azimuth (deg)
	RSfloat  elevation_delta_deg;   // Azimuth sampling gate spacing (deg)
	
	RSfloat  domain_pad_factor;     // Padding factor to scale up the needed domain
	RSfloat  body_per_cell;         // Average number of scatter bodies per cell

	// Derived parameters for easy reference
	RSfloat  prf;                   // Pulse repetition frequency (Hz)
	RSfloat  va;                    // Aliasing velocity (m/s)
	RSfloat  fn;                    // Nyquist frequency (Hz)
	RSfloat  antenna_bw_rad;        // Antenna beamwidth (rad)
	RSfloat  dr;                    // Range resolution

	//RSfloat azimuth_start_rad;
	
	uint32_t range_count;
	
} RSParams;

#endif
