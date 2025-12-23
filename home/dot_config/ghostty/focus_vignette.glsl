// ============================================================================
// GHOSTTY FOCUS VIGNETTE SHADER
// ============================================================================
// Applies visual feedback based on window focus state:
// - Vignette effect (darkened edges) when unfocused
// - Cursor pulse highlight when focus is gained
//
// FEATURES:
// - Uses iFocus (1.0 = focused, 0.0 = unfocused) for vignette effect
// - Uses iTimeFocus to detect focus transitions and time the pulse
// - Configurable pulse duration and vignette intensity
// - Smooth transitions between states
//
// Copyright (c) 2025 Martin Emde
// ============================================================================

// Configuration constants
const float PULSE_DURATION = 0.15;       // How long the focus pulse lasts (seconds)
const float VIGNETTE_STRENGTH = 0.3;     // How dark the vignette gets (0.0-1.0)
const float VIGNETTE_FALLOFF = 1.4;      // Inner shadow width (lower = thinner shadow, higher = wider)

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Calculate vignette effect - returns darkening factor (0.0 = full dark, 1.0 = no effect)
float vignette(vec2 uv, float strength, float falloff) {
    // Distance from center (0.5, 0.5)
    vec2 pos = uv - 0.5;
    float dist = length(pos);

    // Inner shadow effect - only darkens near the edges
    // Start darkening at distance 0.3, fully dark at 0.7
    float vig = 1.0 - smoothstep(0.3 * falloff, 0.7, dist);

    // Mix between full brightness and darkened
    return mix(1.0 - strength, 1.0, vig);
}

// Calculate focus pulse effect - zooming inward cursor shape
float focusPulse(vec2 fragCoord, vec2 cursorPos, vec2 cursorSize, float timeSinceFocus) {
    // Only show pulse during PULSE_DURATION after gaining focus
    if (timeSinceFocus < 0.0 || timeSinceFocus > PULSE_DURATION) {
        return 0.0;
    }

    // Animation progress: 0.0 at start, 1.0 at end
    float progress = timeSinceFocus / PULSE_DURATION;

    // Start large and zoom inward (scale goes from 8.0 to 1.0)
    float scale = mix(6.0, 1.0, progress);

    // Opacity increases as it zooms in (nearly transparent to opaque)
    float opacity = mix(0.15, 0.8, progress);

    // Calculate scaled cursor rectangle
    vec2 scaledSize = cursorSize * scale;
    vec2 offset = fragCoord - cursorPos;

    // Check if we're inside the scaled cursor rectangle
    vec2 halfSize = scaledSize * 0.5;
    bool insideRect = abs(offset.x) < halfSize.x && abs(offset.y) < halfSize.y;

    // Create soft edges for the cursor shape
    vec2 edgeDist = abs(offset) - halfSize;
    float dist = max(edgeDist.x, edgeDist.y);
    float softEdge = smoothstep(2.0, -2.0, dist);

    return insideRect ? softEdge * opacity : 0.0;
}

// ============================================================================
// MAIN SHADER
// ============================================================================

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;

    // Get the original pixel color from the terminal
    vec4 originalColor = texture(iChannel0, uv);

    // Start with the original color
    vec3 finalColor = originalColor.rgb;

    // ========================================================================
    // VIGNETTE EFFECT - Apply when unfocused (iFocus == 0.0)
    // ========================================================================
    if (iFocus < 0.5) {
        // Surface is unfocused - apply vignette
        float vignetteAmount = vignette(uv, VIGNETTE_STRENGTH, VIGNETTE_FALLOFF);
        finalColor *= vignetteAmount;
    }

    // ========================================================================
    // FOCUS PULSE - Show when focus is gained
    // ========================================================================
    // iTimeFocus is the time when focus was gained, so iTime - iTimeFocus
    // gives us the time since focus was gained
    float timeSinceFocus = iTime - iTimeFocus;

    // Only show pulse when focused and recently gained focus
    if (iFocus > 0.5 && timeSinceFocus >= 0.0 && timeSinceFocus < PULSE_DURATION) {
        vec2 cursorPos = iCurrentCursor.xy;
        vec2 cursorSize = iCurrentCursor.zw;
        float pulse = focusPulse(fragCoord, cursorPos, cursorSize, timeSinceFocus);

        // Blend the cursor color with the original color based on pulse intensity
        vec3 cursorColor = iCurrentCursorColor.rgb;
        finalColor = mix(finalColor, cursorColor, pulse);
    }

    // Output final color
    fragColor = vec4(finalColor, originalColor.a);
}
