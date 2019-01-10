#include "Utils.ih"

/**
    Composes source and destination colors according to specified alpha
   correction
    @param src Source RGBA color
    @param dst Returned destination RGBA color
    @param alphaCorrection Alpha correction used to blend colors
*/
inline void composite(const varying vec4f& src, varying vec4f& dst,
                      const varying float alphaCorrection)
{
    const float alpha =
        1.f - pow(1.f - min(src.w, 1.f - 1.f / 256.f), alphaCorrection);
    const float a = alpha * (1.f - dst.w);
    dst.x = dst.x + src.x * a;
    dst.y = dst.y + src.y * a;
    dst.z = dst.z + src.z * a;
    dst.w += (alpha * (1.f - dst.w));
}

inline float sign(const float v)
{
    return v > 0 ? 1.f : v == 0.f ? 0.f : -1.f;
}

inline vec3f sign(const vec3f& v)
{
    return make_vec3f(sign(v.x), sign(v.y), sign(v.z));
}

inline vec3f mod(const vec3f& v, const int m)
{
    return make_vec3f(v.x - m * floor(v.x / m), v.y - m * floor(v.y / m),
                      v.z - m * floor(v.z / m));
}

inline vec3f mod(const vec3f& v, const vec3f& u)
{
    return v - u * floor(v / u);
}

inline float smoothstep(const float edge0, const float edge1, float x)
{
    float t;
    t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
}

inline float mix(const float x, const float y, const float a)
{
    return x * (1.f - a) + y * a;
}

uniform bool seedInitialized = false;
struct RNGState rngState;

inline float getRandomValue(varying ScreenSample&, const int)
{
    float r;
    int nbMaxTries = 10;
    while (nbMaxTries >= 0 && rdrand(&r) == false)
        --nbMaxTries;
    return r;
}

inline vec3f getRandomVector(const unsigned int, varying ScreenSample& sample,
                             const vec3f& normal, const int randomNumber)
{
    if (!seedInitialized)
    {
        seed_rng(&rngState, programIndex);
        seedInitialized = true;
    }

    const float rx = getRandomValue(sample, randomNumber) - 0.5f;
    const float ry = getRandomValue(sample, randomNumber) - 0.5f;
    const float rz = getRandomValue(sample, randomNumber) - 0.5f;
    return normalize(normal + make_vec3f(rx, ry, rz));
}
