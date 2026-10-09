shader_type spatial;
render_mode cull_disabled, depth_draw_always;

uniform vec3 shallow_color : source_color = vec3(0.15, 0.55, 0.65);
uniform vec3 deep_color : source_color = vec3(0.03, 0.18, 0.42);
uniform float wave_scale = 0.04;
uniform float wave_speed = 0.6;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

varying vec3 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float w = sin(v_world.x * 0.05 + TIME * wave_speed) * 0.15 + sin(v_world.z * 0.07 + TIME * wave_speed * 1.3) * 0.1;
	VERTEX.y += w;
}

void fragment() {
	vec2 p = v_world.xz * wave_scale;
	float n = noise(p + TIME * 0.15) * 0.6 + noise(p * 3.1 - TIME * 0.1) * 0.4;
	float depth_fac = clamp(n * 0.4 + 0.3, 0.0, 1.0);
	vec3 col = mix(deep_color, shallow_color, depth_fac);
	// normal perturbation for sparkle
	float dx = noise(p * 4.0 + TIME * 0.2) - noise(p * 4.0 + vec2(0.05, 0.0) + TIME * 0.2);
	float dz = noise(p * 4.0 + TIME * 0.2) - noise(p * 4.0 + vec2(0.0, 0.05) + TIME * 0.2);
	NORMAL = normalize(NORMAL + vec3(dx, 0.0, dz) * 1.5);
	ALBEDO = col;
	ROUGHNESS = 0.08;
	METALLIC = 0.1;
	SPECULAR = 0.7;
	ALPHA = 0.9;
}
