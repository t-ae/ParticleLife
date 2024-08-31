#include <simd/simd.h>

#ifndef particle_h
#define particle_h

typedef struct {
    uint32_t color;
    simd_float2 position;
    simd_float2 velocity;
} Particle;

enum ForceFunction {
    ForceFunction_force1,
    ForceFunction_force2,
    ForceFunction_force3,
};

enum DistanceFunction {
    DistanceFunction_l1,
    DistanceFunction_l2,
    DistanceFunction_linf,
};

typedef struct {
    enum ForceFunction forceFunction;
    enum DistanceFunction distanceFunction;
    float rmax;
    float velocityHalfLife;
    float forceFactor;
} VelocityUpdateSetting;

typedef struct {
    simd_float2 center;
    float zoom;
} Transform;

#endif /* particle_h */
