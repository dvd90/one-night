shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;

// PS1 vertex snapping + affine texture mapping + faceted flat shading
// (ARCHITECTURE.md §7). The jitter and wobble are INTENTIONAL — do not "fix".
// Toggles are pushed in from Config.apply_ps1_settings(); keep uniform names
// in sync with autoload/config.gd.

uniform bool snap_enabled = true;
// Vertical resolution of the virtual snap grid, in "PS1 pixels".
uniform float snap_resolution : hint_range(64.0, 480.0) = 160.0;
uniform bool affine_enabled = true;
// Derivative-based face normals: the classic hard-edged low-poly read.
uniform bool flat_shading = true;

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_nearest, hint_default_white;
// Texture tiling (world-scale surfaces set this high, characters keep 1).
uniform vec2 uv_scale = vec2(1.0, 1.0);

varying vec2 uv_affine;
varying float affine_w;

void vertex() {
	vec4 clip_pos = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));

	if (snap_enabled) {
		// Snap NDC xy to a coarse grid scaled by the viewport aspect, then
		// restore the perspective divide — the classic PS1 vertex wobble.
		vec3 ndc = clip_pos.xyz / clip_pos.w;
		vec2 grid = vec2(
			snap_resolution * VIEWPORT_SIZE.x / VIEWPORT_SIZE.y,
			snap_resolution
		) * 0.5;
		ndc.xy = floor(ndc.xy * grid + 0.5) / grid;
		clip_pos.xy = ndc.xy * clip_pos.w;
	}

	POSITION = clip_pos;

	// Affine mapping: premultiply UVs by clip w and divide back per-fragment.
	// The perspective-correct interpolation of (UV * w, w) reconstructs a
	// screen-linear UV — the PS1's perspective-free texture crawl.
	vec2 scaled_uv = UV * uv_scale;
	if (affine_enabled) {
		uv_affine = scaled_uv * clip_pos.w;
		affine_w = clip_pos.w;
	} else {
		uv_affine = scaled_uv;
		affine_w = 1.0;
	}
}

void fragment() {
	if (flat_shading) {
		NORMAL = normalize(cross(dFdy(VERTEX), dFdx(VERTEX)));
	}
	vec2 uv = uv_affine / affine_w;
	vec4 albedo = albedo_color * texture(albedo_texture, uv);
	ALBEDO = albedo.rgb;
}
