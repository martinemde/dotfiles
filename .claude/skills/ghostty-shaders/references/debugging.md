# Debugging

## Visual Debugging

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

## Safe Fallbacks

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

## Gradual Development

1. Start with passthrough
2. Add focus gating
3. Add simple effect
4. Test compilation
5. Iterate with complexity
6. Profile performance
