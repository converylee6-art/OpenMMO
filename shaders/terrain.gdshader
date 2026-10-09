shader_type spatial;
render_mode cull_back;

uniform sampler2D colormap : source_color, filter_linear;
uniform vec2 world_size = vec2(4096.0, 2240.0);
uniform float sea_level = 25.0;
uniform vec3 rock_color : source_color = vec3(0.42, 0.38, 0.34);
uniform vec3 snow_color : source_color = vec3(0.93, 0.95, 0.98);
uniform vec3 sand_color : source_color = vec3(0.85, 0.78, 0.56);

varying vec3 v_world;
varying vec3 v_normal_w;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal_w = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 uv = v_world.xz / world_size;
	vec3 base = texture(colormap, uv).rgb;
	float n1 = noise(v_world.xz * 0.08);
	float n2 = noise(v_world.xz * 0.6);
	float detail = 0.85 + 0.3 * n1 * 0.5 + 0.15 * n2;
	vec3 col = base * detail;
	float slope = 1.0 - v_normal_w.y;
	float rock = smoothstep(0.25, 0.45, slope + (n2 - 0.5) * 0.1);
	col = mix(col, rock_color * (0.8 + 0.4 * n2), rock);
	float snow = smoothstep(300.0, 340.0, v_world.y + n1 * 40.0) * (1.0 - smoothstep(0.35, 0.6, slope));
	col = mix(col, snow_color, snow);
	float beach = 1.0 - smoothstep(sea_level + 0.5, sea_level + 3.0, v_world.y);
	col = mix(col, sand_color, beach * (1.0 - rock));
	ALBEDO = col;
	ROUGHNESS = 0.95 - snow * 0.3;
	SPECULAR = 0.2;
}
