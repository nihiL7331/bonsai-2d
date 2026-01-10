layout(binding=0) uniform ShaderData {
  mat4 uViewProjectionMatrix;
};

in vec2 aPosition;
in vec4 aColor;
in vec2 aUv;
in vec2 aLocalUv;
in vec2 aSize;
in vec4 aBytes;
in vec4 aColorOverride;
in vec4 aParams;

out vec2 vPosition;
out vec4 vColor;
out vec2 vUv;
out vec2 vLocalUv;
out vec2 vSize;
out vec4 vBytes;
out vec4 vColorOverride;
out vec4 vParams;

vec4 getProjectedPosition(vec2 position) {
  return uViewProjectionMatrix * vec4(position, 0.0, 1.0);
}

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
