#include <simd/simd.h>

#ifndef particle_h
#define particle_h

typedef struct {
    uint color;
    simd_float2 position;
    simd_float2 velocity;
    uint attractorCount;
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
    DistanceFunction_l05,
    DistanceFunction_l02,
    DistanceFunction_triangular,
    DistanceFunction_pentagonal,
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
