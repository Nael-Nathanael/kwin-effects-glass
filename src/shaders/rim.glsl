uniform vec3 glowColor;
uniform float glowStrength;
uniform int edgeLighting;

vec3 glassGlow(vec2 position, GlassFragment s)
{
    float rimMask = clamp(0.25 * s.concaveFactor, 0.0, glowStrength);
    vec3 glow = mix(s.color.rgb, glowColor, rimMask);
    if (edgeLighting == 1) {
        glow += (s.color.rgb * s.concaveFactor);
    }

    return glow;
}

vec3 glassOutline(vec2 position, GlassFragment s)
{
    vec3 glow = s.color.rgb;

    if (glowStrength > 0.0) {
        float edgeMask = smoothstep(0.0, -2.0, s.dist);
        float borderInner = smoothstep(-1.0, -3.0, s.dist);
        float edgeProfile = edgeMask - borderInner;
        float thicknessShadow = pow(edgeProfile, 0.9);
        float shadowMask = smoothstep(blurSize.y * 0.7, -blurSize.y * 0.7, position.y) *
                           smoothstep(blurSize.x * 0.7, -blurSize.x * 0.7, position.x);
        float highlightMask = smoothstep(-blurSize.y * 0.7, blurSize.y * 0.7, position.y) *
                              smoothstep(-blurSize.x * 0.7, blurSize.x * 0.7, position.x);

        glow = mix(glow, vec3(1.0), thicknessShadow * shadowMask);
        glow = mix(glow, vec3(1.0), thicknessShadow * highlightMask);
    }

    return glow;
}
