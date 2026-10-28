---
name: ghostty-shaders
description: Create, modify, debug, and optimize Ghostty terminal shaders using its Shadertoy-compatible GLSL interface. Use when working on custom Ghostty shader effects, focus behavior, cursor animation, or shader safety and validation.
---

# Ghostty shaders

Shaders live in `home/dot_config/ghostty/shaders/` and are enabled from
`home/dot_config/ghostty/style.ghostty` (`custom-shader = "shaders/NAME.glsl"`, repeatable to
chain; each shader's output is the next one's `iChannel0`). `custom-shader-animation` is
`true` (animate while focused), `false` (render only on terminal updates), or `always`.

Ghostty takes Shadertoy-style GLSL ES 3.0: `void mainImage(out vec4 fragColor, in vec2 fragCoord)`,
with `iChannel0` as the terminal screen.

**A shader that fails to compile can leave the terminal black.** Start from `noop.glsl`, change
one thing at a time, and keep a passthrough path (`fragColor = texture(iChannel0, uv)`).
Avoid the pitfalls that have bitten here: `1.0f` suffixes, HLSL `saturate()` (use `clamp`),
negative input to `sqrt`/`pow`, `mod(x, 0.0)`, uninitialized variables, and a function named
like a variable.

## Uniforms

Supported Shadertoy uniforms: `iChannel0`, `iResolution`, `iTime`, `iTimeDelta`, `iFrame`,
`iChannelResolution`. Not supported: `iMouse`, `iDate`, `iFrameRate`, `iSampleRate`,
`iChannelTime` — remove them when porting from Shadertoy.

Ghostty additions:

```glsl
vec4  iCurrentCursor, iPreviousCursor;            // .xy top-left, .zw width/height
vec4  iCurrentCursorColor, iPreviousCursorColor;
float iTimeCursorChange, iTimeFocus;              // timestamps; elapsed = iTime - t
int   iFocus;                                     // 1 focused, 0 not
```

Terminal shaders run every frame, so gate expensive work on `iFocus == 0` with an early
passthrough return, and keep texture lookups and loops minimal.
