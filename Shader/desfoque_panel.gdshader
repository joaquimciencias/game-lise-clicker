shader_type canvas_item;

// Adicionamos a palavra 'uniform' antes do sampler. 
// Isso resolve o erro de "samplers are not allowed" na Godot 4.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float lod: hint_range(0.0, 5.0) = 2.0;

void fragment() {
    COLOR = textureLod(screen_texture, SCREEN_UV, lod);
}