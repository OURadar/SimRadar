// GPU Vencor
enum RS_GPU_VENDOR {
    RS_GPU_VENDOR_UNKNOWN,
    RS_GPU_VENDOR_NVIDIA,
    RS_GPU_VENDOR_INTEL,
    RS_GPU_VENDOR_AMD
};

// A typical convention for table description, which is a set of parameters along with a table
enum RSTable1DDescription {
    RSTable1DDescriptionScale                     = 0,
    RSTable1DDescriptionOrigin                    = 1,
    RSTable1DDescriptionMaximum                   = 2,
    RSTable1DDescriptionUserConstant              = 3
};

enum RSTable3DDescription {
    RSTable3DDescriptionScaleX                    =  0,
    RSTable3DDescriptionScaleY                    =  1,
    RSTable3DDescriptionScaleZ                    =  2,
    RSTable3DDescriptionRefreshTime               =  3,
    RSTable3DDescriptionOriginX                   =  4,
    RSTable3DDescriptionOriginY                   =  5,
    RSTable3DDescriptionOriginZ                   =  6,
    RSTable3DDescriptionFormat                    =  7,
    RSTable3DDescriptionMaximumX                  =  8,
    RSTable3DDescriptionMaximumY                  =  9,
    RSTable3DDescriptionMaximumZ                  = 10,
    RSTable3DDescription11                        = 11,
    RSTable3DDescriptionRecipInLnX                = 12,
    RSTable3DDescriptionRecipInLnY                = 13,
    RSTable3DDescriptionRecipInLnZ                = 14,
    RSTable3DDescriptionTachikawa                 = 15
};

enum RSTable3DStaggeredDescription {
    RSTable3DStaggeredDescriptionBaseChangeX      =  0,
    RSTable3DStaggeredDescriptionBaseChangeY      =  1,
    RSTable3DStaggeredDescriptionBaseChangeZ      =  2,
    RSTable3DStaggeredDescriptionRefreshTime      =  3,
    RSTable3DStaggeredDescriptionPositionScaleX   =  4,
    RSTable3DStaggeredDescriptionPositionScaleY   =  5,
    RSTable3DStaggeredDescriptionPositionScaleZ   =  6,
    RSTable3DStaggeredDescriptionFormat           =  7,
    RSTable3DStaggeredDescriptionOffsetX          =  8,
    RSTable3DStaggeredDescriptionOffsetY          =  9,
    RSTable3DStaggeredDescriptionOffsetZ          = 10,
    RSTable3DStaggeredDescription11               = 11,
    RSTable3DStaggeredDescriptionRecipInLnX       = 12,
    RSTable3DStaggeredDescriptionRecipInLnY       = 13,
    RSTable3DStaggeredDescriptionRecipInLnZ       = 14,
    RSTable3DStaggeredDescriptionTachikawa        = 15
};

enum RSTableDescription {
    RSTableDescriptionScaleX                      =  0,
    RSTableDescriptionScaleY                      =  1,
    RSTableDescriptionScaleZ                      =  2,
    RSTableDescriptionReserved1                   =  3,
    RSTableDescriptionOriginX                     =  4,
    RSTableDescriptionOriginY                     =  5,
    RSTableDescriptionOriginZ                     =  6,
    RSTableDescriptionReserved2                   =  7,
    RSTableDescriptionMaximumX                    =  8,
    RSTableDescriptionMaximumY                    =  9,  // s9
    RSTableDescriptionMaximumZ                    = 10,  // sa
    RSTableDescriptionReserved3                   = 11,  // sb
    RSTableDescriptionReserved4                   = 12,  // sc
    RSTableDescriptionReserved5                   = 13,  // sd
    RSTableDescriptionReserved6                   = 14,  // se
    RSTableDescriptionReserved7                   = 15   // sf
};

enum RSTableStaggeredDescription {
    RSTableStaggeredDescriptionBaseChangeX        =  0,
    RSTableStaggeredDescriptionBaseChangeY        =  1,
    RSTableStaggeredDescriptionBaseChangeZ        =  2,
    RSTableStaggeredDescriptionReserved1          =  3,
    RSTableStaggeredDescriptionPositionScaleX     =  4,
    RSTableStaggeredDescriptionPositionScaleY     =  5,
    RSTableStaggeredDescriptionPositionScaleZ     =  6,
    RSTableStaggeredDescriptionReserved2          =  7,
    RSTableStaggeredDescriptionOffsetX            =  8,
    RSTableStaggeredDescriptionOffsetY            =  9,
    RSTableStaggeredDescriptionOffsetZ            = 10,
    RSTableStaggeredDescriptionReserved3          = 11,
    RSTableStaggeredDescriptionReserved4          = 12,
    RSTableStaggeredDescriptionReserved5          = 13,
    RSTableStaggeredDescriptionReserved6          = 14,
    RSTableStaggeredDescriptionReserved7          = 15
};

enum RSSimulationDescription {
    RSSimulationDescriptionBeamUnitX              =  0,
    RSSimulationDescriptionBeamUnitY              =  1,
    RSSimulationDescriptionBeamUnitZ              =  2,
    RSSimulationDescriptionTotalParticles         =  3,
    RSSimulationDescriptionWaveNumber             =  4,
    RSSimulationDescriptionConcept                =  5,
    RSSimulationDescriptionDropConcentrationScale =  6,
    RSSimulationDescriptionSimTic                 =  7,
    RSSimulationDescriptionBoundOriginX           =  8,  // hi.s0
    RSSimulationDescriptionBoundOriginY           =  9,  // hi.s1
    RSSimulationDescriptionBoundOriginZ           = 10,  // hi.s2
    RSSimulationDescriptionPRT                    = 11,
    RSSimulationDescriptionBoundSizeX             = 12,  // hi.s4
    RSSimulationDescriptionBoundSizeY             = 13,  // hi.s5
    RSSimulationDescriptionBoundSizeZ             = 14,  // hi.s6
    RSSimulationDescription15                     = 15   //
};

enum RSDropSizeDistribution {
    RSDropSizeDistributionUndefined               = 0,
    RSDropSizeDistributionMarshallPalmer          = 1,
    RSDropSizeDistributionGamma                   = 2,
    RSDropSizeDistributionArbitrary               = 3
};

enum RSTableSpacing {
    RSTableSpacingUniform                         = 0,
    RSTableSpacingStretchedX                      = 1,
    RSTableSpacingStretchedY                      = 1 << 1,
    RSTableSpacingStretchedZ                      = 1 << 2,
    RSTableSpacingStretchedXYZ                    = RSTableSpacingStretchedX | RSTableSpacingStretchedY | RSTableSpacingStretchedZ
};

enum RSSimulationConcept {
    RSSimulationConceptNull                       = 0,
    RSSimulationConceptNonZeroCrossPol            = 1,
    RSSimulationConceptDraggedBackground          = 1 << 1,
    RSSimulationConceptTransparentBackground      = 1 << 2,
    RSSimulationConceptBoundedParticleVelocity    = 1 << 3,
    RSSimulationConceptUniformDSDScaledRCS        = 1 << 4,
    RSSimulationConceptFixedScattererPosition     = 1 << 5,
    RSSimulationConceptVerticallyPointingRadar    = 1 << 6,
    RSSimulationConceptDebrisFluxFromVelocity     = 1 << 7
};
