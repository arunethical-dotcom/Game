shader_type canvas_item;
// Warm late-afternoon light over the world (the interface is drawn above it):
//  - sun shafts falling diagonally from the upper left, fixed to the world
//  - a soft golden glow from the sun's corner of the sky
//  - dust specks drifting through the beams
//  - colour grade: golden highlights, cool shadows, light vignette

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform vec2 cam_pos = vec2(0.0);       // world position of the screen's top-left corner
uniform vec2 view_size = vec2(960.0, 540.0);
// The grade is kept gentle on purpose: the art's own colours are the reference. Each
// environment (outdoors, throne hall, bedrooms, library, kitchen, dungeon) has its own
// profile, blended in by grade.gd; time of day tints the outdoor profile.
uniform float saturation = 1.0;
uniform float contrast = 1.03;
uniform float exposure = 1.0;            // overall brightness of the ambient light
uniform vec3 ambient = vec3(1.0);        // colour of the ambient light (multiplies the scene)
uniform vec3 hi_tint = vec3(0.025, 0.014, -0.012);  // added to highlights
uniform vec3 lo_tint = vec3(0.0);        // added to shadows (cool for stone, warm for wood)
uniform float vignette = 0.16;
uniform vec3 sun_color = vec3(1.0, 0.88, 0.62);
uniform float shaft_strength = 0.22;
uniform float glow_strength = 0.16;
uniform float indoor = 0.0;              // 0 outside, 1 under a roof: no sun beams or sky glow

float hash(float n) { return fract(sin(n) * 43758.5453); }
float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float noise1(float x) {
	float i = floor(x);
	float f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(hash(i), hash(i + 1.0), f);
}

void fragment() {
	vec3 c = texture(screen_texture, SCREEN_UV).rgb;
	vec2 world = cam_pos + SCREEN_UV * view_size;

	// --- sun shafts: bands across the light direction, slowly drifting
	vec2 ray_dir = normalize(vec2(0.42, 1.0));
	vec2 across = vec2(ray_dir.y, -ray_dir.x);
	float u = dot(world, across);
	float v = dot(world, ray_dir);
	float t = TIME * 0.04;
	float n = noise1(u / 150.0 + t) * 0.65 + noise1(u / 47.0 - t * 1.7 + 11.0) * 0.35;
	// a soft halo around each beam plus a brighter core
	float shaft = smoothstep(0.44, 0.76, n) * 0.55 + smoothstep(0.68, 0.82, n) * 0.6;
	// each shaft fades in and out along its length so they look like broken beams
	shaft *= 0.45 + 0.55 * smoothstep(0.2, 0.8, noise1(v / 380.0 + u / 900.0 + 3.0));

	// --- glow from the sun beyond the upper-left corner of the screen
	float glow = exp(-length((SCREEN_UV - vec2(-0.15, -0.25)) * vec2(1.0, 1.4)) * 2.1);

	// --- dust specks floating in the light, one per 36 px cell at most
	vec2 cell = floor(world / 36.0);
	float has = step(0.86, hash2(cell));
	vec2 drift = vec2(sin(TIME * 0.6 + hash2(cell + 7.0) * 6.28) * 4.0, mod(TIME * 6.0 + hash2(cell + 3.0) * 36.0, 36.0));
	vec2 mote = cell * 36.0 + vec2(hash2(cell + 1.0), hash2(cell + 2.0)) * 30.0 + drift;
	float dust = has * step(length(world - mote), 1.1) * (0.5 + 0.5 * sin(TIME * 2.0 + hash2(cell) * 20.0));

	float sky = 1.0 - indoor;   // no sun beams, sky glow or dust under a roof
	vec3 light = sky * (sun_color * (shaft * shaft_strength + glow * glow_strength) + sun_color * dust * shaft * 0.9);
	c = c + light * (1.0 - c);   // screen blend: brightens without blowing out

	// --- colour grade (per environment)
	c *= ambient * exposure;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation);
	c += hi_tint * smoothstep(0.35, 0.9, l);
	c += lo_tint * (1.0 - smoothstep(0.05, 0.45, l));
	c = (c - 0.5) * contrast + 0.5;
	vec2 d = SCREEN_UV - 0.5;
	c *= 1.0 - dot(d, d) * vignette;
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
