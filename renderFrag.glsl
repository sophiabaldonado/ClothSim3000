uniform sampler2D cloth;
uniform float t;
in vec3 Position;
in vec2 TexCoord;

//  Function from Iñigo Quiles
//  https://www.shadertoy.com/view/MsS3Wc
vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

void main() {
  color = texture(cloth, TexCoord) * vec4(hsb2rgb(vec3(abs(TexCoord.x), 1, .9)), 1);
}
