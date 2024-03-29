/* Copyright (c) 2018, Cyrille Favreau
 * All rights reserved. Do not distribute without permission.
 * Responsible Author: Cyrille Favreau <cyrille.favreau@gmail.com>
 *
 * This file is part of the reseach Brayns module
 * <https://github.com/favreau/Brayns-Research-Modules>
 *
 * This library is free software; you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License version 3.0 as published
 * by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include "../../../common/commonTypes.h"
#include "Utils.ih"

#include <ospray/SDK/lights/Light.ih>
#include <ospray/SDK/render/Renderer.ih>

struct FractalsRenderer
{
    Renderer super;

    // Rendering attributes
    const uniform Light* uniform* uniform lights;
    uint32 numLights;
    vec3f bgColor;
    float shadows;
    float softShadows;
    float minShadingThreshold;
    float maxShadingThreshold;
    FractalType fractalType;
    uint32 maxIterations;
    float param1;
    float param2;
    int randomNumber;
    float exposure;

    // Transfer function / Color map attributes
    uniform vec4f* uniform colorMap;
    uniform vec3f* uniform emissionIntensitiesMap;
    uint32 colorMapSize;
    float colorMapMinValue;
    float colorMapRange;

    // Volume dimension
    vec3f volumeDimensions;
    uint32 volumeSamplesPerRay;
};

inline varying bool intersectBox(const varying Ray& ray, const vec3f& aabbMin,
                                 const vec3f& aabbMax, varying float& t0,
                                 varying float& t1)
{
    Ray r = ray;
    vec3f invR = 1.f / r.dir;
    vec3f tbot = invR * (aabbMin - r.org);
    vec3f ttop = invR * (aabbMax - r.org);
    vec3f tmin = min(ttop, tbot);
    vec3f tmax = max(ttop, tbot);
    vec2f t = make_vec2f(max(tmin.x, tmin.y), max(tmin.x, tmin.z));
    t0 = max(t.x, t.y);
    t = make_vec2f(min(tmax.x, tmax.y), min(tmax.x, tmax.z));
    t1 = min(t.x, t.y);
    return (t0 <= t1);
}

inline uint8 getMandelBulbContribution(
    const uniform FractalsRenderer* uniform self, const vec3f& point)
{
    const float power = self->param1;
    const vec3f P = self->param2 * point - make_vec3f(0.125f);
    vec3f w = P;
    float m = dot(w, w);

    vec4f trap = make_vec4f(abs(w), m);
    float dz = 1.f;

    int i = 0;
    for (i = 0; i < 4; i++)
    {
        dz = power * pow(sqrt(m), 7.f) * dz + 1.f;

        float r = length(w);
        float b = power * acos(w.y / r);
        float a = power * atan2(w.x, w.z);
        w = P + pow(r, power) *
                    make_vec3f(sin(b) * sin(a), cos(b), sin(b) * cos(a));

        trap = min(trap, make_vec4f(abs(w), m));

        m = dot(w, w);
        if (m > 256.f)
            break;
    }

    const float value = clamp(512.f * log(m) * sqrt(m) / dz, 0.f, 255.f);
    return (uint8)value;
}

inline varying uint8 getJuliaContribution(
    const uniform FractalsRenderer* uniform self, const vec3f& point)
{
    const float cRe = self->param1;
    const float cIm = self->param2 + 3.f * point.z;

    float newRe = 1.5f * point.x / 0.5f;
    float newIm = point.y / 0.5f;

    uint8 n = 0;
    for (n = 0; n < self->maxIterations; ++n)
    {
        float oldRe = newRe;
        float oldIm = newIm;
        newRe = oldRe * oldRe - oldIm * oldIm + cRe;
        newIm = 2.f * oldRe * oldIm + cIm;
        if ((newRe * newRe + newIm * newIm) > 4.f)
            break;
    }
    return n;
}

inline varying vec4f getVoxelColor(const uniform FractalsRenderer* uniform self,
                                   const vec3f& point)
{
    uint8 voxelValue;
    switch (self->fractalType)
    {
    case julia:
        voxelValue = getJuliaContribution(self, point);
        break;
    case mandelbulb:
        voxelValue = getMandelBulbContribution(self, point);
        break;
    default:
        return make_vec4f(1.f, 0.f, 0.f, 1.f);
    }

#if 1
    const float v = 5.f * (float)voxelValue / (float)self->maxIterations;
    const float a =
        (v >= self->minShadingThreshold && v < self->maxShadingThreshold) ? 0.1f
                                                                          : 0.f;
    return make_vec4f(0.5f + v * 0.5f, v, 1.f - v * 0.5f, a);
#else
    const float normalizedValue =
        clamp(((float)voxelValue - self->colorMapMinValue) /
                  (float)self->colorMapRange,
              0.f, 1.f);

    // Voxel color according to colormap value
    return self->colorMap[self->colorMapSize * normalizedValue];
#endif
}

inline float getShadowContribution(const uniform FractalsRenderer* uniform self,
                                   varying ScreenSample& sample,
                                   const vec3f point, const float epsilon)
{
    float pathOpacity = 0.f;
    for (uniform int i = 0;
         pathOpacity < 1.f && self->lights && i < self->numLights; ++i)
    {
        const uniform Light* uniform light = self->lights[i];
        const varying vec2f s = make_vec2f(0.5f);
        DifferentialGeometry dg;
        dg.P = point;
        const varying Light_SampleRes lightSample = light->sample(light, dg, s);

        Ray ray;
        ray.dir = lightSample.dir;
        ray.org = point;
        float t0, t1;
        const vec3f aabbmin = make_vec3f(-0.5f);
        const vec3f aabbmax = make_vec3f(0.5f);
        if (!intersectBox(ray, aabbmin, aabbmax, t0, t1))
            break;

        t0 = max(0, t0);

        for (float t = t1; pathOpacity < 1.f && t > t0; t -= epsilon)
        {
            const vec3f p = ray.org + t * ray.dir;
            const vec4f voxelColor = getVoxelColor(self, p);
            pathOpacity += voxelColor.w;
        }
    }
    return pathOpacity;
}

inline vec3f FractalsRenderer_shadeRay(
    const uniform FractalsRenderer* uniform self, varying ScreenSample& sample)
{
    vec4f pathColor = make_vec4f(0.f);
    float pathOpacity = 0.f;

    float t0, t1;
    const vec3f aabbmin = make_vec3f(0.f);
    const vec3f aabbmax = make_vec3f(1.f);
    if (!intersectBox(sample.ray, aabbmin, aabbmax, t0, t1))
        return make_vec3f(self->bgColor);

    t0 = max(0.f, t0);
    t0 -= getRandomValue(sample, self->randomNumber) * ((t1 - t0) * 0.01f);

    const float epsilon = max(0.001f, 1.f / (float)(self->volumeSamplesPerRay));

    for (float t = t0; pathOpacity < 1.f && t < t1; t += epsilon)
    {
        const vec3f point = (sample.ray.org + t * sample.ray.dir) - 0.5f;
        vec4f voxelColor = getVoxelColor(self, point);

        // Shadow
        if (sample.sampleID.z > 0 && self->shadows > 0.f && voxelColor.w > 0.f)
        {
            const float alpha =
                1.f - self->shadows *
                          getShadowContribution(self, sample, point, epsilon);
            voxelColor.x *= alpha;
            voxelColor.y *= alpha;
            voxelColor.z *= alpha;
        }
        pathOpacity += voxelColor.w;
        pathColor.w = pathOpacity;

        composite(voxelColor, pathColor, 1.f);
    }

    // Combine with background color
    const vec4f bgColor = make_vec4f(self->bgColor, 1.f);
    composite(bgColor, pathColor, 1.f);

    sample.alpha = pathOpacity;
    sample.z = t0;

    return clamp(self->exposure * make_vec3f(pathColor), make_vec3f(0.f),
                 make_vec3f(1.f));
}

void FractalsRenderer_renderSample(uniform Renderer* uniform _self,
                                   void* uniform perFrameData,
                                   varying ScreenSample& sample)
{
    uniform FractalsRenderer* uniform self =
        (uniform FractalsRenderer * uniform) _self;
    sample.rgb = FractalsRenderer_shadeRay(self, sample);
}

// Exports (called from C++)
export void* uniform FractalsRenderer_create(void* uniform cppE)
{
    uniform FractalsRenderer* uniform self =
        uniform new uniform FractalsRenderer;
    Renderer_Constructor(&self->super, cppE);
    self->super.renderSample = FractalsRenderer_renderSample;
    return self;
}

export void FractalsRenderer_set(
    void* uniform _self, const uniform vec3f& bgColor,
    const uniform FractalType& fractalType, const uniform float& shadows,
    const uniform float& softShadows, const uniform float& minShadingThreshold,
    const uniform float& maxShadingThreshold, const uniform int32 maxIterations,
    const uniform int& randomNumber, const uniform float& param1,
    const uniform float& param2, void** uniform lights,
    const uniform int32 numLights, const uniform int32& volumeSamplesPerRay,
    uniform vec4f* uniform colormap,
    uniform vec3f* uniform emissionIntensitiesMap,
    const uniform int32 colorMapSize, const uniform float& colorMapMinValue,
    const uniform float& colorMapRange, const uniform float& exposure)
{
    uniform FractalsRenderer* uniform self =
        (uniform FractalsRenderer * uniform) _self;

    self->bgColor = bgColor;
    self->shadows = shadows;
    self->softShadows = softShadows;
    self->minShadingThreshold = minShadingThreshold;
    self->maxShadingThreshold = maxShadingThreshold;
    self->maxIterations = maxIterations;
    self->randomNumber = randomNumber;
    self->param1 = param1;
    self->param2 = param2;
    self->fractalType = fractalType;
    self->exposure = exposure;

    self->lights = (const uniform Light* uniform* uniform)lights;
    self->numLights = numLights;

    self->colorMap = (uniform vec4f * uniform) colormap;
    self->emissionIntensitiesMap =
        (uniform vec3f * uniform) emissionIntensitiesMap;
    self->colorMapSize = colorMapSize;
    self->colorMapMinValue = colorMapMinValue;
    self->colorMapRange = colorMapRange;

    self->volumeSamplesPerRay = volumeSamplesPerRay;
    self->volumeDimensions = make_vec3f(1.f);
}
