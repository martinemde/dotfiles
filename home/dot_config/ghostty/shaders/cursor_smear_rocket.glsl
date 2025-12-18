// Based on curoser_smear_fade.glsl Copyright (c) 2025 Krone Corylus
// https://github.com/KroneCorylus/ghostty-shader-playground
// Modified version Copyright (c) 2025 Martin Emde

// ============================================================================
// CONFIGURATION - Adjust these to customize the effect
// ============================================================================
const float MIN_DURATION = 0.08; // Fast fade for short jumps
const float MAX_DURATION = 0.3;  // Duration for long jumps
const float LONG_JUMP_THRESHOLD = 0.5; // Distance threshold for "long jump" in normalized space
const float TAPER_FACTOR = 0.15; // How narrow the tail gets (0.0 = point, 1.0 = full width)
const float TRAIL_INTENSITY = 0.8; // Overall trail opacity (0.0 = invisible, 1.0 = full, >1.0 = boosted)
const float GLOW_INTENSITY = 0.0; // Brightness boost at trail tail (0.0 = no glow, 0.5 = subtle, 1.0 = bright)
const float GLOW_FALLOFF = 0.3; // How quickly glow fades (lower = more concentrated at tail)

float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b)
{
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// Based on Inigo Quilez's 2D distance functions article: https://iquilezles.org/articles/distfunctions2d/
// Potencially optimized by eliminating conditionals and loops to enhance performance and reduce branching

float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
    vec2 e = b - a;
    vec2 w = p - a;
    vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
    float segd = dot(p - proj, p - proj);
    d = min(d, segd);

    float c0 = step(0.0, p.y - a.y);
    float c1 = 1.0 - step(0.0, p.y - b.y);
    float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
    float allCond = c0 * c1 * c2;
    float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
    float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
    s *= flip;
    return d;
}

float getSdfParallelogram(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3) {
    float s = 1.0;
    float d = dot(p - v0, p - v0);

    d = seg(p, v0, v3, s, d);
    d = seg(p, v1, v0, s, d);
    d = seg(p, v2, v1, s, d);
    d = seg(p, v3, v2, s, d);

    return s * sqrt(d);
}

vec2 norm(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

float determineStartVertexFactor(vec2 a, vec2 b) {
    // Conditions using step
    float condition1 = step(b.x, a.x) * step(a.y, b.y); // a.x < b.x && a.y > b.y
    float condition2 = step(a.x, b.x) * step(b.y, a.y); // a.x > b.x && a.y < b.y

    // If neither condition is met, return 1 (else case)
    return 1.0 - max(condition1, condition2);
}

float ease(float x) {
    // Quadratic easing - faster finish than cubic
    return pow(1.0 - x, 2.0);
}

vec2 getRectangleCenter(vec4 rect) {
    // Calculate center point of a rectangle (accounts for Y-down coordinate system)
    return vec2(rect.x + rect.z * 0.5, rect.y - rect.w * 0.5);
}

// ============================================================================
// ROCKET CURSOR TRAIL SHADER
// ============================================================================
// This shader creates a tapered "rocket trail" effect when the cursor moves.
// The trail is widest at the current cursor position and tapers to a point
// at the previous cursor position, creating a speed-streak effect.
//
// KEY FEATURES:
// 1. Fuzzy edge alpha blending using smoothstep for soft, natural fade
// 2. Tapered trail (wide at cursor, narrow at origin point)
// 3. Both spatial AND temporal fading for proper disappearance
//    - Spatial: fade along the trail length (current -> previous position)
//    - Temporal: fade over time (trail disappears after DURATION)
// 4. Masking prevents trails from persisting forever
// 5. Quadratic easing for snappy, responsive feel
// 6. Optional glow effect for enhanced visual impact
// 7. Multiple early exits for optimal performance
//
// PERFORMANCE NOTES:
// - Frame-rate independent animation using (iTime - iTimeCursorChange)
// - Early exits skip rendering when effect is inactive or complete
// - Optimized distance calculations minimize expensive operations
// ============================================================================

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // ========================================================================
    // SETUP: Get the previous frame and normalize coordinates
    // ========================================================================
    // Cache UV coordinate to avoid repeated division
    vec2 uv = fragCoord.xy / iResolution.xy;

    // Start with the previous frame's output - this is critical because
    // we're drawing trails over time and need to see previous frames
    // Cache the texture fetch to avoid duplicate lookup later
    vec4 prevFrame = texture(iChannel0, uv);
    fragColor = prevFrame;

    // Skip cursor trail effect when window is unfocused
    if (iFocus == 0) {
        return;
    }

    // Normalize pixel coordinates to -1..1 space for SDF calculations
    // This makes distance calculations resolution-independent
    vec2 vu = norm(fragCoord, 1.);
    vec2 offsetFactor = vec2(-.5, 0.5);

    // Pre-compute normalized pixel values for trail rendering
    // Computed once here instead of inline to avoid repeated calculations
    float shrinkAmount = 12.0 / iResolution.y;   // norm(vec2(6., 6.), 0.).x - 6px inward
    float fuzzyEdgeWidth = 16.0 / iResolution.y; // norm(vec2(8., 8.), 0.).x - 8px fuzzy edge

    // ========================================================================
    // CURSOR DATA: Normalize cursor positions and sizes
    // ========================================================================
    // Convert cursor data from pixel space to normalized space (-1..1)
    // .xy = position, .zw = width/height
    vec4 currentCursor = vec4(norm(iCurrentCursor.xy, 1.), norm(iCurrentCursor.zw, 0.));
    vec4 previousCursor = vec4(norm(iPreviousCursor.xy, 1.), norm(iPreviousCursor.zw, 0.));

    // ========================================================================
    // EARLY EXIT: Skip expensive calculations for tiny cursor movements
    // ========================================================================
    // Calculate cursor centers and distance traveled
    vec2 centerCC = getRectangleCenter(currentCursor);
    vec2 centerCP = getRectangleCenter(previousCursor);

    // Use squared distance for early exit to avoid expensive sqrt()
    vec2 delta = centerCC - centerCP;
    float lineLengthSq = dot(delta, delta);

    // Skip effect for tiny jumps (1-2 character movements)
    // This prevents stuttering during character-by-character scrolling
    float minJumpThreshold = currentCursor.z * 2.0; // 2 character widths
    float minJumpThresholdSq = minJumpThreshold * minJumpThreshold;
    if (lineLengthSq < minJumpThresholdSq) {
        return; // No trail effect for small movements
    }

    // Only compute sqrt when we actually need the distance
    float lineLength = sqrt(lineLengthSq);

    // ========================================================================
    // PARALLELOGRAM GEOMETRY: Create the tapered trail shape
    // ========================================================================
    // Determine which corner of the cursor to use as the starting vertex
    // This ensures the parallelogram connects the cursors correctly based
    // on direction of movement (handles diagonal movements properly)
    float vertexFactor = determineStartVertexFactor(currentCursor.xy, previousCursor.xy);
    float invertedVertexFactor = 1.0 - vertexFactor;

    // TAPER EFFECT: Create the "rocket trail" by making the old position narrow
    // Current position uses full cursor dimensions, previous uses TAPER_FACTOR
    // This creates the characteristic narrowing effect - like a speed streak
    vec2 currentWidth = currentCursor.zw;
    vec2 previousWidth = currentCursor.zw * TAPER_FACTOR;

    // Define the four vertices of the tapered parallelogram
    // v0, v1 = current cursor position (full width)
    // v2, v3 = previous cursor position (tapered width)
    vec2 v0 = vec2(currentCursor.x + currentWidth.x * vertexFactor, currentCursor.y - currentWidth.y);
    vec2 v1 = vec2(currentCursor.x + currentWidth.x * invertedVertexFactor, currentCursor.y);
    vec2 v2 = vec2(previousCursor.x + previousWidth.x * invertedVertexFactor, previousCursor.y);
    vec2 v3 = vec2(previousCursor.x + previousWidth.x * vertexFactor, previousCursor.y - previousWidth.y);

    // ========================================================================
    // DISTANCE FIELDS: Calculate signed distance to cursor and trail
    // ========================================================================
    // SDF (Signed Distance Field) gives us smooth, anti-aliasable edges
    // Negative = inside shape, Positive = outside shape, 0 = on edge
    float sdfCurrentCursor = getSdfRectangle(vu, currentCursor.xy - (currentCursor.zw * offsetFactor), currentCursor.zw * 0.5);
    float sdfTrail = getSdfParallelogram(vu, v0, v1, v2, v3);

    // ========================================================================
    // ANIMATION TIMING: Dynamic duration based on jump distance
    // ========================================================================
    // Short jumps fade quickly, long jumps fade slowly (linear interpolation)
    float duration = mix(MIN_DURATION, MAX_DURATION, clamp(lineLength / LONG_JUMP_THRESHOLD, 0.0, 1.0));

    // progress: 0.0 at cursor move -> 1.0 after duration seconds
    float progress = clamp((iTime - iTimeCursorChange) / duration, 0.0, 1.0);

    // easedProgress: 1.0 at start -> 0.0 at end (inverted for fade-out)
    // Quadratic easing provides faster finish than cubic (less lingering tail)
    float easedProgress = ease(progress);

    // ========================================================================
    // EARLY EXIT: Skip rendering if animation is complete
    // ========================================================================
    if (progress >= 1.0) {
        return; // Animation finished, no trail to render
    }

    // ========================================================================
    // VAPOR TRAIL EFFECT: Semi-transparent particles fading with distance
    // ========================================================================

    // Calculate spatial fade: strongest near current cursor, fading toward previous position
    // This creates the "particle trail" effect where opacity decreases with distance
    float distFromCurrent = distance(vu, centerCC);
    float spatialFade = lineLength > 0.001 ? 1.0 - clamp(distFromCurrent / lineLength, 0.0, 1.0) : 1.0;

    // Shrink trail and add fuzzy edges for softer, more vapor-like appearance
    // Shrink by 6 pixels to tighten the core, then extend fuzzy edge to 8 pixels
    float trailMask = 1.0 - smoothstep(0., fuzzyEdgeWidth, sdfTrail + shrinkAmount);

    // CRITICAL MASKING - Only show trail within animated distance
    // Combine distance mask with trail mask early to avoid unnecessary blending
    float animatedDistance = easedProgress * lineLength;
    float distanceMask = smoothstep(animatedDistance * 1.1, animatedDistance * 0.9, distFromCurrent);
    float combinedMask = trailMask * distanceMask;

    // ========================================================================
    // EARLY EXIT: Skip blending if completely masked out
    // ========================================================================
    if (combinedMask < 0.001) {
        return; // No visible trail at this pixel
    }

    // ========================================================================
    // COLOR AND ALPHA: Apply gradient, glow, and intensity
    // ========================================================================
    // Color gradient from source (previous cursor) to destination (current cursor)
    // spatialFade = 1.0 at current cursor -> use iCurrentCursorColor
    // spatialFade = 0.0 at previous cursor -> use iPreviousCursorColor
    vec4 gradientColor = mix(iPreviousCursorColor, iCurrentCursorColor, spatialFade);

    // Combine all fading: combined mask * spatial fade * temporal fade * intensity
    float alpha = combinedMask * spatialFade * easedProgress * TRAIL_INTENSITY;

    // Apply trail with color gradient and alpha blending
    vec4 trailColor = gradientColor;

    // Optional glow effect: boost brightness at the tail for "energy" feel
    // GLOW_INTENSITY controls the effect strength, GLOW_FALLOFF controls distribution
    if (GLOW_INTENSITY > 0.0) {
        // Glow is strongest at the tail (low spatialFade) and fades toward cursor
        float glowFactor = pow(1.0 - spatialFade, GLOW_FALLOFF) * GLOW_INTENSITY;
        trailColor.rgb *= 1.0 + glowFactor;
    }

    trailColor.a = alpha;
    fragColor = mix(prevFrame, trailColor, trailColor.a);
}
