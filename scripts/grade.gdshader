shader_type canvas_item;
// Warm "late afternoon" colour grade for the world (the interface is drawn above it).

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float saturation = 0.9;
uniform float warmth = 0.05;
uniform float contrast = 1.05;
uniform float vignette = 0.32;
uniform vec3 shadow_tint = vec3(0.02, 0.0, 0.035);

void fragment() {
	vec3 c = texture(screen_texture, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation);
	// golden highlights, slightly cool violet shadows
	c += vec3(warmth, warmth * 0.55, -warmth * 0.5) * smoothstep(0.25, 0.85, l);
	c += shadow_tint * (1.0 - smoothstep(0.0, 0.4, l));
	c = (c - 0.5) * contrast + 0.5;
	vec2 d = SCREEN_UV - 0.5;
	c *= 1.0 - dot(d, d) * vignette;
	COLOR = vec4(c, 1.0);
}
