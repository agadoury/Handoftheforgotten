// The pilot's sea: a flat-shaded, glossy plane that swells gently.
shader_type spatial;

uniform vec4 color : source_color;
// The pilot's sea is 90% opaque, so a little of the sandy seabed shows through.
uniform vec4 seabed : source_color;
uniform float seabed_mix = 0.1;
uniform float roughness = 0.25;
// amplitude (m), frequency (per m), speed (per s)
uniform vec3 swell_x = vec3(0.22, 0.045, 0.9);
uniform vec3 swell_z = vec3(0.18, 0.05, 1.2);
uniform float offset = -0.05;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y = sin(w.x * swell_x.y + TIME * swell_x.z) * swell_x.x
		+ cos(w.z * swell_z.y + TIME * swell_z.z) * swell_z.x + offset;
}

void fragment() {
	vec3 n = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	if (dot(n, VIEW) < 0.0) {
		n = -n;
	}
	NORMAL = n;
	ALBEDO = mix(color.rgb, seabed.rgb, seabed_mix);
	ROUGHNESS = roughness;
	SPECULAR = 0.5;
}
