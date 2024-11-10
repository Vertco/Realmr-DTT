shader_type canvas_item;

uniform sampler2D vertical_gradient; // used to set alpha values. So you can use this to make the effect dis-/re-appear at points
uniform sampler2D color_gradient; // sets the effect color, supports 2d gradients
uniform float size_effect: hint_range(-5.0, 5.0, 0.05) = 0.2; // size of the effect
uniform float speed = -0.5; // effect speed; Will reverse effect if set to negative
uniform float highlight_strength: hint_range(-4.0, 4.0, 0.05) = 0.5; // how strong the color overrides the base color
uniform bool color_mode_toggle = false; // changes how the color gradient is applied. Default is on the entire texture, if set to true it is only applied to the effect

void fragment() {
    // set up base parameters
    vec4 old_color = texture(TEXTURE, UV) * vec4(1.0, 1.0, 1.0, COLOR.a); // Use only alpha from modulate
    float time = TIME * speed;
    float current_time = fract(-time);
    // sets time to fit better with the effect. (Barely detectable change)
    current_time = mix(0. - size_effect, 1. + size_effect, current_time);
    float effect_lower_bound = current_time - size_effect;
    float effect_upper_bound = current_time + size_effect;
    float position_value = (UV.x + UV.y) * 0.5; // Use both coordinates for a diagonal effect
    // smooths out the lower/upper bounds with the UV values to calculate how far from the middle point(the effect) the pixel is away
    float effect_distance = smoothstep(effect_lower_bound, current_time, position_value) - smoothstep(current_time, effect_upper_bound, position_value);
    // gets the position of the pixel within the effect for the inner_gradient color mode
    float inner_effect_position = smoothstep(effect_lower_bound, effect_upper_bound, position_value);
    vec2 color_position = (color_mode_toggle) ? vec2(UV.x, inner_effect_position) : vec2(current_time);
    // gets the new color from the gradient
    vec4 new_color = vec4(texture(color_gradient, color_position));
    // this step calculates the vertical gradient and alpha values
    new_color = mix(old_color, new_color, vec4(texture(vertical_gradient, vec2(current_time))));
    // apply the color to the texture
    if (old_color.a > 0.0) { // Only apply the effect if the base color is not transparent
        COLOR.rgb = mix(old_color.rgb, new_color.rgb, vec3(effect_distance * highlight_strength));
        COLOR.a = old_color.a * mix(1.0, new_color.a, effect_distance); // Smooth alpha blending affected by modulate alpha
    } else {
        COLOR = old_color * vec4(1.0, 1.0, 1.0, COLOR.a); // Retain original color, apply modulate alpha only
    }
}
