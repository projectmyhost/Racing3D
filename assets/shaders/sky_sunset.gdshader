shader_type sky;

uniform vec3 color_zenith : source_color = vec3(0.18, 0.15, 0.32);     // Deep twilight indigo
uniform vec3 color_mid : source_color = vec3(0.42, 0.24, 0.44);        // Sunset purple
uniform vec3 color_pink : source_color = vec3(0.78, 0.32, 0.46);       // Vibrant magenta-pink
uniform vec3 color_horizon : source_color = vec3(1.0, 0.52, 0.20);      // Radiant golden-orange
uniform vec3 color_sun : source_color = vec3(1.0, 0.94, 0.75);          // Intense golden-white sun
uniform vec3 color_sun_glow : source_color = vec3(1.0, 0.72, 0.35);     // Golden corona
uniform vec3 color_ground : source_color = vec3(0.08, 0.08, 0.11);      // Road ground dusk

// Sun direction corresponding to azimuth ~18Â°, elevation ~3.5Â° (visible under highway overpass)
uniform vec3 sun_dir = vec3(0.3084, 0.055, 0.9493);

void sky() {
    float y = EYEDIR.y;
    vec3 col = color_ground;
    
    if (y >= 0.0) {
        // Multi-tier sunset gradient
        if (y < 0.12) {
            float t = y / 0.12;
            col = mix(color_horizon, color_pink, smoothstep(0.0, 1.0, t));
        } else if (y < 0.38) {
            float t = (y - 0.12) / 0.26;
            col = mix(color_pink, color_mid, smoothstep(0.0, 1.0, t));
        } else {
            float t = clamp((y - 0.38) / 0.62, 0.0, 1.0);
            col = mix(color_mid, color_zenith, smoothstep(0.0, 1.0, t));
        }
        
        // Layered sunset cirrus clouds (horizontal dusk streaks with golden lit undersides)
        float cloud1 = sin(EYEDIR.x * 10.0 + EYEDIR.z * 6.0) * cos(EYEDIR.y * 30.0);
        float cloud2 = sin(EYEDIR.x * 24.0 + EYEDIR.z * 16.0) * sin(EYEDIR.y * 45.0);
        float cloud_pattern = clamp((cloud1 * 0.6 + cloud2 * 0.4) * 0.5 + 0.5, 0.0, 1.0);
        
        if (y > 0.03 && y < 0.50) {
            float cloud_mask = sin((y - 0.03) / 0.47 * 3.14159);
            vec3 cloud_col = mix(color_pink * 0.9, color_sun_glow * 1.2, clamp(cloud_pattern * 1.2, 0.0, 1.0));
            col = mix(col, cloud_col, cloud_pattern * cloud_mask * 0.28);
        }
        
        // Sun disc and golden atmospheric flare
        float sun_dot = max(dot(EYEDIR, normalize(sun_dir)), 0.0);
        
        // Wide atmospheric sunset wash
        float broad_glow = pow(sun_dot, 6.0) * 0.85;
        col += color_sun_glow * broad_glow;
        
        // Brilliant corona flare
        float corona = pow(sun_dot, 42.0) * 1.8;
        col += color_sun_glow * corona;
        
        // Crisp sun disc
        if (sun_dot > 0.9975) {
            float disc = smoothstep(0.9975, 0.9988, sun_dot);
            col = mix(col, color_sun * 4.0, disc);
        }
    } else {
        // Horizon blend into asphalt ground
        col = mix(color_horizon * 0.35, color_ground, clamp(-y * 12.0, 0.0, 1.0));
    }
    
    COLOR = col;
}
