#include <simd/simd.h>

#ifndef particle_h
#define particle_h

typedef struct {
    uint color;
    vector_float2 position;
    vector_float2 velocity;
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
    float velocityHalfLife;
    float rmax;
    float forceFactor;
} VelocityUpdateSetting;

typedef struct {
    float x;
    float y;
    float width;
    float height;
} Rect2;

#endif /* particle_h */
