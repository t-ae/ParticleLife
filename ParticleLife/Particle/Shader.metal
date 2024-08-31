#include <metal_stdlib>
#include "Types.h"
using namespace metal;

// wrap values into [-max, max) range
float2 wrap(float2 vector, float max) {
    return vector - floor((vector+max) / (2*max)) * (2*max);
}

// MARK: - Force functions
/// The force function described in the reference video: https://youtu.be/scvuli-zcRc?si=2XnKp-vTtEUd9QE3
float force1(float distance, float attraction) {
    float beta = 0.3;
    if(distance <= beta) {
        return -1 + distance/beta;
    } else if(distance <= 1) {
        return attraction * (1 - abs(2*distance-1-beta) / (1-beta));
    } else {
        return 0;
    }
}

float force2(float distance, float attraction) {
    float beta = 0.65;
    if(distance <= beta) {
        return -1 + (attraction+1)/beta * distance;
    } else if(distance <= 1) {
        return attraction / (beta-1) * (distance-1);
    } else {
        return 0;
    }
}

/// Combination pf force1 and force2.
float force3(float distance, float attraction) {
    if(attraction >= 0) {
        return force1(distance, attraction);
    } else {
        return force2(distance, attraction);
    }
}

// MARK: - Distance functions
float l1Distance(float2 vector) {
    return abs(vector.x) + abs(vector.y);
}

float linfDistance(float2 vector) {
    if(isnan(vector.x)) return NAN; // if vector.y is NaN, max returns NaN.
    return max(abs(vector.x), abs(vector.y));
}

// MARK: - Kernel functions
kernel void
updateVelocity(const device Particle* in [[ buffer(0) ]],
               device Particle* out [[ buffer(1) ]],
               constant uint32_t *particleCount [[ buffer(2) ]],
               constant uint32_t *colorCount [[ buffer(3) ]],
               constant float* attractionMatrix [[ buffer(4) ]],
               constant VelocityUpdateSetting *velocityUpdateSetting [[ buffer(5) ]],
               constant float *dt [[ buffer(6) ]],
               const uint32_t gid [[ thread_position_in_grid ]])
{
    float rmax = velocityUpdateSetting->rmax;
    float velocityHalfLife = velocityUpdateSetting->velocityHalfLife;
    
    float (*forceFunction)(float, float);
    if(velocityUpdateSetting->forceFunction == ForceFunction_force1) {
        forceFunction = force1;
    } else if(velocityUpdateSetting->forceFunction == ForceFunction_force2) {
        forceFunction = force2;
    } else if(velocityUpdateSetting->forceFunction == ForceFunction_force3) {
        forceFunction = force3;
    } else {
        return;
    }
    
    float (*distanceFunction)(float2);
    if(velocityUpdateSetting->distanceFunction == DistanceFunction_l1) {
        distanceFunction = l1Distance;
    } else if(velocityUpdateSetting->distanceFunction == DistanceFunction_l2) {
        distanceFunction = length;
    } else if(velocityUpdateSetting->distanceFunction == DistanceFunction_linf) {
        distanceFunction = linfDistance;
    } else {
        return;
    }
    
    float2 position = in[gid].position;
    constant float* attractionRow = attractionMatrix + in[gid].color * *colorCount;
    
    float2 accel(0, 0);
    for(uint32_t i = 0 ; i < *particleCount ; i++) {
        if(i == gid) continue;
        
        float2 vector = wrap(in[i].position - position, 1);
        
        if(!(linfDistance(vector) < rmax)) {
            // Ignore too large distance and NaN.
            continue;
        }
        
        float attraction = attractionRow[in[i].color];
        float distance = distanceFunction(vector);
        
        float f = forceFunction(distance/rmax, attraction);
        accel += f / distance * vector;
    }
    
    out[gid].position = in[gid].position;
    out[gid].color = in[gid].color;
    out[gid].velocity = in[gid].velocity * pow(0.5, *dt/velocityHalfLife); // friction
    out[gid].velocity += rmax * accel * velocityUpdateSetting->forceFactor * *dt;
}

kernel void
updatePosition(device Particle* particles [[ buffer(0) ]],
               constant float *dt [[ buffer(1) ]],
               const uint32_t gid [[ thread_position_in_grid ]])
{
    float2 velocity = particles[gid].velocity;
    particles[gid].position += velocity * *dt;
    particles[gid].position = wrap(particles[gid].position, 1);
}

// MARK: - Particle vertex/fragment shader
struct Point {
    float4 position [[position]];
    float size [[point_size]];
    float3 color;
};

vertex Point
particleVertex(const device Particle* particles [[ buffer(0) ]],
               constant float3 *rgb [[ buffer(1) ]],
               constant float *particleSize [[ buffer(2) ]],
               constant Transform *transform [[ buffer(3) ]],
               constant float2 *offset [[ buffer(4) ]],
               constant float2 *viewportSize [[ buffer(5) ]],
               uint32_t vid [[ vertex_id ]])
{
    Point out;
    out.position = float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = particles[vid].position + *offset - transform->center;
    out.position.xy = wrap(out.position.xy, 3);
    out.position.xy *= transform->zoom;
    
    // Aspect fill
    if(viewportSize->x < viewportSize->y) {
        out.position.x *= viewportSize->y / viewportSize->x;
    } else {
        out.position.y *= viewportSize->x / viewportSize->y;
    }
    
    out.size = *particleSize * max(viewportSize->x, viewportSize->y) * transform->zoom / 1000;
    out.color = rgb[particles[vid].color];
    return out;
}

fragment float4
particleFragment(Point point [[stage_in]],
                 float2 pointCoord [[point_coord]])
{
    float distance = length(pointCoord - float2(0.5));
    if(distance < 0.15) {
        float alpha = 1.0;
        return float4(point.color, alpha);
    } if(distance < 0.5) {
        float alpha = 1.0 - smoothstep(0.0, 0.5, distance);
        return float4(point.color, alpha);
    } else {
        discard_fragment();
        return float4();
    }
};
