// @overview
// The configuration header for all bonsai shaders.
// It maps **GLSL** types to their **Odin** equivalents in the [`bonsai:core/gmath`](https://bonsai-framework.dev/reference/core/gmath) package
// and handles standard imports for the `sokol-shdc` compiler.
//
// :::note[Usage]
// ```glsl
// @header package game_shaders
// @include shader_header.glsl
// ```
// :::

/**/

// @ref
// Imports the **Sokol** GFX bindings for the generated **Odin** code.
@header import sg "bonsai:libs/sokol/gfx"

// @ref
// Imports the [`bonsai:core/gmath`](https://bonsai-framework.dev/reference/core/gmath) package.
@header import "bonsai:core/gmath"

// @ref
// Maps **GLSL** `vec4` to Odin [`gmath.Vector4`](https://bonsai-framework.dev/reference/core/gmath/#vector4).
@ctype vec4 gmath.Vector4

// @ref
// Maps **GLSL** `mat4` to Odin [`gmath.Matrix4`](https://bonsai-framework.dev/reference/core/gmath/#matrix4).
@ctype mat4 gmath.Matrix4

