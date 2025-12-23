// ============================================================================
// GHOSTTY FOCUS VIGNETTE SHADER
// ============================================================================
// Applies vignette (darkened edges) and subtle bloom when window is unfocused.
// Early exits when focused for minimal performance impact.
//
// Copyright (c) 2025 Martin Emde
// ============================================================================

// Configuration
const float VIGNETTE_STRENGTH = 0.35;  // How dark the vignette gets (0.0-1.0)
const float VIGNETTE_FALLOFF = 0.4;    // Inner shadow width (lower = thinner, higher = wider)
const float BLOOM_INTENSITY = 0.08;    // Bloom strength (0.0-1.0)
const float BLOOM_THRESHOLD = 0.3;     // Minimum luminance to bloom (0.0-1.0)

// Bloom sample positions (golden spiral, 12 samples)
const vec3 bloomSamples[12] = vec3[12](
    vec3(0.169, 0.986, 1.0),
    vec3(-1.333, 0.472, 0.707),
    vec3(-0.846, -1.511, 0.577),
    vec3(1.554, -1.259, 0.5),
    vec3(1.681, 1.474, 0.447),
    vec3(-1.280, 2.089, 0.408),
    vec3(-2.458, -0.980, 0.378),
    vec3(0.587, -2.767, 0.354),
    vec3(2.998, 0.117, 0.333),
    vec3(0.414, 3.135, 0.316),
    vec3(-3.167, 0.984, 0.302),
    vec3(-1.574, -3.086, 0.289)
);

float luminance(vec3 c) {
    return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
}

float vignette(vec2 uv) {
    vec2 pos = uv - 0.5;
    float dist = length(pos);
    float vig = 1.0 - smoothstep(0.3 * VIGNETTE_FALLOFF, 0.7, dist);
    return mix(1.0 - VIGNETTE_STRENGTH, 1.0, vig);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;

    // Quick exit when focused
    if (iFocus == 1) {
        fragColor = texture(iChannel0, uv);
        return;
    }

    // Unfocused: apply vignette + bloom
    vec4 originalColor = texture(iChannel0, uv);
    vec3 finalColor = originalColor.rgb * vignette(uv);

    // Subtle bloom on bright pixels
    vec2 step = vec2(1.414) / iResolution.xy;
    vec3 bloom = vec3(0.0);
    for (int i = 0; i < 12; i++) {
        vec3 s = bloomSamples[i];
        vec3 c = texture(iChannel0, uv + s.xy * step).rgb;
        float l = luminance(c);
        if (l > BLOOM_THRESHOLD) {
            bloom += l * s.z * c;
        }
    }
    finalColor += bloom * BLOOM_INTENSITY;

    fragColor = vec4(finalColor, originalColor.a);
}
