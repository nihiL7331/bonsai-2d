layout(binding=0) uniform texture2D uTex;
layout(binding=1) uniform texture2D uFontTex;
layout(binding=0) uniform sampler uDefaultSampler;

in vec2 vPosition;
in vec4 vColor;
in vec2 vUv;
in vec2 vLocalUv;
in vec2 vSize;
in vec4 vBytes;
in vec4 vColorOverride;
in vec4 vParams;

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

bool hasFlag(int flags, int flag) {
  return (flags & flag) != 0;
}
