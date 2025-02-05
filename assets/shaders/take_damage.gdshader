shader_type canvas_item;

uniform float intensity;

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 basecolor = vec4(1.0, 0.0, 0.0, 0.0);
	basecolor.a = intensity * 0.8;
	COLOR = basecolor;
}