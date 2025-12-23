# Ghostty Shader Development Skill

## Overview

This skill provides comprehensive guidance for creating and editing custom shaders for Ghostty terminal. Ghostty uses Shadertoy-compatible GLSL ES 3.0 (WebGL 2.0) shaders with additional terminal-specific extensions.

## When to Use This Skill

- Creating new Ghostty shaders from scratch
- Modifying existing Ghostty shaders
- Debugging shader compilation issues
- Optimizing shader performance for terminal usage
- Implementing focus-aware shader effects
- Working with terminal cursor animations

## Critical Safety Notes

**SHADER SAFETY**: Invalid shaders can render Ghostty completely unusable (black screen). Always:

1. Test shaders incrementally with simple effects first
2. Keep a backup of working shaders
3. Provide fallback behavior (especially for unfocused states)
4. Initialize all variables explicitly
5. Validate shader compilation before deployment

**COMMON PITFALLS TO AVOID**:

- `1.0f` notation (use `1.0` only - no 'f' suffix)
- `saturate()` function (use `clamp(x, 0.0, 1.0)`)
- Negative values to `sqrt()` or `pow()` (wrap with `abs()` or `max(0.0, x)`)
- Division by zero in `mod(x, 0.0)`
- Uninitialized variables (always initialize!)
- Function names matching variable names

## Ghostty Shader Architecture

### Configuration

```toml
custom-shader = /path/to/shader.glsl
# In ghostty config
custom-shader-animation = true # true (focused), false (static), always
```

Multiple shaders chain together - output of one becomes `iChannel0` input of the next.

### Shader Entry Point

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // fragCoord: pixel coordinates (0,0 = bottom-left)
    // fragColor: output RGBA color

    // Typical UV calculation
    vec2 uv = fragCoord.xy / iResolution.xy;

    // Your shader code here
}
```

## Standard Shadertoy Uniforms

### Available in Ghostty

```glsl
sampler2D iChannel0;           // Terminal screen texture (or previous shader output)
vec3 iResolution;              // [width, height, 1.0] in pixels
float iTime;                   // Seconds since first frame
float iTimeDelta;              // Seconds since last frame
int iFrame;                    // Frame count
vec3 iChannelResolution[4];    // iChannelResolution[0] == iResolution
```

### NOT Currently Supported

```glsl
float iFrameRate;              // NOT SUPPORTED
vec4 iMouse;                   // NOT SUPPORTED
vec4 iDate;                    // NOT SUPPORTED
float iSampleRate;             // NOT SUPPORTED (N/A)
float iChannelTime[4];         // NOT SUPPORTED (N/A)
```

## Ghostty-Specific Extensions

These are unique to Ghostty and enable terminal-aware effects:

```glsl
// Cursor position and dimensions
vec4 iCurrentCursor;           // .xy = top-left corner, .zw = width/height
vec4 iPreviousCursor;          // Previous cursor position/size

// Cursor colors
vec4 iCurrentCursorColor;      // RGBA of current cursor
vec4 iPreviousCursorColor;     // RGBA of previous cursor

// Timing events
float iTimeCursorChange;       // Timestamp when cursor changed
float iTimeFocus;              // Timestamp when surface gained focus

// Focus state
int iFocus;                    // 1 = focused, 0 = unfocused
```

### Computing Time Since Events

```glsl
float timeSinceCursorChange = iTime - iTimeCursorChange;
float timeSinceFocus = iTime - iTimeFocus;
```

## Performance Best Practices

### 1. Gate on Focus State

Unfocused surfaces don't need to animate. Skip expensive effects when unfocused:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;

    // Early exit when unfocused - passthrough only
    if (iFocus == 0) {
        fragColor = texture(iChannel0, uv);
        return;
    }

    // Expensive effects only when focused
    // ...
}
```

### 2. Optimize Texture Lookups

```glsl
// BAD: Multiple lookups of same coordinate
vec4 color1 = texture(iChannel0, uv);
vec4 color2 = texture(iChannel0, uv);

// GOOD: Single lookup, reuse
vec4 baseColor = texture(iChannel0, uv);
vec4 modified = baseColor * someValue;
```

### 3. Use Cheap Approximations

```glsl
// Expensive
float x = sin(a) / cos(a);

// Cheaper
float x = tan(a);

// For distance fields, consider:
float fastLength = max(abs(v.x), abs(v.y));  // Cheaper than length(v)
```

### 4. Minimize Branching

```glsl
// BAD: Many branches
if (condition1) {
    // ...
} else if (condition2) {
    // ...
} else if (condition3) {
    // ...
}

// BETTER: Use step/mix for simple cases
float factor = step(threshold, value);
vec4 result = mix(colorA, colorB, factor);
```

## Common Shader Patterns

### Basic Passthrough (Template)

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    fragColor = texture(iChannel0, uv);
}
```

### Focus-Aware Blur

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;

    if (iFocus == 1) {
        // Sharp when focused
        fragColor = texture(iChannel0, uv);
        return;
    }

    // Blur when unfocused
    vec4 color = vec4(0.0);
    float kernel = 0.0;

    for (float x = -2.0; x <= 2.0; x += 1.0) {
        for (float y = -2.0; y <= 2.0; y += 1.0) {
            vec2 offset = vec2(x, y) / iResolution.xy;
            float weight = 1.0;
            color += texture(iChannel0, uv + offset) * weight;
            kernel += weight;
        }
    }

    fragColor = color / kernel;
}
```

### Focus Transition Animation

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 baseColor = texture(iChannel0, uv);

    if (iFocus == 0) {
        fragColor = baseColor;
        return;
    }

    // Animate for 0.3s after gaining focus
    float timeSinceFocus = iTime - iTimeFocus;
    float progress = clamp(timeSinceFocus / 0.3, 0.0, 1.0);

    // Smooth easing
    float ease = smoothstep(0.0, 1.0, progress);

    // Example: flash effect
    vec3 flash = vec3(1.0);
    fragColor = vec4(mix(flash, baseColor.rgb, ease), baseColor.a);
}
```

### Cursor Highlighting

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 baseColor = texture(iChannel0, uv);

    if (iFocus == 0) {
        fragColor = baseColor;
        return;
    }

    // Check if current pixel is within cursor bounds
    vec2 cursorStart = iCurrentCursor.xy;
    vec2 cursorSize = iCurrentCursor.zw;
    vec2 cursorEnd = cursorStart + cursorSize;

    bool inCursor = fragCoord.x >= cursorStart.x &&
                    fragCoord.x <= cursorEnd.x &&
                    fragCoord.y >= cursorStart.y &&
                    fragCoord.y <= cursorEnd.y;

    if (inCursor) {
        // Pulse cursor
        float pulse = 0.5 + 0.5 * sin(iTime * 3.0);
        fragColor = mix(baseColor, iCurrentCursorColor, pulse * 0.5);
    } else {
        fragColor = baseColor;
    }
}
```

### Cursor Trail Effect

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 baseColor = texture(iChannel0, uv);

    if (iFocus == 0) {
        fragColor = baseColor;
        return;
    }

    // Time since cursor moved
    float timeSinceMove = iTime - iTimeCursorChange;
    float trailDuration = 0.5;

    if (timeSinceMove < trailDuration) {
        // Check if in previous cursor position
        vec2 prevStart = iPreviousCursor.xy;
        vec2 prevSize = iPreviousCursor.zw;
        vec2 prevEnd = prevStart + prevSize;

        bool inPrevCursor = fragCoord.x >= prevStart.x &&
                           fragCoord.x <= prevEnd.x &&
                           fragCoord.y >= prevStart.y &&
                           fragCoord.y <= prevEnd.y;

        if (inPrevCursor) {
            float fade = 1.0 - (timeSinceMove / trailDuration);
            vec4 trailColor = iPreviousCursorColor;
            fragColor = mix(baseColor, trailColor, fade * 0.3);
            return;
        }
    }

    fragColor = baseColor;
}
```

### CRT Effect

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;

    if (iFocus == 0) {
        fragColor = texture(iChannel0, uv);
        return;
    }

    // Scanlines
    float scanline = sin(fragCoord.y * 3.14159 * 2.0) * 0.1;

    // Slight barrel distortion
    vec2 cc = uv - 0.5;
    float dist = dot(cc, cc) * 0.2;
    vec2 distortedUV = uv + cc * dist;

    vec4 color = texture(iChannel0, distortedUV);
    color.rgb -= scanline;

    // Vignette
    float vignette = smoothstep(0.7, 0.2, length(cc));
    color.rgb *= vignette;

    fragColor = color;
}
```

## GLSL Language Reference

### Data Types

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

### Vector Swizzling

```glsl
vec4 color = vec4(1.0, 2.0, 3.0, 4.0);

color.xy     // vec2(1.0, 2.0)
color.rgb    // vec3(1.0, 2.0, 3.0)
color.bgr    // vec3(3.0, 2.0, 1.0)
color.xxxx   // vec4(1.0, 1.0, 1.0, 1.0)
color.zyxw   // vec4(3.0, 2.0, 1.0, 4.0)

// Can use .xyzw, .rgba, or .stpq
```

### Essential Math Functions

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

### Texture Sampling

```glsl
// Standard sampling
texture(iChannel0, uv)                    // Auto LOD
textureLod(iChannel0, uv, lod)           // Explicit LOD
textureGrad(iChannel0, uv, dPdx, dPdy)   // Explicit gradients

// Fetching
texelFetch(iChannel0, ivec2(x, y), lod)  // Direct pixel access
textureSize(iChannel0, lod)               // Get texture dimensions
```

### Control Flow

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

### Structs and Arrays

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

### Functions

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

## Debugging Strategies

### Visual Debugging

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;

    // Debug: Visualize UV coordinates
    fragColor = vec4(uv.x, uv.y, 0.0, 1.0);

    // Debug: Visualize time
    // fragColor = vec4(fract(iTime), 0.0, 0.0, 1.0);

    // Debug: Visualize focus state
    // fragColor = iFocus == 1 ? vec4(0.0, 1.0, 0.0, 1.0) : vec4(1.0, 0.0, 0.0, 1.0);
}
```

### Safe Fallbacks

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 baseColor = texture(iChannel0, uv);

    // Always have a safe fallback path
    fragColor = baseColor;

    // Try experimental effect
    #ifdef EXPERIMENTAL
        // Risky code here
        vec4 experimental = someComplexEffect(uv);

        // Only apply if valid
        if (!isnan(experimental.r) && !isinf(experimental.r)) {
            fragColor = experimental;
        }
    #endif
}
```

### Gradual Development

1. Start with passthrough
2. Add focus gating
3. Add simple effect
4. Test compilation
5. Iterate with complexity
6. Profile performance

## Common Effects Library

### Grayscale

```glsl
vec4 color = texture(iChannel0, uv);
float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
fragColor = vec4(vec3(gray), color.a);
```

### Sepia

```glsl
vec4 color = texture(iChannel0, uv);
float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
vec3 sepia = vec3(gray) * vec3(1.2, 1.0, 0.8);
fragColor = vec4(sepia, color.a);
```

### Chromatic Aberration

```glsl
float offset = 0.002;
vec2 uv = fragCoord.xy / iResolution.xy;

float r = texture(iChannel0, uv + vec2(offset, 0.0)).r;
float g = texture(iChannel0, uv).g;
float b = texture(iChannel0, uv - vec2(offset, 0.0)).b;

fragColor = vec4(r, g, b, 1.0);
```

### Pixelate

```glsl
float pixelSize = 4.0;
vec2 pixelatedUV = floor(fragCoord / pixelSize) * pixelSize / iResolution.xy;
fragColor = texture(iChannel0, pixelatedUV);
```

### Noise (Random)

```glsl
// Simple hash function
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// In mainImage:
float noise = hash(fragCoord.xy + fract(iTime));
vec4 color = texture(iChannel0, uv);
fragColor = color + vec4(vec3(noise * 0.1), 0.0);
```

## Development Workflow

1. **Start Simple**: Begin with passthrough template
2. **Add Focus Gating**: Always gate expensive effects on `iFocus`
3. **Test Incrementally**: Add one feature at a time
4. **Use shadertoy.com**: Test complex logic in browser first
5. **Safe Defaults**: Initialize all variables, add bounds checks
6. **Profile**: Monitor CPU usage with `custom-shader-animation` settings
7. **Version Control**: Keep working shaders backed up
8. **Document**: Comment complex math and non-obvious effects

## Conversion from Shadertoy

When adapting Shadertoy shaders:

1. **Keep `mainImage` signature**: Already compatible
2. **Check uniforms**: Some may not be supported
3. **Add focus gating**: Shadertoy doesn't have `iFocus`
4. **Remove mouse interactions**: `iMouse` not supported
5. **Test textures**: `iChannel0` is terminal screen, not uploaded image
6. **Performance**: Terminal shaders run constantly; optimize more aggressively

## Configuration Tips

```
# Single shader
custom-shader = ~/.config/ghostty/shaders/crt.glsl

# Multiple shaders (chain)
custom-shader = ~/.config/ghostty/shaders/blur.glsl
custom-shader = ~/.config/ghostty/shaders/vignette.glsl

# Animation control
custom-shader-animation = true     # Default: animate when focused
custom-shader-animation = false    # Static: only render on terminal updates
custom-shader-animation = always   # Always animate (CPU intensive!)
```

## Resources

- **GLSL ES Spec**: https://www.khronos.org/registry/OpenGL/specs/es/3.0/GLSL_ES_Specification_3.00.pdf
- **Shadertoy**: https://www.shadertoy.com
- **OpenGL Reference**: https://www.khronos.org/registry/OpenGL-Refpages/gl4/

## Quick Reference Card

```glsl
// Essential template
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;

    // ALWAYS gate on focus for performance
    if (iFocus == 0) {
        fragColor = texture(iChannel0, uv);
        return;
    }

    // Your effect here
    vec4 color = texture(iChannel0, uv);

    // Modify color...

    fragColor = color;
}
```

**Golden Rules**:

- No 'f' suffix on floats
- Use `clamp()` not `saturate()`
- Protect `sqrt()` and `pow()` with `abs()` or `max(0.0, x)`
- Initialize all variables
- Always provide focus-gated fallback
- Test incrementally
