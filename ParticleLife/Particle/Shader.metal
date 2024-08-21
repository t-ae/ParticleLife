#include <metal_stdlib>
#include "Types.h"
using namespace metal;

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
float l05Distance(vector_float2 vector) {
    return pow(pow(abs(vector.x), 0.5) + pow(abs(vector.y), 0.5), 2);
}

float l02Distance(vector_float2 vector) {
    return pow(pow(abs(vector.x), 0.2) + pow(abs(vector.y), 0.2), 5);
}

float l1Distance(vector_float2 vector) {
    return abs(vector.x) + abs(vector.y);
}

float linfDistance(vector_float2 vector) {
    if(isnan(vector.x)) return NAN; // if vector.y is NaN, max returns NaN.
    return max(abs(vector.x), abs(vector.y));
}

/// Referred https://qiita.com/7CIT/items/fe33b9b341b9918b6c3d
/// Modified to return 1 when (x,y) = (0, -1).
float triangularDistance(vector_float2 vector) {
    float a = atan2(vector.x, vector.y);
    float r = M_PI_F * 2 / 3;
    return cos(floor(0.5+a/r)*r-a) * length(vector) / cos(r*0.5);
}

float pentagonalDistance(vector_float2 vector) {
    float a = atan2(vector.x, vector.y);
    float r = M_PI_F * 2 / 5;
    return cos(floor(0.5+a/r)*r-a) * length(vector) / cos(r*0.5);
}

// MARK: - Kernel functions
kernel void
updateVelocity(device Particle* particles [[ buffer(0) ]],
               constant uint *particleCount [[ buffer(1) ]],
               constant uint *colorCount [[ buffer(2) ]],
               constant float* attraction [[ buffer(3) ]],
               constant VelocityUpdateSetting *velocityUpdateSetting [[ buffer(4) ]],
               constant float *dt [[ buffer(5) ]],
               const uint gid [[ thread_position_in_grid ]])
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
    }
    
    float (*distanceFunction)(vector_float2);
    if(velocityUpdateSetting->distanceFunction == DistanceFunction_l1) {
        distanceFunction = l1Distance;
    } else if(velocityUpdateSetting->distanceFunction == DistanceFunction_l2) {
        distanceFunction = length;
    } else if(velocityUpdateSetting->distanceFunction == DistanceFunction_linf) {
        distanceFunction = linfDistance;
    } else if(velocityUpdateSetting->distanceFunction == DistanceFunction_l05) {
        distanceFunction = l05Distance;
    } else if(velocityUpdateSetting->distanceFunction == DistanceFunction_l02) {
        distanceFunction = l02Distance;
    } else if(velocityUpdateSetting->distanceFunction == DistanceFunction_triangular) {
        distanceFunction = triangularDistance;
    } else if(velocityUpdateSetting->distanceFunction == DistanceFunction_pentagonal) {
        distanceFunction = pentagonalDistance;
    }
    
    vector_float2 position = particles[gid].position;
    constant float* attractionRow = attraction + particles[gid].color * *colorCount;
    
    vector_float2 accel(0, 0);
    uint attractorCount = 0;
    for(uint i = 0 ; i < *particleCount ; i++) {
        if(i == gid) continue;
        
        vector_float2 vector = particles[i].position - position;
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
        
        if(!(linfDistance(vector) < rmax)) {
            // Ignore too large distance and NaN.
            continue;
        }
        
        float attr = attractionRow[particles[i].color];
        float distance = distanceFunction(vector);
        
        float f = forceFunction(distance/rmax, attr);
        accel += vector / distance * f;
        if(distance < rmax) {
            attractorCount++;
        }
    }
    
    particles[gid].velocity *= pow(0.5, *dt/velocityHalfLife); // friction
    particles[gid].velocity += rmax * accel * velocityUpdateSetting->forceFactor * *dt;
    particles[gid].attractorCount = attractorCount;
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

// MARK: - Particle vertex/fragment shader
struct Point {
    vector_float4 position [[position]];
    float size [[point_size]];
    vector_float3 color;
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
particleVertex(const device Particle* particles [[ buffer(0) ]],
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
    
    out.size = *particleSize * viewportSize->x / renderingRect->width / 500;
    out.color = rgb[particles[vid].color];
    return out;
}

fragment vector_float4
particleFragment(Point in [[stage_in]],
                 vector_float2 pointCoord [[point_coord]])
{
    float distance = length(pointCoord - float2(0.5));
    if(distance < 0.2) {
        float alpha = 0.9;
        return vector_float4(in.color, alpha);
    } if(distance < 0.5) {
        float alpha = 1.0 - smoothstep(0, 0.5, distance);
        return vector_float4(in.color, alpha);
    } else {
        discard_fragment();
        return vector_float4();
    }
};
