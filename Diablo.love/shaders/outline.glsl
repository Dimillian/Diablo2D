extern vec4 outlineColor;
extern number radius;

vec4 effect(vec4 color, Image tex, vec2 texCoord, vec2 screenCoord)
{
    vec4 base = Texel(tex, texCoord) * color;
    if (base.a > 0.0) {
        return base;
    }

    float alpha = 0.0;
    vec2 offsets[8] = vec2[8](
        vec2(radius, 0.0),
        vec2(-radius, 0.0),
        vec2(0.0, radius),
        vec2(0.0, -radius),
        vec2(radius, radius),
        vec2(-radius, radius),
        vec2(radius, -radius),
        vec2(-radius, -radius)
    );

    for (int i = 0; i < 8; i++) {
        alpha = max(alpha, Texel(tex, texCoord + offsets[i]).a);
    }

    if (alpha <= 0.0) {
        return vec4(0.0);
    }

    return vec4(outlineColor.rgb, outlineColor.a * alpha);
}
