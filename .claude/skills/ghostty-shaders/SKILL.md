---
name: ghostty-shaders
description: Write, debug, and optimize custom GLSL shaders for the Ghostty terminal. Covers Ghostty's Shadertoy-compatible GLSL ES 3.0 dialect, its terminal-specific uniforms (cursor position and color, focus state, event timestamps), the unsupported Shadertoy uniforms, focus-gated performance patterns, and adapting shaders from shadertoy.com. Use when creating or editing a .glsl file for Ghostty, diagnosing a shader that renders black or fails to compile, or setting custom-shader config.
---

# Ghostty Shaders

Ghostty compiles Shadertoy-compatible GLSL ES 3.0 (WebGL 2.0) with terminal-specific
extensions. `iChannel0` is the live terminal screen rather than an uploaded image, and the
shader runs continuously while the terminal is visible — which makes performance and failure
behavior matter more than they do on shadertoy.com.

## A broken shader can lock you out

An invalid shader renders Ghostty as a black screen, including the window you would use to
fix it. Keep a known-good shader to fall back to, build up from a passthrough rather than
pasting a finished effect, and keep a non-Ghostty terminal reachable while iterating.

The compile failures that cause this are mostly a short list:

- `1.0f` — no `f` suffix on float literals in GLSL ES
- `saturate()` — doesn't exist here; use `clamp(x, 0.0, 1.0)`
- Negative input to `sqrt()` or `pow()` — wrap with `abs()` or `max(0.0, x)`
- `mod(x, 0.0)` — division by zero
- Uninitialized variables — no implicit zero
- A function and a variable sharing a name

## Configuration

```
# Single shader
custom-shader = ~/.config/ghostty/shaders/crt.glsl

# Multiple shaders chain: each one's output becomes the next one's iChannel0
custom-shader = ~/.config/ghostty/shaders/blur.glsl
custom-shader = ~/.config/ghostty/shaders/vignette.glsl

# Animation control
custom-shader-animation = true     # Default: animate when focused
custom-shader-animation = false    # Static: only render on terminal updates
custom-shader-animation = always   # Always animate (CPU intensive)
```

## Entry point

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // fragCoord: pixel coordinates (0,0 = bottom-left)
    // fragColor: output RGBA color
    vec2 uv = fragCoord.xy / iResolution.xy;
}
```

## Uniforms

Standard Shadertoy uniforms Ghostty provides:

```glsl
sampler2D iChannel0;           // Terminal screen texture (or previous shader output)
vec3 iResolution;              // [width, height, 1.0] in pixels
float iTime;                   // Seconds since first frame
float iTimeDelta;              // Seconds since last frame
int iFrame;                    // Frame count
vec3 iChannelResolution[4];    // iChannelResolution[0] == iResolution
```

Not supported — a shader referencing these won't compile:

```glsl
float iFrameRate;
vec4 iMouse;
vec4 iDate;
float iSampleRate;             // N/A
float iChannelTime[4];         // N/A
```

Ghostty-specific extensions, which are what make terminal-aware effects possible:

```glsl
vec4 iCurrentCursor;           // .xy = top-left corner, .zw = width/height
vec4 iPreviousCursor;          // Previous cursor position/size
vec4 iCurrentCursorColor;      // RGBA of current cursor
vec4 iPreviousCursorColor;     // RGBA of previous cursor
float iTimeCursorChange;       // Timestamp when cursor changed
float iTimeFocus;              // Timestamp when surface gained focus
int iFocus;                    // 1 = focused, 0 = unfocused
```

The timestamps are absolute, so animations key off the elapsed time:

```glsl
float timeSinceCursorChange = iTime - iTimeCursorChange;
float timeSinceFocus = iTime - iTimeFocus;
```

## Working shape

Nearly every shader here has the same skeleton — an unfocused early-exit to a plain
passthrough, then the effect:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;

    if (iFocus == 0) {
        fragColor = texture(iChannel0, uv);
        return;
    }

    vec4 color = texture(iChannel0, uv);
    fragColor = color;
}
```

That early exit does double duty: it's the cheapest performance win available, and it means a
background window keeps rendering readable text even if the effect above it is wrong.

## Adapting from Shadertoy

`mainImage` is already the right signature, so the work is in the differences: check the
uniform list above for anything unsupported, strip `iMouse` interaction, add focus gating that
Shadertoy has no concept of, and expect `iChannel0` to be text rather than a photograph —
effects tuned on a photo often destroy legibility. Optimize harder than the original, since a
terminal shader runs all day rather than while a tab is open.

Testing complex math on shadertoy.com first is usually faster than iterating in a terminal you
can render unusable.

## References

- `references/patterns.md` — focus-aware blur, focus transitions, cursor highlight and trail,
  CRT; the terminal-specific effects worth copying rather than deriving
- `references/effects.md` — grayscale, sepia, chromatic aberration, pixelate, hash noise
- `references/glsl.md` — GLSL ES 3.0 types, swizzling, math and texture builtins, control
  flow, structs, function rules
- `references/performance.md` — focus gating, texture lookup reuse, cheap approximations,
  branch elimination
- `references/debugging.md` — visualizing UV/time/focus state as color, isolating a failing
  effect behind a safe fallback, incremental build order

## External

- [GLSL ES 3.0 spec](https://www.khronos.org/registry/OpenGL/specs/es/3.0/GLSL_ES_Specification_3.00.pdf)
- [Shadertoy](https://www.shadertoy.com)
- [OpenGL reference pages](https://www.khronos.org/registry/OpenGL-Refpages/gl4/)
