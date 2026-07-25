# Effects Library

Drop-in fragments for common color and sampling effects. Each assumes `uv` is already computed and focus gating is already in place.

## Grayscale

```glsl
vec4 color = texture(iChannel0, uv);
float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
fragColor = vec4(vec3(gray), color.a);
```

## Sepia

```glsl
vec4 color = texture(iChannel0, uv);
float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
vec3 sepia = vec3(gray) * vec3(1.2, 1.0, 0.8);
fragColor = vec4(sepia, color.a);
```

## Chromatic Aberration

```glsl
float offset = 0.002;
vec2 uv = fragCoord.xy / iResolution.xy;

float r = texture(iChannel0, uv + vec2(offset, 0.0)).r;
float g = texture(iChannel0, uv).g;
float b = texture(iChannel0, uv - vec2(offset, 0.0)).b;

fragColor = vec4(r, g, b, 1.0);
```

## Pixelate

```glsl
float pixelSize = 4.0;
vec2 pixelatedUV = floor(fragCoord / pixelSize) * pixelSize / iResolution.xy;
fragColor = texture(iChannel0, pixelatedUV);
```

## Noise (Random)

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
