#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

// Qt-provided uniform block. qt_Opacity + our custom uniforms.
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;   // 0.0 (old) -> 1.0 (new)
    float mode;       // 0 fade, 1 wipe, 2 circle, 3 dissolve, 4 slide, 5 zoom-blur-ish
    float aspect;     // width / height, for round circle reveal
    vec2  center;     // reveal center in normalized [0,1] coords
    float seed;       // randomness for dissolve
} ubuf;

layout(binding = 1) uniform sampler2D oldTex;
layout(binding = 2) uniform sampler2D newTex;

// Cheap hash for dissolve noise.
float hash(vec2 p) {
    p = fract(p * vec2(233.34, 851.73));
    p += dot(p, p + 23.45);
    return fract(p.x * p.y);
}

void main() {
    vec2 uv = qt_TexCoord0;
    float p = clamp(ubuf.progress, 0.0, 1.0);
    // Smooth the global progress for nicer easing on top of the QML animation.
    float sp = smoothstep(0.0, 1.0, p);

    vec4 oldC = texture(oldTex, uv);
    vec4 newC = texture(newTex, uv);
    vec4 col = oldC;

    int mode = int(ubuf.mode + 0.5);

    if (mode == 0) {
        // Crossfade
        col = mix(oldC, newC, sp);

    } else if (mode == 1) {
        // Directional wipe with a soft edge (left -> right).
        float edge = sp * (1.0 + 0.15) - 0.15 * (1.0 - uv.y * 0.0);
        float m = smoothstep(edge - 0.12, edge + 0.12, uv.x);
        col = mix(newC, oldC, m);

    } else if (mode == 2) {
        // Circle / iris reveal from center, aspect-corrected so it's round.
        vec2 d = uv - ubuf.center;
        d.x *= ubuf.aspect;
        float dist = length(d);
        float maxR = length(vec2(max(ubuf.center.x, 1.0 - ubuf.center.x) * ubuf.aspect,
                                 max(ubuf.center.y, 1.0 - ubuf.center.y)));
        float r = sp * maxR;
        float m = smoothstep(r + 0.03, r - 0.03, dist);
        col = mix(oldC, newC, m);

    } else if (mode == 3) {
        // Dissolve: per-pixel threshold from noise, with a soft band.
        float n = hash(uv * vec2(ubuf.aspect, 1.0) * 50.0 + ubuf.seed);
        float m = smoothstep(n - 0.08, n + 0.08, sp);
        col = mix(oldC, newC, m);

    } else if (mode == 4) {
        // Slide: new image pushes the old one out to the left.
        vec2 uvOld = uv + vec2(sp, 0.0);
        vec2 uvNew = uv - vec2(1.0 - sp, 0.0);
        vec4 o = texture(oldTex, uvOld);
        vec4 nw = texture(newTex, uvNew);
        col = (uv.x < 1.0 - sp) ? o : nw;

    } else {
        // Fallback crossfade
        col = mix(oldC, newC, sp);
    }

    fragColor = col * ubuf.qt_Opacity;
}
