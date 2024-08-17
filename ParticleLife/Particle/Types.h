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

typedef struct {
    enum ForceFunction forceFunction;
    int distanceFunction;
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
