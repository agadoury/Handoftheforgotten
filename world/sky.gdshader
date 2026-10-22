// The pilot's sky: a horizon-to-top gradient with a sun glow. Ambient light comes from a simple
// hemisphere (sky colour above, ground colour below), like the pilot's HemisphereLight.
//
// The pilot draws its sky without tone mapping, so the gradient is computed in display colours
// (sRGB, as the pilot does) and then run backwards through Godot's ACES tone mapper, so that what
// reaches the screen is the pilot's colour. Must match tonemap_aces in Godot's tonemap shader.
shader_type sky;

// Display colours (sRGB values, no conversion).
uniform vec3 top_color = vec3(0.298, 0.486, 0.714);
uniform vec3 horizon_color = vec3(0.953, 0.784, 0.565);
uniform vec3 sun_color = vec3(1.0, 0.851, 0.627);
uniform vec3 sun_direction = vec3(-0.78, 0.5, 0.38);
uniform vec4 ambient_sky : source_color;
uniform vec4 ambient_ground : source_color;
// Godot ignores Environment.ambient_light_energy for sky ambient, so it is scaled here.
uniform float ambient_energy = 1.0;
uniform float exposure = 1.0;
uniform float white = 1.0;

const float ACES_A = 0.0245786;
const float ACES_B = 0.000090537;
const float ACES_C = 0.983729;
const float ACES_D = 0.432951;
const float ACES_E = 0.238081;
const float EXPOSURE_BIAS = 1.8;
const mat3 RGB_TO_RRT = mat3(
		vec3(0.59719, 0.35458, 0.04823) * EXPOSURE_BIAS,
		vec3(0.07600, 0.90834, 0.01566) * EXPOSURE_BIAS,
		vec3(0.02840, 0.13383, 0.83777) * EXPOSURE_BIAS);
const mat3 ODT_TO_RGB = mat3(
		vec3(1.60475, -0.53108, -0.07367),
		vec3(-0.10208, 1.10813, -0.00605),
		vec3(-0.00327, -0.07276, 1.07602));

vec3 srgb_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

float aces_curve(float x) {
	return (x * (x + ACES_A) - ACES_B) / (x * (ACES_C * x + ACES_D) + ACES_E);
}

// The scene colour that Godot's ACES tone mapper turns into this display colour.
vec3 untonemap(vec3 display) {
	vec3 target = srgb_to_linear(clamp(display, 0.0, 1.0)) * aces_curve(white * EXPOSURE_BIAS);
	vec3 t = clamp(target * inverse(ODT_TO_RGB), vec3(0.0), vec3(0.995 / ACES_C));
	// Solve (x^2 + ACES_A x - ACES_B) / (ACES_C x^2 + ACES_D x + ACES_E) = t for x, per channel.
	vec3 qa = 1.0 - t * ACES_C;
	vec3 qb = ACES_A - t * ACES_D;
	vec3 qc = -(ACES_B + t * ACES_E);
	vec3 x = (-qb + sqrt(qb * qb - 4.0 * qa * qc)) / (2.0 * qa);
	return max(x * inverse(RGB_TO_RRT), vec3(0.0)) / exposure;
}

void sky() {
	vec3 d = normalize(EYEDIR);
	if (AT_CUBEMAP_PASS) {
		COLOR = mix(ambient_ground.rgb, ambient_sky.rgb, 0.5 + 0.5 * d.y) * ambient_energy;
	} else {
		float t = clamp(d.y * 1.5 + 0.06, 0.0, 1.0);
		vec3 c = mix(horizon_color, top_color, pow(t, 0.65));
		float s = max(dot(d, normalize(sun_direction)), 0.0);
		c += sun_color * (pow(s, 80.0) * 1.1 + pow(s, 7.0) * 0.28);
		COLOR = untonemap(c);
	}
}
