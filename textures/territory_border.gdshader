shader_type canvas_item;

uniform vec2 polygon_points[64];
uniform int point_count = 0;
uniform float border_thickness = 2.0;
uniform vec4 border_color = vec4(1.0, 0.5, 0.0, 1.0);

float distance_to_line(vec2 p1, vec2 p2, vec2 point) {
    vec2 line = p2 - p1;
    vec2 to_point = point - p1;
    float t = clamp(dot(to_point, line) / dot(line, line), 0.0, 1.0);
    return length(p1 + t * line - point);
}

void fragment() {
    float min_dist = 1000.0;
    for (int i = 0; i < point_count - 1; i++) {
        float dist = distance_to_line(polygon_points[i], polygon_points[i + 1], SCREEN_UV);
        min_dist = min(min_dist, dist);
    }

    if (min_dist < border_thickness) {
        COLOR = border_color;
    } else {
        discard;
    }
}