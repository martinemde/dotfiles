# Shader Patterns

Working starting points for the effects Ghostty's terminal-specific uniforms make possible. Each gates on `iFocus` — copy that part even when adapting the rest.

## Basic Passthrough (Template)

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    fragColor = texture(iChannel0, uv);
}
```

## Focus-Aware Blur

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

## Focus Transition Animation

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

## Cursor Highlighting

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

## Cursor Trail Effect

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

## CRT Effect

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
