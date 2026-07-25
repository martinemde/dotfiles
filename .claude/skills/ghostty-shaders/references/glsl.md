# GLSL ES 3.0 Reference

Language reference for the dialect Ghostty compiles: GLSL ES 3.0 (WebGL 2.0). Covers types, swizzling, the built-in math and texture functions, control flow, structs, and function declaration rules.

## Data Types

```glsl
// Scalars
float x = 1.0;          // Note: NO 'f' suffix
int i = 1;
uint u = 1U;
bool b = true;

// Vectors
vec2 v2 = vec2(1.0, 2.0);
vec3 v3 = vec3(1.0, 2.0, 3.0);
vec4 v4 = vec4(1.0, 2.0, 3.0, 4.0);

// Integer vectors
ivec2, ivec3, ivec4
uvec2, uvec3, uvec4
bvec2, bvec3, bvec4

// Matrices
mat2, mat3, mat4
mat2x3, mat3x2, etc.

// Samplers
sampler2D, sampler3D, samplerCube
```

## Vector Swizzling

```glsl
vec4 color = vec4(1.0, 2.0, 3.0, 4.0);

color.xy     // vec2(1.0, 2.0)
color.rgb    // vec3(1.0, 2.0, 3.0)
color.bgr    // vec3(3.0, 2.0, 1.0)
color.xxxx   // vec4(1.0, 1.0, 1.0, 1.0)
color.zyxw   // vec4(3.0, 2.0, 1.0, 4.0)

// Can use .xyzw, .rgba, or .stpq
```

## Essential Math Functions

```glsl
// Trigonometry
sin(x), cos(x), tan(x)
asin(x), acos(x), atan(y, x)

// Exponential
pow(x, y), exp(x), log(x)
sqrt(x), inversesqrt(x)

// Common
abs(x), sign(x)
floor(x), ceil(x), fract(x)
min(x, y), max(x, y)
clamp(x, minVal, maxVal)
mod(x, y)

// Interpolation
mix(x, y, a)              // Linear: x*(1-a) + y*a
step(edge, x)             // 0 if x < edge, else 1
smoothstep(edge0, edge1, x)  // Smooth 0-1 transition

// Vector
length(v), distance(p0, p1)
dot(v1, v2), cross(v1, v2)
normalize(v)
reflect(I, N), refract(I, N, eta)
```

## Texture Sampling

```glsl
// Standard sampling
texture(iChannel0, uv)                    // Auto LOD
textureLod(iChannel0, uv, lod)           // Explicit LOD
textureGrad(iChannel0, uv, dPdx, dPdy)   // Explicit gradients

// Fetching
texelFetch(iChannel0, ivec2(x, y), lod)  // Direct pixel access
textureSize(iChannel0, lod)               // Get texture dimensions
```

## Control Flow

```glsl
// Conditionals
if (condition) {
    // ...
} else if (other) {
    // ...
} else {
    // ...
}

// Loops
for (int i = 0; i < 10; i++) {
    // ...
}

while (condition) {
    // ...
}

// Switch (GLSL ES 3.0)
switch (value) {
    case 0:
        // ...
        break;
    case 1:
        // ...
        break;
    default:
        // ...
}
```

## Structs and Arrays

```glsl
// Struct definition
struct Light {
    vec3 position;
    vec3 color;
    float intensity;
};

// Usage
Light myLight = Light(vec3(0.0, 10.0, 0.0), vec3(1.0, 1.0, 1.0), 1.0);
vec3 pos = myLight.position;

// Arrays
float values[5] = float[](1.0, 2.0, 3.0, 4.0, 5.0);
float first = values[0];
```

## Functions

```glsl
// Function definition
float myFunction(float x, float y) {
    return x * y + sin(x);
}

// Parameter qualifiers
void modifyValue(inout float x) {
    x *= 2.0;
}

void getValues(out float x, out float y) {
    x = 1.0;
    y = 2.0;
}
```
