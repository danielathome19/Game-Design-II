shader_type canvas_item;

uniform float intensity;

void fragment() {
	vec4 baseColor = vec4(1.0, 0.0, 0.0, 0.0);
	baseColor.a = intensity * 0.8;
	COLOR = baseColor;
}
