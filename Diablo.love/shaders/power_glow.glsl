extern number time;
extern number intensity;
extern vec3 glowColor;
extern number pulseSpeed;
extern number glowRadius;
extern number distortionStrength;

vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords) {
    vec4 texColor = Texel(texture, textureCoords);

    // Skip transparent pixels
    if (texColor.a < 0.01) {
        return texColor * color;
    }

    // Smooth progressive pulse - gradual up and down with easing (not blinking)
    // abs(sin) creates natural smooth up/down from 0 to 1
    float rawPulse = abs(sin(time * pulseSpeed));
    // Apply power curve for progressive easing - smoother transitions
    float pulse = pow(rawPulse, 0.7); // Easing curve for smooth progressive feel

    // More intense pulse range - from 0.4 to 1.2 for stronger effect
    float pulseIntensity = 0.4 + pulse * 0.8;

    // Calculate distance from center for radial glow
    vec2 center = vec2(0.5, 0.5);
    vec2 uv = textureCoords;
    float dist = distance(uv, center);

    // Create radial glow mask - extend further out for more visible glow
    float glowMask = 1.0 - smoothstep(0.0, glowRadius, dist);
    glowMask = pow(glowMask, 0.8); // Softer falloff for wider glow

    // Much stronger animated glow
    float animatedGlow = glowMask * pulseIntensity * intensity;

    // More noticeable radial distortion for power effect
    vec2 distortion = (uv - center) * distortionStrength * pulse * 0.03;
    vec4 distortedColor = Texel(texture, uv + distortion);

    // More visible warping
    vec4 baseColor = mix(texColor, distortedColor, pulse * 0.25);

    // Glow color overlay - use screen blend to preserve color saturation
    vec3 glowOverlay = glowColor * animatedGlow * (1.0 + pulse * 0.4);
    // Screen blend: 1 - (1 - a) * (1 - b) preserves colors better than additive
    vec3 screenBlend = 1.0 - (1.0 - baseColor.rgb) * (1.0 - glowOverlay);
    // Mix between original and screen blend to control intensity
    vec3 finalColor = mix(baseColor.rgb, screenBlend, 0.7);

    // Reduced brightness boost to avoid white washout
    finalColor = finalColor * (1.0 + pulse * 0.1);

    // Add colored edge glow with screen blend for color preservation
    float edgeGlow = smoothstep(glowRadius * 0.7, glowRadius, dist);
    vec3 edgeGlowColor = glowColor * edgeGlow * pulse * intensity * 0.3;
    vec3 edgeScreenBlend = 1.0 - (1.0 - finalColor) * (1.0 - edgeGlowColor);
    finalColor = mix(finalColor, edgeScreenBlend, 0.5);

    // Preserve alpha
    return vec4(finalColor, texColor.a) * color;
}
