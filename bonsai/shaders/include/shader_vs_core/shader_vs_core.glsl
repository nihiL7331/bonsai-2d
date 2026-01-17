// @overview
// The standard Vertex Shader package.
// Defines the crucial attribute layout that matches the [`Vertex`](https://bonsai-framework.dev/reference/core/render/#vertex)
// struct in **Odin** and provides helpers for coordinate space transformation.
//
// :::note[Usage]
// ```glsl
// @vs vs
// @include shader_vs_code.glsl
//
// void main() { ... }
// ```
// :::

/**/

// @ref
// **Binding 0:** The global shader data.
// Automatically uploaded by [`flushBatch`](https://bonsai-framework.dev/reference/core/render/#flushbatch).
layout(binding=0) uniform ShaderData {
  mat4 uViewProjectionMatrix;
};

// @ref
// **Location 0:** World space position (x, y).
// Z position is used for depth.
in vec3 aPosition;

// @ref
// **Location 1:** Vertex color (rgba).
in vec4 aColor;

// @ref
// **Location 2:** Atlas texture coordinates (u, v).
in vec2 aUv;

// @ref
// **Location 3:** Local UVs (0-1)
in vec2 aLocalUv;

// @ref
// **Location 4:** Size of the sprite **in pixels**.
in vec2 aSize;

// @ref
// **Location 5:** Packed data (texture index, layer, flags).
in vec4 aBytes;

// @ref
// **Location 6:** Color override.
in vec4 aColorOverride;

// @ref
// **Location 7:** Custom parameters for user shaders.
in vec4 aParams;

out vec3 vPosition;
out vec4 vColor;
out vec2 vUv;
out vec2 vLocalUv;
out vec2 vSize;
out vec4 vBytes;
out vec4 vColorOverride;
out vec4 vParams;

// @ref
// Transforms a raw 2D world position into **clip space** (screen coordinates).
// Applies the current camera and projection matrices.
//
// **Arguments:**
// - `position`: World space position.
//
// :::note[Example]
// ```glsl
// gl_Position = getProjectedPosition(aPosition);
// ```
// :::
vec4 getProjectedPosition(vec2 position) {
  return uViewProjectionMatrix * vec4(position, 0.0, 1.0);
}

// @ref
// Passes all standard attributes (color, UVs, flags, etc.) to the **Fragment Shader**.
// :::caution
// Must be called at the end of your vertex `main` function.
// :::
void passVertexData() {
  vPosition = aPosition;
  vColor = aColor;
  vUv = aUv;
  vLocalUv = aLocalUv;
  vSize = aSize;
  vBytes = aBytes;
  vColorOverride = aColorOverride;
  vParams = aParams;
}
