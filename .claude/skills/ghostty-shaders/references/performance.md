# Performance

Terminal shaders run on every frame the terminal is visible, so the budget is tighter than a Shadertoy demo's. These four moves account for most of the difference.

## 1. Gate on Focus State

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

## 2. Optimize Texture Lookups

```glsl
// BAD: Multiple lookups of same coordinate
vec4 color1 = texture(iChannel0, uv);
vec4 color2 = texture(iChannel0, uv);

// GOOD: Single lookup, reuse
vec4 baseColor = texture(iChannel0, uv);
vec4 modified = baseColor * someValue;
```

## 3. Use Cheap Approximations

```glsl
// Expensive
float x = sin(a) / cos(a);

// Cheaper
float x = tan(a);

// For distance fields, consider:
float fastLength = max(abs(v.x), abs(v.y));  // Cheaper than length(v)
```

## 4. Minimize Branching

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
