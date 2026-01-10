@header package shaders
@include shader_header.glsl

// NOTE: VERTEX SHADER
@vs vs
@include shader_vs_core.glsl

void main() {
  gl_Position = getProjectedPosition(aPosition);

  passVertexData();
}
@end

// NOTE: FRAGMENT SHADER
@fs fs
@include shader_fs_core.glsl

out vec4 oColor;

void main() {
  vec4 texColor = getTexColor(vBytes, vUv);

  oColor = texColor * vColor;

  oColor.rgb = mix(oColor.rgb, vColorOverride.rgb, vColorOverride.a);
}
@end

@program quad vs fs
