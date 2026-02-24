shader_type canvas_item;

uniform sampler2D mask_texture;
uniform float softness = 0.02;

void fragment() {
	vec4 scene_tex = texture(TEXTURE, UV);
	vec4 mask = texture(mask_texture, UV);

	float visibility = smoothstep(0.5 - softness, 0.5 + softness, mask.r);
	COLOR = vec4(scene_tex.rgb, scene_tex.a * visibility);
}