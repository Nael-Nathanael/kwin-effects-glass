uniform vec3 glowColor;
uniform float glowStrength;
uniform int edgeLighting;
uniform int rimGlow;
uniform int rimSpecular;
uniform float rimWidth;

vec3 glassGlow(vec2 position, GlassFragment s)
{
    vec3 result = s.color.rgb;

    if (rimGlow == 1) {
        float rimMask = clamp(0.25 * s.concaveFactor, 0.0, glowStrength);
        result = mix(result, glowColor, rimMask);
    }

    if (edgeLighting == 1) {
        result += (s.color.rgb * s.concaveFactor);
    }

    return result;
}

vec3 glassOutline(vec2 position, GlassFragment s)
{
    vec3 result = s.color.rgb;

    if (rimSpecular == 1) {
        float edgeMask = smoothstep(0.0, -2.0 * rimWidth, s.dist);
        float borderInner = smoothstep(-1.0 * rimWidth, -3.0 * rimWidth, s.dist);
        float edgeProfile = edgeMask - borderInner;
        float thicknessShadow = pow(edgeProfile, 0.9);
        float shadowMask = smoothstep(blurSize.y * 0.7, -blurSize.y * 0.7, position.y) *
                           smoothstep(blurSize.x * 0.7, -blurSize.x * 0.7, position.x);
        float highlightMask = smoothstep(-blurSize.y * 0.7, blurSize.y * 0.7, position.y) *
                              smoothstep(-blurSize.x * 0.7, blurSize.x * 0.7, position.x);

        result = mix(result, vec3(1.0), thicknessShadow * shadowMask);
        result = mix(result, vec3(1.0), thicknessShadow * highlightMask);
    }

    return result;
}
