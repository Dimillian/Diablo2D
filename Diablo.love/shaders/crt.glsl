extern vec2 resolution;
extern number time;
extern number curvature;
extern number scanStrength;
extern number vignetteStrength;
extern number noiseStrength;
extern number rgbOffset;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec2 curveCoords(vec2 uv) {
    uv = uv * 2.0 - 1.0;
    uv.x *= 1.0 + (uv.y * uv.y) * curvature;
    uv.y *= 1.0 + (uv.x * uv.x) * curvature;
    uv = uv * 0.5 + 0.5;
    return uv;
}

vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords) {
    vec2 uv = curveCoords(textureCoords);

    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        return vec4(0.0, 0.0, 0.0, 1.0);
    }

    float scan = sin((screenCoords.y / resolution.y + time * 0.5) * resolution.y * 1.2);
    float scanMix = mix(1.0 - scanStrength, 1.0, scan * 0.5 + 0.5);

    float grain = (hash(screenCoords + time) - 0.5) * noiseStrength;

    vec4 centerSample = Texel(texture, uv);
    float r = Texel(texture, uv + vec2(rgbOffset, 0.0)).r;
    float b = Texel(texture, uv - vec2(rgbOffset, 0.0)).b;

    vec4 colorSample = vec4(r, centerSample.g, b, centerSample.a);

    float dist = distance(uv, vec2(0.5));
    float vignette = 1.0 - smoothstep(0.3, 0.72, dist);
    vignette = mix(1.0 - vignetteStrength, 1.0, vignette);

    vec3 finalColor = colorSample.rgb * scanMix;
    finalColor += grain;
    finalColor *= vignette;

    return vec4(finalColor, colorSample.a) * color;
}
