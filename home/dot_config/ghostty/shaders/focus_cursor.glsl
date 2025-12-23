// ============================================================================
// GHOSTTY CURSOR FOCUS SHADER
// ============================================================================
// Displays a zooming cursor highlight animation when the window gains focus.
// Early exits when not in active animation for minimal performance impact.
//
// Copyright (c) 2025 Martin Emde
// ============================================================================

const float PULSE_DURATION = 0.15;  // Animation duration in seconds

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Quick exit: only run during active focus animation
    float timeSinceFocus = iTime - iTimeFocus;
    if (iFocus == 0 || timeSinceFocus < 0.0 || timeSinceFocus > PULSE_DURATION) {
        fragColor = texture(iChannel0, fragCoord / iResolution.xy);
        return;
    }

    vec2 uv = fragCoord / iResolution.xy;
    vec4 originalColor = texture(iChannel0, uv);

    // Animation progress: 0.0 at start, 1.0 at end
    float progress = timeSinceFocus / PULSE_DURATION;

    // Zoom inward: scale from 6x to 1x
    float scale = mix(6.0, 1.0, progress);

    // Fade in: nearly transparent to opaque
    float opacity = mix(0.15, 0.8, progress);

    // Calculate scaled cursor rectangle
    // iCurrentCursor.xy is top-left corner (Y-down coordinate system)
    vec2 cursorSize = iCurrentCursor.zw;
    vec2 cursorCenter = iCurrentCursor.xy + vec2(cursorSize.x * 0.5, -cursorSize.y * 0.5);
    vec2 scaledSize = cursorSize * scale;
    vec2 offset = fragCoord - cursorCenter;
    vec2 halfSize = scaledSize * 0.5;

    // Soft-edged cursor shape
    vec2 edgeDist = abs(offset) - halfSize;
    float dist = max(edgeDist.x, edgeDist.y);
    float softEdge = smoothstep(2.0, -2.0, dist);

    // Only apply inside the scaled rectangle
    bool insideRect = abs(offset.x) < halfSize.x && abs(offset.y) < halfSize.y;
    float pulse = insideRect ? softEdge * opacity : 0.0;

    // Blend cursor color with original
    vec3 finalColor = mix(originalColor.rgb, iCurrentCursorColor.rgb, pulse);
    fragColor = vec4(finalColor, originalColor.a);
}
