uniform vec3 glowColor;
uniform float glowStrength;
uniform int edgeLighting;
uniform int rimGlow;
uniform int rimSpecular;
uniform int rimEdgeHighlight;
uniform float rimEdgeHighlightStrength;
uniform float rimWidth;

vec3 glassGlow(vec2 position, GlassFragment s)
{
    vec3 outline = s.color.rgb;

    if (edgeLighting == 1) {
        outline += (s.color.rgb * s.concaveFactor);
    }

    return outline;
}

vec3 glassOutline(vec2 position, GlassFragment s)
{
    vec3 outline = s.color.rgb;

    if (rimGlow == 1 && glowStrength > 0.0) {
        vec2 edgeDist = blurSize * 0.5 - abs(position);
        float cornerBlend = min(blurSize.x, blurSize.y) * 0.25;
        float horizontalEdge = smoothstep(-cornerBlend, cornerBlend, edgeDist.x - edgeDist.y);
        float falloff = exp(s.dist / (2.0 * rimWidth));
        float glowMask = glowStrength * horizontalEdge * falloff;
        outline = mix(outline, glowColor, glowMask);
    }

    if (rimSpecular == 1) {
        vec3 specColor = mix(glowColor, vec3(1.0), 0.5 + 0.5 * rimEdgeHighlightStrength);
        if(glowStrength == 0.0 || dot(glowColor, glowColor) <= 0.0) {
            specColor = vec3(1.0);
        }

        float edgeMask = smoothstep(0.0, -2.0 * rimWidth, s.dist);
        float borderInner = smoothstep(-1.0 * rimWidth, -3.0 * rimWidth, s.dist);
        float edgeProfile = edgeMask - borderInner;
        float thicknessShadow = pow(edgeProfile, 0.9);
        float shadowMask = smoothstep(blurSize.y * 0.7, -blurSize.y * 0.7, position.y) *
                           smoothstep(blurSize.x * 0.7, -blurSize.x * 0.7, position.x);
        float highlightMask = smoothstep(-blurSize.y * 0.7, blurSize.y * 0.7, position.y) *
                              smoothstep(-blurSize.x * 0.7, blurSize.x * 0.7, position.x);

        outline = mix(outline, specColor, thicknessShadow * shadowMask);
        outline = mix(outline, specColor, thicknessShadow * highlightMask);
    }

    if (rimEdgeHighlight == 1) {
        float tOut = clamp(1.0 - s.dist / (-3.5 * rimWidth), 0.0, 1.0);
        tOut = pow(tOut, max(refractionNormalPow, 0.001));
        float edgeSat = mix(1.0, 2, tOut);
        vec3 edgeColor = oklabSaturate(s.color.rgb, edgeSat);
        float luma = dot(edgeColor, vec3(1));
        edgeColor *= 1.0 + 0.6 / (luma + 0.4);
        float band = smoothstep(0.0, -1.5 * rimWidth, s.dist) - smoothstep(-2.0 * rimWidth, -3.5 * rimWidth, s.dist);
        outline += edgeColor * clamp(band, 0.0, 1.0) * rimEdgeHighlightStrength;
    }

    return outline;
}
