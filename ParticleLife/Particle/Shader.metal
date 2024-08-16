#include <metal_stdlib>
#include "Types.h"
using namespace metal;

constant int COLOR_COUNT = 6;

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

kernel void
updateVelocity(device Particle* particles [[ buffer(0) ]],
               constant uint *particleCount [[ buffer(1) ]],
               constant float* attraction [[ buffer(2) ]],
               constant AccelSetting *accelSetting [[ buffer(3) ]],
               constant float *dt [[ buffer(4) ]],
               const uint gid [[ thread_position_in_grid ]])
{
    float rmax = accelSetting->rmax;
    float velocityHalfLife = accelSetting->velocityHalfLife;
    auto forceFunction = force1;
    if(accelSetting->forceFunction == 1) {
        forceFunction = force1;
    } else if(accelSetting->forceFunction == 2) {
        forceFunction = force2;
    }else if(accelSetting->forceFunction == 3) {
        forceFunction = force3;
    }
    
    vector_float2 accel(0, 0);
    for(uint i = 0 ; i < *particleCount ; i++) {
        if(i == gid) continue;
        
        float2 vector = particles[i].position - particles[gid].position;
        if(vector.x < -0.5) {
            vector.x += 1;
        } else if(vector.x > 0.5) {
            vector.x -= 1;
        }
        if(vector.y < -0.5) {
            vector.y += 1;
        } else if(vector.y > 0.5) {
            vector.y -= 1;
        }
        
        if(vector.x < -rmax || vector.x > rmax || vector.y < -rmax || vector.y > rmax) {
            // early continue
            continue;
        }
        
        float attr = attraction[particles[gid].color * COLOR_COUNT + particles[i].color];
        float distance = length(vector);
        
        float f = forceFunction(distance/rmax, attr);
        accel += vector / distance * f;
    }
    
    particles[gid].velocity *= pow(0.5, *dt/velocityHalfLife); // friction
    particles[gid].velocity += rmax * accel * *dt;
}

kernel void
updatePosition(device Particle* particles [[ buffer(0) ]],
               constant float *dt [[ buffer(1) ]],
               const uint gid [[ thread_position_in_grid ]])
{
    float2 velocity = particles[gid].velocity;
    
    particles[gid].position += velocity * *dt;
    
    while(particles[gid].position.x < 0) {
        particles[gid].position.x += 1;
    }
    while(particles[gid].position.x > 1) {
        particles[gid].position.x -= 1;
    }
    
    while(particles[gid].position.y < 0) {
        particles[gid].position.y += 1;
    }
    while(particles[gid].position.y > 1) {
        particles[gid].position.y -= 1;
    }
}

struct Point {
    float4 position [[position]];
    float size [[point_size]];
    float3 color;
};

vertex Point
vertexFunc(const device Particle* particles [[ buffer(0) ]],
           constant vector_float3 *rgba [[ buffer(1) ]],
           constant float *particleSize [[ buffer(2) ]],
           unsigned int vid [[ vertex_id ]])
{
    Point out;
    out.position = vector_float4(0.0f, 0.0f, 0.0f, 1.0f);
    out.position.xy = particles[vid].position * 2 - 1;
    out.size = *particleSize;
    out.color = rgba[particles[vid].color];
    return out;
}

fragment float4
fragmentFunc(Point in [[stage_in]],
             float2 pointCoord [[point_coord]])
{
    float distance = length(pointCoord - float2(0.5));
    if(distance > 0.5) {
        discard_fragment();
    }
    float alpha = 1 - smoothstep(0.2, 0.8, distance);
    return float4(in.color, alpha);
};
