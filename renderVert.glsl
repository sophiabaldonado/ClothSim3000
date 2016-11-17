in vec2 texCoord;
out vec2 TexCoord;
out vec3 Position;

void main() {
  TexCoord = texCoord;
  Position = position;
  gl_Position = lovrProjection * lovrTransform * vec4(position, 1.0);
}
