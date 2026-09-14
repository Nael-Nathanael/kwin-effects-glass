uniform vec3 glowColor;
uniform float glowStrength;
uniform int edgeLighting;
uniform int rimGlow;
uniform float glowOffset;
uniform int rimSpecular;
uniform float rimSpecularScale;
uniform int rimEdgeHighlight;
uniform float rimEdgeHighlightStrength;
uniform float rimWidth;
uniform int rimAdaptToRefraction;
uniform float rimAdaptMultiplier;

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
    vec2 halfSize = blurSize * 0.5;
    float bevelScale = physicallyBasedRefraction == 1 ? refractionBevelIntensity : 1.0;
    float edgeBand = max(clamp(edgeSizePixels, 0.1, min(halfSize.x, halfSize.y) * 0.9) * bevelScale * rimAdaptMultiplier, 0.1);
    float width = rimAdaptToRefraction == 1 ? edgeBand / 3.5 : rimWidth;

    if (rimGlow == 1 && glowStrength > 0.0) {
        vec2 edgeDist = halfSize - abs(position);
        vec2 n = position / halfSize;
        float cornerBlend = min(blurSize.x, blurSize.y) * 0.25;
        float horizontalEdge = smoothstep(-cornerBlend, cornerBlend, edgeDist.x - edgeDist.y);
        vec2 lightPos = vec2(glowOffset, 1.0);
        float pointLight = max(1.0 - smoothstep(0.0, 1.0, distance(n, lightPos)),
                               1.0 - smoothstep(0.0, 1.0, distance(n, -lightPos)));
        float lightWeight = mix(horizontalEdge, pointLight, abs(glowOffset));
        float falloff = exp(s.dist / (2.0 * width));
        if (rimAdaptToRefraction == 1) {
            float edge = 1.0 - clamp(-s.dist / edgeBand, 0.0, 1.0);
            falloff = 1.0 - sqrt(1.0 - pow(smoothstep(0.0, 1.0, edge), refractionNormalPow));
        }
        float glowMask = glowStrength * lightWeight * falloff;
        outline = mix(outline, glowColor, glowMask);
    }

    if (rimSpecular == 1 && rimSpecularScale > 0.0) {
        vec3 specColor = mix(glowColor, vec3(1.0), 0.5 + 0.5 * rimEdgeHighlightStrength);
        if(glowStrength == 0.0 || dot(glowColor, glowColor) <= 0.0) {
            specColor = vec3(1.0);
        }

        float specWidth = width * rimSpecularScale;
        float edgeMask = smoothstep(0.0, -2.0 * specWidth, s.dist);
        float borderInner = smoothstep(-1.0 * specWidth, -3.0 * specWidth, s.dist);
        float edgeProfile = edgeMask - borderInner;
        float thicknessShadow = pow(edgeProfile, 0.9);
        float shadowMask = smoothstep(blurSize.y * 0.7, -blurSize.y * 0.7, position.y) *
                           smoothstep(blurSize.x * 0.7, -blurSize.x * 0.7, position.x);
        float highlightMask = smoothstep(-blurSize.y * 0.7, blurSize.y * 0.7, position.y) *
                              smoothstep(-blurSize.x * 0.7, blurSize.x * 0.7, position.x);

        outline = mix(outline, specColor, clamp(thicknessShadow * shadowMask, 0.0, 1.0));
        outline = mix(outline, specColor, clamp(thicknessShadow * highlightMask, 0.0, 1.0));
    }

    if (rimEdgeHighlight == 1) {
        float tOut = clamp(1.0 - s.dist / (-3.5 * width), 0.0, 1.0);
        tOut = pow(tOut, max(refractionNormalPow, 0.001));
        float edgeSat = mix(1.0, 2, tOut);
        vec3 edgeColor = oklabSaturate(s.color.rgb, edgeSat);
        float luma = dot(edgeColor, vec3(1));
        edgeColor *= 1.0 + 0.6 / (luma + 0.4);
        float band = smoothstep(0.0, -1.5 * width, s.dist) - smoothstep(-2.0 * width, -3.5 * width, s.dist);
        outline += edgeColor * clamp(band, 0.0, 1.0) * rimEdgeHighlightStrength;
    }

    return outline;
}
