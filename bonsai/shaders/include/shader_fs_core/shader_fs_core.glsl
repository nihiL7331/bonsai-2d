// @overview
// The standard Fragment Shader package.
// Handles texture lookups, sprite/text switching, and basic coloring.
//
// :::note[Usage]
// ```glsl
// @fs fs
// @include shader_fs_core.glsl
//
// void main() { ... }
// ```
// :::

/**/

// @ref
// **Binding 0 (Texture):** The main sprite atlas.
// Sampled when `textureIndex == 0`.
layout(binding=0) uniform texture2D uTex;

// @ref
// **Binding 1 (Texture):** The font atlas.
// Sampled when `textureIndex == 1`. Stores font data in the **Red** color channel.
layout(binding=1) uniform texture2D uFontTex;

// @ref
// **Binding 0 (Sampler):** The default sampler state.
// Shared by both texture atlases.
layout(binding=0) uniform sampler uDefaultSampler;

// @ref
// **Input:** Interpolated world space position of the fragment.
// Z position is used for depth.
in vec3 vPosition;

// @ref
// **Input:** Vertex color (multiplied by sprite color).
in vec4 vColor;

// @ref
// **Input:** Texture coordinates for the atlas.
in vec2 vUv;

// @ref
// **Input:** Local UV coordinates relative to the sprite itself.
// :::tip
// Useful for procedural effects (e.g. borders, gradients) regardless of atlas position.
// :::
in vec2 vLocalUv;

// @ref
// **Input:** World space size of the sprite **in pixels**.
in vec2 vSize;

// @ref
// **Input:** Packed data passed from the vertex attributes.
// - `x`: Texture index (0 = `Sprite`, 1 = `Font`)
in vec4 vBytes;

// @ref
// **Input:** Color override.
// - `rgb`: The tint color.
// - `a`: The blend strength (`0.0` = off, `1.0` = full override)
// :::tip
// Useful for damage flashes or solid tints.
// :::
in vec4 vColorOverride;

// @ref
// **Input:** Custom parameters passed via [`Vertex.parameters`](https://bonsai-framework.dev/reference/core/render/#vertex)
in vec4 vParams;

// @ref
// Retreives the correct pixel color for the current fragment.
//
// This function automatically detects if the primitive is a `Sprite` or a `Text`
// based on the `bytes` data and samples the correct atlas accordingly.
//
// **Arguments:**
// - `bytes`: The `vBytes` varying passed from the vertex shader.
// - `uv`: The texture coordinates.
//
// :::note[Example]
// ```glsl
// vec4 texColor = getTexColor(vBytes, vUv);
// oColor = texColor * vColor;
// oColor.rgb = mix(oColor.rgb, vColorOverride.rgb, vColorOverride.a);
// ```
// :::
vec4 getTexColor(vec4 bytes, vec2 uv) {
  int texIndex = int(bytes.x * 255.0 + 0.5);
  vec4 texColor = vec4(1.0);
  if (texIndex == 0) {
    texColor = texture(sampler2D(uTex, uDefaultSampler), uv);
  } else if (texIndex == 1) {
    texColor.a = texture(sampler2D(uFontTex, uDefaultSampler), uv).r;
  }

  return texColor;
}

// @ref
// Helper to check if a specific bit is set in an integer bitmask.
// 
// **Arguments:**
// - `flags`: The integer containing all flags.
// - `flag`: The specific bit to check.
//
// :::tip
// Useful for decoding `vBytes.z` (QuadFlags).
// :::
bool hasFlag(int flags, int flag) {
  return (flags & flag) != 0;
}
