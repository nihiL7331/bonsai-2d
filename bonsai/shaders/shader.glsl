// @overview
// The default shader used by the framework.
// It implements the standard rendering pipeline for sprites, text and geometry.
//
// This shader is automatically loaded by [`init`](https://bonsai-framework.dev/reference/core/render/#init)
// and serves as the baseline for all 2D rendering. Copying this file is a good way to start writing custom shaders.
//
// **Features:**
// - Projects vertices using the global [`viewProjectionMatrix`](https://bonsai-framework.dev/reference/core/render/#shaderglobals).
// - Supports both Sprite and Font rendering (via [`getTexColor`](https://bonsai-framework.dev/reference/shaders/include/shader_fs_core/#gettexcolor)).
// - Handles vertex colors (tinting).
// - Handles color overrides.

@header package shaders
@include shader_header.glsl

@vs vs
@include shader_vs_core.glsl

// @ref
// The standard vertex entry point.
//
// Projects the vertex position into clip space via [`getProjectedPosition`](https://bonsai-framework.dev/reference/shaders/include/shader_vs_core/#getprojectedposition).
//
// Passes all standard attributes to the fragment stage via [`passVertexData`](https://bonsai-framework.dev/reference/shaders/include/shader_vs_core/#passvertexdata).
void main() {
  gl_Position = getProjectedPosition(aPosition);

  passVertexData();
}
@end

@fs fs
@include shader_fs_core.glsl

out vec4 oColor;

// @ref
// The standard fragment entry point.
//
// Fetches the base color via [`getTexColor`](https://bonsai-framework.dev/reference/shaders/include/shader_fs_core/#gettexcolor).
//
// Multiplies by the vertex [`vColor`](https://bonsai-framework.dev/reference/shaders/include/shader_fs_core/#vcolor) (tint).
//
// Mixes in the [`vColorOverride`](https://bonsai-framework.dev/reference/shaders/include/shader_fs_core/#vcoloroverride).
void main() {
  vec4 texColor = getTexColor(vBytes, vUv);

  oColor = texColor * vColor;

  oColor.rgb = mix(oColor.rgb, vColorOverride.rgb, vColorOverride.a);
}
@end

@program quad vs fs
