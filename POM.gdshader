shader_type spatial;

// GLSL
// GDShader

uniform sampler2D albedo_texture : source_color;
uniform sampler2D normal_texture : hint_normal;
uniform sampler2D depth_texture;

uniform bool Use_Albedo;
uniform bool Use_Normal;
uniform bool Use_Parallax;

uniform float height_scale : hint_range(0.0, 0.2, 0.01);
uniform float num_layers : hint_range(0.0, 64.0, 1.0) = 10.0;

uniform float scale_x = 1.0;
uniform float scale_y = 1.0;
uniform float scale_z = 1.0;

varying vec3 tangent_view_dir;
varying vec2 tex_coords;

void vertex()
{
    tex_coords = UV * vec3(scale_x, scale_y, scale_z).xy;

    // Get camera position in model space
    vec3 camera_pos_model = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;

    // Calculate view direction in model space (from vertex to camera)
    vec3 view_dir_model = normalize(camera_pos_model - VERTEX);

    // Transform view direction to tangent space using TBN matrix
    vec3 T = normalize(TANGENT);
    vec3 B = normalize(BINORMAL);
    vec3 N = normalize(NORMAL);
    mat3 TBN = mat3(T, B, N);

    // Transform view direction to tangent space
    tangent_view_dir = TBN * view_dir_model;
}

vec2 parallax_mapping(vec2 texCoords, vec3 viewDir)
{
    if (!Use_Parallax) return texCoords;

    float layer_depth = 1.0 / num_layers;
    float current_layer_depth = 0.0;

    // Fix for coordinate system
    viewDir.y = -viewDir.y;

    // Calculate the amount to shift texture coordinates per layer
    vec2 P = viewDir.xy * height_scale;
    vec2 delta_texcoords = P / num_layers;

    // Initial values
    vec2 current_texcoords = texCoords;
    float current_depth = texture(depth_texture, current_texcoords).r;

    // Raymarching through depth layers
    while(current_layer_depth < current_depth) {
        current_texcoords -= delta_texcoords;
        current_depth = texture(depth_texture, current_texcoords).r;
        current_layer_depth += layer_depth;
    }

    return current_texcoords;
}

void fragment()
{


    // Use the pre-calculated tangent space view direction
    vec3 view_dir = normalize(tangent_view_dir);

    // Offset texture coordinates with Parallax Mapping
    vec2 tex_coords_parallax = parallax_mapping(tex_coords, view_dir);

    // Sample textures with new texture coords
    vec3 albedo = texture(albedo_texture, tex_coords_parallax).rgb;
    vec3 normal = texture(normal_texture, tex_coords_parallax).rgb;

    // Output final color
	if (Use_Albedo)
	{
    	ALBEDO = albedo;
	}
	else ALBEDO = vec3(1.0, 1.0, 1.0);

    if (Use_Normal)
	{
        NORMAL_MAP = normal;
    }
}