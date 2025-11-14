extern vec2 resolution;
extern number time;
extern number curvature;
extern number scanStrength;
extern number vignetteStrength;
extern number noiseStrength;
extern number rgbOffset;
extern number sharpStrength;
extern number glowStrength;
extern number glowThreshold;
extern number glowRadius;

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

    vec2 texel = 1.0 / resolution;

    float scan = sin((screenCoords.y / resolution.y + time * 0.5) * resolution.y * 1.2);
    float scanMix = mix(1.0 - scanStrength, 1.0, scan * 0.5 + 0.5);

    float grain = (hash(screenCoords + time) - 0.5) * noiseStrength;

    vec4 centerSample = Texel(texture, uv);
    float r = Texel(texture, uv + vec2(rgbOffset, 0.0)).r;
    float b = Texel(texture, uv - vec2(rgbOffset, 0.0)).b;

    vec4 colorSample = vec4(r, centerSample.g, b, centerSample.a);

    vec3 baseColor = colorSample.rgb;

    vec3 north = Texel(texture, uv + vec2(0.0, texel.y)).rgb;
    vec3 south = Texel(texture, uv - vec2(0.0, texel.y)).rgb;
    vec3 east = Texel(texture, uv + vec2(texel.x, 0.0)).rgb;
    vec3 west = Texel(texture, uv - vec2(texel.x, 0.0)).rgb;

    vec3 blurSample = (north + south + east + west) * 0.25;
    vec3 sharpened = baseColor + (baseColor - blurSample) * sharpStrength;

    vec2 glowStep = texel * glowRadius;
    vec3 glowAccum = vec3(0.0);
    glowAccum += Texel(texture, uv + vec2(glowStep.x, 0.0)).rgb;
    glowAccum += Texel(texture, uv - vec2(glowStep.x, 0.0)).rgb;
    glowAccum += Texel(texture, uv + vec2(0.0, glowStep.y)).rgb;
    glowAccum += Texel(texture, uv - vec2(0.0, glowStep.y)).rgb;
    glowAccum += Texel(texture, uv + glowStep).rgb;
    glowAccum += Texel(texture, uv - glowStep).rgb;
    glowAccum += Texel(texture, uv + vec2(glowStep.x, -glowStep.y)).rgb;
    glowAccum += Texel(texture, uv - vec2(glowStep.x, -glowStep.y)).rgb;
    vec3 glowColor = glowAccum * 0.125;
    float glowMask = max(max(glowColor.r, max(glowColor.g, glowColor.b)) - glowThreshold, 0.0);
    glowColor *= glowMask * glowStrength;

    float dist = distance(uv, vec2(0.5));
    float vignette = 1.0 - smoothstep(0.3, 0.72, dist);
    vignette = mix(1.0 - vignetteStrength, 1.0, vignette);

    vec3 finalColor = (sharpened + glowColor) * scanMix;
    finalColor += grain;
    finalColor *= vignette;

    return vec4(finalColor, colorSample.a) * color;
}
