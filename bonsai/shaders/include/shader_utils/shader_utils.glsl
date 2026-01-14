// @overview
// Common utility functions for color manipulation and UV calculations.
//
// :::note[Usage]
// ```glsl
// @include shader_utils.glsl
// ```
// :::

/**/

// @ref
// Converts a color from **RGB** space to **HSV** space.
// Based on Sam Hocevar's optimized [implementation](https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl).
vec3 rgbToHsv(vec3 c) {
  vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
  vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

  float d = q.x - min(q.w, q.y);
  float e = 1.0e-10;
  return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// @ref
// Converts a color from **HSV** space back to **RGB** space.
//
// **Arguments:**
// - `c`: Input color in HSV space.
vec3 hsvToRgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// @ref
// Decodes a standard hex integer (e.g. `0xFFFF00`) into a normalized RGB vector.
//
// **Arguments:**
// - `hex`: An integer representing the color.
//
// Returns a normalized **RGB** color (`0.0` to `1.0`).
vec3 hexToRgb(int hex) {
  return vec3(
      float((hex >> 16) & 0xFF),
      float((hex >> 8 ) & 0xFF),
      float((hex      ) & 0xFF)
      ) / 255.0;
}

// @ref
// Compares two `vec3` with a tolerance threshold.
//
// **Arguments:**
// - `a`: `vec3`.
// - `b`: `vec3`.
// - `epsilon`: The allowed difference.
//
// :::tip
// Useful for floating point comparisons where `==` is unreliable.
// :::
bool almostEquals(vec3 a, vec3 b, float epsilon) {
  return all(lessThan(abs(a - b), vec3(epsilon)));
}

// @ref
// Remaps a 0-1 local UV coordinate into the specific UV range of a sprite in the atlas.
// Handles wrapping (repeating textures) within the sub-rect.
//
// **Arguments:**
// - `localUv`: The UV relative to the sprite.
// - `atlasRect`: The UV bounds of the sprite in the atlas.
//
// Returns the UV coordinate to sample from the atlas texture.
vec2 localUvToAtlasUv(vec2 localUv, vec4 atlasRect) {
  vec2 size = atlasRect.zw - atlasRect.xy;

  vec2 wrapped = fract(localUv);

  const float epsilon = 0.0001;
  wrapped = clamp(wrapped, vec2(epsilon), vec2(1.0 - epsilon));

  return atlasRect.xy + (size * wrapped);
}

// @ref
// Converts a color to grayscale using standard luminance weights.
//
// **Arguments:**
// - `color`: The **RGB** color to desaturate.
//
// Returns the luminance float (brightness).
float luminance(vec3 color) {
  return dot(color, vec3(0.299, 0.587, 0.114));
}

// @ref 
// Remaps a value from one range to another.
// Shader equivalent of the [`remap`](https://bonsai-framework.dev/reference/core/gmath/#remap) function.
//
// **Arguments:**
// - `input`: Incoming value.
// - `inMin`, `inMax`: The range of the input.
// - `outMin`, `outMax`: The range of the output.
float remap(float input, float inMin, float inMax, float outMin, float outMax) {
  return outMin + (input - inMin) * (outMax - outMin) / (inMax - inMin);
}

// @ref
// Generates a pseudo random float in the `0.0` - `1.0` range.
//
// **Arguments:**
// - `uv`: A `seed` vector (e.g. UV coordinates).
// 
// :::tip
// Useful for static noise, dissolve patterns, dithering.
// :::
//
// **Source:** [this](https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner) stackoverflow question.
float random(vec2 seed) {
  return fract(sin(dot(seed, vec2(12.9898, 78.233))) * 43758.5453);
}

// @ref
// Rotates a 2D vector around a pivot point.
//
// **Counter-clockwise rotation**
//
// **Arguments:**
// - `vector`: The vector to rotate.
// - `pivot`: The center of rotation.
// - `angle`: Rotation angle in **radians**.
vec2 rotate(vec2 uv, vec2 pivot, float angle) {
  mat2 rotation = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
  return (rotation * (uv - pivot)) + pivot;
}
