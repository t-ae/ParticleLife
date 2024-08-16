#include <simd/simd.h>

#ifndef particle_h
#define particle_h

typedef struct {
    uint color;
    vector_float2 position;
    vector_float2 velocity;
} Particle;

typedef struct {
    uint forceFunction;
    float velocityHalfLife;
    float rmax;
} AccelSetting;

#endif /* particle_h */
