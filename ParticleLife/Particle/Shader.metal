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

float l1(vector_float2 vector) {
    return abs(vector.x) + abs(vector.y);
}

float linf(vector_float2 vector) {
    return max(abs(vector.x), abs(vector.y));
}

kernel void
updateVelocity(device Particle* particles [[ buffer(0) ]],
               constant uint *particleCount [[ buffer(1) ]],
               constant float* attraction [[ buffer(2) ]],
               constant VelocityUpdateSetting *velocityUpdateSetting [[ buffer(3) ]],
               constant float *dt [[ buffer(4) ]],
               const uint gid [[ thread_position_in_grid ]])
{
    float rmax = velocityUpdateSetting->rmax;
    float velocityHalfLife = velocityUpdateSetting->velocityHalfLife;
    
    float (*forceFunction)(float, float);
    if(velocityUpdateSetting->forceFunction == 1) {
        forceFunction = force1;
    } else if(velocityUpdateSetting->forceFunction == 2) {
        forceFunction = force2;
    } else if(velocityUpdateSetting->forceFunction == 3) {
        forceFunction = force3;
    }
    
    float (*distanceFunction)(vector_float2);
    if(velocityUpdateSetting->distanceFunction == 1) {
        distanceFunction = l1;
    } else if(velocityUpdateSetting->distanceFunction == 2) {
        distanceFunction = length;
    } else if(velocityUpdateSetting->distanceFunction == -1) {
        distanceFunction = linf;
    }
    
    vector_float2 position = particles[gid].position;
    constant float* attractionRow = attraction + particles[gid].color * COLOR_COUNT;
    
    vector_float2 accel(0, 0);
    for(uint i = 0 ; i < *particleCount ; i++) {
        if(i == gid) continue;
        
        float2 vector = particles[i].position - position;
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
        
        if(linf(vector) > rmax) {
            // early continue
            continue;
        }
        
        float attr = attractionRow[particles[i].color];
        float distance = distanceFunction(vector);
        
        float f = forceFunction(distance/rmax, attr);
        accel += vector / distance * f;
    }
    
    particles[gid].velocity *= pow(0.5, *dt/velocityHalfLife); // friction
    particles[gid].velocity += rmax * accel * *dt;
}

float wrappedZeroOneRange(float value) {
    if(value < 0) {
        value += ceil(abs(value));
    } else if(value > 1) {
        value -= floor(value);
    }
    return value;
}

kernel void
updatePosition(device Particle* particles [[ buffer(0) ]],
               constant float *dt [[ buffer(1) ]],
               const uint gid [[ thread_position_in_grid ]])
{
    float2 velocity = particles[gid].velocity;
    
    particles[gid].position += velocity * *dt;
    particles[gid].position.x = wrappedZeroOneRange(particles[gid].position.x);
    particles[gid].position.y = wrappedZeroOneRange(particles[gid].position.y);
}

struct Point {
    float4 position [[position]];
    float size [[point_size]];
    float3 color;
};

float transform(float value, float origin, float size, float offset) {
    value -= origin;
    if(value < 0) {
        value += ceil(abs(value));
    } else if(value > size) {
        value -= ceil(value - size);
    }
    value += offset;
    return value / size;
}

vertex Point
vertexFunc(const device Particle* particles [[ buffer(0) ]],
           constant vector_float3 *rgb [[ buffer(1) ]],
           constant float *particleSize [[ buffer(2) ]],
           constant Rect2 *renderingRect [[ buffer(3) ]],
           constant vector_float2 *offset [[ buffer(4) ]],
           constant vector_float2 *viewportSize [[ buffer(5) ]],
           unsigned int vid [[ vertex_id ]])
{
    Point out;
    out.position = vector_float4(0.0f, 0.0f, 0.0f, 1.0f);
    out.position.xy = particles[vid].position;
    
    out.position.x = transform(out.position.x, renderingRect->x, renderingRect->width, offset->x);
    out.position.y = transform(out.position.y, renderingRect->y, renderingRect->height, offset->y);
    
    out.position.xy *= 2;
    out.position.xy -= 1;
    
    out.size = *particleSize * viewportSize->x / 500 / renderingRect->width;
    out.color = rgb[particles[vid].color];
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
    float alpha = 1 - smoothstep(0.2, 0.5, distance);
    return float4(in.color, alpha);
};
